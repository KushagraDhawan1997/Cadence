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
    @Published private(set) var streamingResponse: String = ""
    @Published private(set) var isStreaming = false
    
    // MARK: - Initialization
    init(service: OpenAIService) {
        self.service = service
        Task {
            await loadSavedThread()
        }
    }
    
    // MARK: - Thread Management
    private func loadSavedThread() async {
        if UserDefaults.standard.string(forKey: threadKey) != nil {
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
    
    func deleteThread(_ thread: ThreadModel) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        // If we're deleting the current thread, clear it
        if thread.id == currentThread?.id {
            currentThread = nil
            messages = []
            UserDefaults.standard.removeObject(forKey: threadKey)
        }
        
        // Remove the thread from our local array
        if let index = threads.firstIndex(where: { $0.id == thread.id }) {
            threads.remove(at: index)
        }
        
        // TODO: Add API call for thread deletion when available
        // try await service.deleteThread(thread.id)
    }
    
    // MARK: - Message Management
    func sendMessage(_ content: String) async throws {
        guard let threadId = currentThread?.id else {
            let error = AssistantError.noActiveThread
            self.error = error
            throw error
        }
        
        isLoading = true
        isStreaming = false
        streamingResponse = ""
        error = nil
        
        do {
            // Send user message
            let messageRequest = CreateMessageRequest(threadId: threadId, content: content, fileIds: nil)
            let _: MessageResponse = try await service.sendRequest(messageRequest)
            
            // Update messages immediately with user message
            try await updateMessages(threadId: threadId)
            
            // Create and monitor streaming run
            print("Creating streaming run for message")
            let runRequest = CreateRunRequest(threadId: threadId)
            
            isStreaming = true
            try await service.streamRequest(runRequest) { [weak self] (response: String) in
                guard let self = self else { return }
                self.streamingResponse = response
            }
            
            // After streaming completes, update messages to include the full response
            try await updateMessages(threadId: threadId)
            isStreaming = false
            isLoading = false
        } catch {
            let assistantError = error as? AssistantError ?? AssistantError.unknown(error)
            self.error = assistantError
            isStreaming = false
            isLoading = false
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
            // TODO: Add actual workout storage/processing here
            return "Successfully logged workout: \(details). I'll store this in your workout history."
            
        default:
            throw AssistantError.functionExecutionFailed("Unknown function: \(name)")
        }
    }
}
