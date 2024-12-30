import Foundation

// MARK: - Custom Errors
enum AssistantError: Error {
    case noActiveThread
    case functionExecutionFailed(String)
    case invalidFunctionArguments
    case runFailed(String)
    case unknown(Error)
}

@MainActor
class AssistantViewModel: ObservableObject {
    private let service: OpenAIService
    private let threadKey = "current_thread_id"
    
    // MARK: - Published Properties
    @Published private(set) var threads: [ThreadModel] = []
    @Published private(set) var currentThread: ThreadModel?
    @Published private(set) var messages: [MessageResponse] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    // MARK: - Initialization
    init(service: OpenAIService) {
        self.service = service
        Task {
            await loadSavedThread()
        }
    }
    
    // MARK: - Thread Management
    private func loadSavedThread() async {
        if let threadId = UserDefaults.standard.string(forKey: threadKey) {
            // TODO: Implement thread retrieval
            // For now, we'll just create a new thread if loading fails
            do {
                try await createThread()
            } catch {
                print("Failed to load saved thread: \(error)")
            }
        }
    }
    
    func createThread() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let request = CreateThreadRequest(messages: nil)
            let newThread: ThreadModel = try await service.sendRequest(request)
            threads.append(newThread)
            currentThread = newThread
            messages = [] // Clear messages for new thread
            
            // Save thread ID
            if let threadId = currentThread?.id {
                UserDefaults.standard.set(threadId, forKey: threadKey)
            }
            
            print("Thread created: \(newThread.id)")
        } catch {
            let assistantError = AssistantError.unknown(error)
            self.error = assistantError
            throw assistantError
        }
    }
    
    func selectThread(_ thread: ThreadModel) async throws {
        guard thread.id != currentThread?.id else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            currentThread = thread
            messages = try await retrieveMessages(threadId: thread.id)
        } catch {
            let assistantError = AssistantError.unknown(error)
            self.error = assistantError
            throw assistantError
        }
    }
    
    // MARK: - Message Management
    func sendMessage(_ content: String) async throws {
        guard let threadId = currentThread?.id else {
            let error = AssistantError.noActiveThread
            self.error = error
            throw error
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            // Send user message
            print("Sending message to thread: \(threadId)")
            let messageRequest = CreateMessageRequest(threadId: threadId, content: content, fileIds: nil)
            let _: MessageResponse = try await service.sendRequest(messageRequest)
            
            // Update messages immediately with user message
            try await updateMessages(threadId: threadId)
            
            // Create and monitor run
            print("Creating run for message")
            let runRequest = CreateRunRequest(threadId: threadId)
            let run: RunResponse = try await service.sendRequest(runRequest)
            print("Run created: \(run.id)")
            
            // Wait for run completion
            try await monitorRun(threadId: threadId, runId: run.id)
            
            // Update messages to include assistant's response
            try await updateMessages(threadId: threadId)
        } catch {
            let assistantError = error as? AssistantError ?? AssistantError.unknown(error)
            self.error = assistantError
            throw assistantError
        }
    }
    
    // MARK: - Message Retrieval
    private func updateMessages(threadId: String) async throws {
        let request = ListMessagesRequest(threadId: threadId, limit: 100, order: "desc")
        let response: ListMessagesResponse = try await service.sendRequest(request)
        messages = response.data.reversed() // Reverse to show oldest first
    }
    
    private func retrieveMessages(threadId: String) async throws -> [MessageResponse] {
        let request = ListMessagesRequest(threadId: threadId, limit: 100, order: "desc")
        let response: ListMessagesResponse = try await service.sendRequest(request)
        return response.data.reversed() // Reverse to show oldest first
    }
    
    // MARK: - Helper Methods
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
                throw AssistantError.runFailed("Run failed with status: \(run.status)")
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
        print("Executing function: \(name) with arguments: \(arguments)")
        
        guard let jsonData = arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AssistantError.invalidFunctionArguments
        }
        
        // Handle dashboard-configured functions
        switch name {
        case "add_test_workout":
            guard let details = args["workout_details"] as? String else {
                throw AssistantError.invalidFunctionArguments
            }
            print("📝 Workout Details Received: \(details)")
            return "Successfully noted workout: \(details)"
            
        default:
            throw AssistantError.functionExecutionFailed("Unknown function: \(name)")
        }
    }
}
