import Foundation

// MARK: - Custom Errors removed since we're using AppError

@MainActor
class AssistantViewModel: ObservableObject {
    // Add new enum for thread grouping
    enum ThreadGroup: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case lastWeek = "Last Week"
        case earlier = "Earlier"
    }
    
    // Add grouped threads structure
    struct GroupedThreads: Identifiable {
        let id: ThreadGroup
        let threads: [ThreadModel]
        var title: String { id.rawValue }
        var count: Int { threads.count }
    }
    
    // MARK: - Dependencies
    private let service: APIClient
    private let errorHandler: ErrorHandling
    
    // MARK: - Published Properties
    @Published private(set) var threads: [ThreadModel] = [] {
        didSet {
            groupedThreads = groupThreadsByDate(threads)
        }
    }
    @Published private(set) var groupedThreads: [GroupedThreads] = []
    @Published private(set) var currentThread: ThreadModel?
    @Published private(set) var messages: [MessageResponse] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var streamingResponse: String = ""
    @Published private(set) var isStreaming = false
    @Published private(set) var isWaitingForResponse = false
    
    // Add task storage
    private var currentTask: Task<Void, Error>?
    
    // MARK: - Initialization
    init(service: APIClient, errorHandler: ErrorHandling) {
        self.service = service
        self.errorHandler = errorHandler
    }
    
    // Add this function before the Thread Management section
    private func groupThreadsByDate(_ threads: [ThreadModel]) -> [GroupedThreads] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: threads) { thread in
            let threadDate = Date(timeIntervalSince1970: TimeInterval(thread.createdAt))
            let components = calendar.dateComponents([.day], from: threadDate, to: now)
            
            guard let days = components.day else { return ThreadGroup.earlier }
            
            switch days {
            case 0:
                return ThreadGroup.today
            case 1:
                return ThreadGroup.yesterday
            case 2...7:
                return ThreadGroup.lastWeek
            default:
                return ThreadGroup.earlier
            }
        }
        
        return ThreadGroup.allCases.compactMap { group in
            let threadsInGroup = grouped[group, default: []]
            if threadsInGroup.isEmpty { return nil }
            return GroupedThreads(id: group, threads: threadsInGroup)
        }
    }
    
    // MARK: - Thread Management
    func createThread() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            try await errorHandler.handleWithRetry { [weak self] in
                guard let self = self else { return }
                let request = CreateThreadRequest(messages: nil)
                let newThread: ThreadModel = try await service.sendRequest(request)
                threads.append(newThread)
                currentThread = newThread
                messages = [] // Clear messages for new thread
                
                print("Thread created: \(newThread.id)")
            }
        } catch {
            let appError = errorHandler.handle(error)
            self.error = appError
            throw appError
        }
    }
    
    func selectThread(_ thread: ThreadModel) async throws {
        guard thread.id != currentThread?.id else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            try await errorHandler.handleWithRetry { [weak self] in
                guard let self = self else { return }
                currentThread = thread
                messages = try await retrieveMessages(threadId: thread.id)
            }
        } catch {
            let appError = errorHandler.handle(error)
            self.error = appError
            throw appError
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
            let error = AppError.userError("No active thread")
            self.error = error
            throw error
        }
        
        // Cancel any existing task
        currentTask?.cancel()
        
        // Immediately add the user's message to the UI
        let temporaryUserMessage = MessageResponse(
            id: UUID().uuidString,
            object: "thread.message",
            createdAt: Int(Date().timeIntervalSince1970),
            threadId: threadId,
            role: "user",
            content: [MessageContent(
                type: "text",
                text: TextContent(value: content, annotations: nil)
            )]
        )
        messages.append(temporaryUserMessage)
        
        isLoading = true
        isStreaming = false
        streamingResponse = ""
        error = nil
        
        currentTask = Task {
            do {
                try await errorHandler.handleWithRetry { [weak self] in
                    guard let self = self else { return }
                    try Task.checkCancellation()
                    
                    // Send user message to API
                    let messageRequest = CreateMessageRequest(threadId: threadId, content: content, fileIds: nil)
                    let _: MessageResponse = try await service.sendRequest(messageRequest)
                    
                    try Task.checkCancellation()
                    try await updateMessages(threadId: threadId)
                    
                    // Create and monitor streaming run
                    print("Creating streaming run for message")
                    let runRequest = CreateRunRequest(threadId: threadId)
                    
                    isStreaming = true
                    try await service.streamRequest(runRequest) { [weak self] (response: String) in
                        guard let self = self else { return }
                        self.streamingResponse = response
                    }
                    
                    try Task.checkCancellation()
                    try await updateMessages(threadId: threadId)
                    isStreaming = false
                    isLoading = false
                }
            } catch is CancellationError {
                print("Task was cancelled")
                isStreaming = false
                isLoading = false
            } catch {
                let appError = errorHandler.handle(error)
                self.error = appError
                isStreaming = false
                isLoading = false
                throw appError
            }
        }
        
        try await currentTask?.value
    }
    
    func cancelCurrentTask() {
        currentTask?.cancel()
    }
    
    // MARK: - Message Retrieval
    private func updateMessages(threadId: String) async throws {
        let request = ListMessagesRequest(threadId: threadId, limit: 100, order: "desc")
        let response: ListMessagesResponse = try await service.sendRequest(request)
        
        // Create a map of existing messages by content for quick lookup
        let existingMessageMap = Dictionary(grouping: messages) { message in
            message.content.first?.text?.value ?? ""
        }
        
        // Process new messages, preserving IDs for matching content
        let updatedMessages = response.data.map { newMessage in
            if let existingMessage = existingMessageMap[newMessage.content.first?.text?.value ?? ""]?.first {
                // Preserve the ID but update other properties
                return MessageResponse(
                    id: existingMessage.id,
                    object: newMessage.object,
                    createdAt: newMessage.createdAt,
                    threadId: newMessage.threadId,
                    role: newMessage.role,
                    content: newMessage.content
                )
            } else {
                return newMessage
            }
        }
        
        messages = updatedMessages.reversed() // Reverse to show oldest first
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
        print("Executing function: \(name) with arguments: \(arguments)")
        
        guard let jsonData = arguments.data(using: .utf8),
              let args = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw AppError.systemError("Invalid function arguments")
        }
        
        // Handle dashboard-configured functions
        switch name {
        case "add_test_workout":
            guard let details = args["workout_details"] as? String else {
                throw AppError.systemError("Invalid function arguments")
            }
            print("📝 Workout Details Received: \(details)")
            // TODO: Add actual workout storage/processing here
            return "Successfully logged workout: \(details). I'll store this in your workout history."
            
        default:
            throw AppError.systemError("Unknown function: \(name)")
        }

    }
}
