import Foundation

// MARK: - Run Management
extension AssistantViewModel {
    private func monitorRun(threadId: String, runId: String) async throws {
        let retrieveRequest = RetrieveRunRequest(threadId: threadId, runId: runId)
        
        while true {
            let run: RunResponse = try await service.sendRequest(retrieveRequest)
            
            switch run.status {
            case "completed":
                return
            case "requires_action":
                if let action = run.requiredAction,
                   action.type == "submit_tool_outputs",
                   let tools = action.submitToolOutputs {
                    try await handleToolCalls(tools.toolCalls, threadId: threadId, runId: runId)
                }
            case "failed", "cancelled", "expired":
                throw AppError.systemError("Run failed with status: \(run.status)")
            default:
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                continue
            }
        }
    }
    
    private func handleToolCalls(_ toolCalls: [ToolCall], threadId: String, runId: String) async throws {
        var outputs: [[String: String]] = []
        
        for call in toolCalls {
            if call.type == "function" {
                let result = try await executeFunction(name: call.function.name, arguments: call.function.arguments)
                outputs.append(["tool_call_id": call.id, "output": result])
            }
        }
        
        if !outputs.isEmpty {
            let request = SubmitToolOutputsRequest(threadId: threadId, runId: runId, toolOutputs: outputs)
            let _: RunResponse = try await service.sendRequest(request)
        }
    }
    
    private func executeFunction(name: String, arguments: String) async throws -> String {
        guard let jsonData = arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AppError.systemError("Invalid function arguments")
        }
        
        // Handle dashboard-configured functions
        switch name {
        case "create_workout":
            guard let argsData = try? JSONSerialization.data(withJSONObject: args),
                  let workoutArgs = try? JSONDecoder().decode(WorkoutArgs.self, from: argsData) else {
                throw AppError.systemError("Invalid workout arguments")
            }
            
            // Create workout from arguments
            let workout = Workout(
                type: workoutArgs.backingData,
                duration: workoutArgs.duration,
                notes: workoutArgs.notes
            )
            
            let durationText = workoutArgs.duration != nil ? " (\(workoutArgs.duration!) minutes)" : ""
            return "Successfully logged your \(workout.type.rawValue) workout\(durationText)"
            
        default:
            throw AppError.systemError("Unknown function: \(name)")
        }
    }
    
    // Helper struct for decoding arguments
    private struct WorkoutArgs: Codable {
        let backingData: WorkoutType
        let duration: Int?
        let notes: String?
    }
} 
