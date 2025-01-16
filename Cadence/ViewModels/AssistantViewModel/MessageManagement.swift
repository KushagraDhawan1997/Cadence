import Foundation

// MARK: - Message Management
extension AssistantViewModel {
    @MainActor
    func sendMessage(_ content: String) async throws {
        guard networkMonitor.isConnected else {
            let error = AppError.network(.invalidResponse)
            self.error = error
            throw error
        }
        
        guard let threadId = currentThread?.id else {
            let error = AppError.userError("No active thread")
            self.error = error
            throw error
        }
        
        // Create and immediately show the user's message
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
        
        // Add message to UI immediately
        messages.append(temporaryUserMessage)
        
        isStreaming = false
        streamingResponse = ""
        error = nil
        
        var messageAddedToServer = false
        
        let newTask = Task { @MainActor in
            do {
                // Send message to server
                let messageRequest = CreateMessageRequest(threadId: threadId, content: content, fileIds: nil)
                let _: MessageResponse = try await service.sendRequest(messageRequest)
                messageAddedToServer = true
                
                // Create and start the run immediately
                let runRequest = CreateRunRequest(threadId: threadId)
                isStreaming = true
                
                try await service.streamRequest(runRequest) { @MainActor [weak self] (response: String) in
                    guard let self = self else { return }
                    self.streamingResponse = response
                }
                
                // Final message update
                try await updateMessages(threadId: threadId, force: true)
                isStreaming = false
                
                // Sync messages to persistence
                await syncStoredMessages(threadId: threadId, with: messages)
                
            } catch is CancellationError {
                print("Task was cancelled")
                cleanupState()
                if messageAddedToServer {
                    Task {
                        try? await updateMessages(threadId: threadId, force: true)
                        await syncStoredMessages(threadId: threadId, with: messages)
                    }
                }
            } catch {
                let appError = errorHandler.handle(error)
                cleanupState()
                self.error = appError
                if messageAddedToServer {
                    Task {
                        try? await updateMessages(threadId: threadId, force: true)
                        await syncStoredMessages(threadId: threadId, with: messages)
                    }
                }
                throw appError
            }
        }
        
        currentTask = newTask
        
        do {
            try await newTask.value
        } catch {
            if networkMonitor.isConnected && messageAddedToServer {
                Task {
                    try? await updateMessages(threadId: threadId, force: true)
                    await syncStoredMessages(threadId: threadId, with: messages)
                }
            }
            throw error
        }
    }
    
    @MainActor
    private func waitForRunCompletion(threadId: String, runId: String) async throws {
        while true {
            let request = RetrieveRunRequest(threadId: threadId, runId: runId)
            let run: RunResponse = try await service.sendRequest(request)
            
            switch run.status {
            case "completed":
                return
            case "failed", "cancelled", "expired":
                throw AppError.userError("Run failed with status: \(run.status)")
            case "in_progress", "queued":
                try await Task.sleep(nanoseconds: 1_000_000_000)
                continue
            default:
                throw AppError.userError("Unknown run status: \(run.status)")
            }
        }
    }
    
    @MainActor
    private func cleanupState() {
        isStreaming = false
        isLoading = false
        streamingResponse = ""
        isWaitingForResponse = false
    }
    
    // Only cleanup if explicitly requested, not during navigation
    func cleanupCurrentTask() {
        // Don't cancel the task, let it complete
        // currentTask?.cancel()
        // currentTask = nil
    }
    
    // MARK: - Message Retrieval
    @MainActor
    func updateMessages(threadId: String, force: Bool = false) async throws {
        guard networkMonitor.isConnected else {
            throw AppError.network(.invalidResponse)
        }
        
        let request = ListMessagesRequest(threadId: threadId, limit: 100, order: "desc")
        let response: ListMessagesResponse = try await service.sendRequest(request)
        
        // Sort messages by creation timestamp to ensure proper ordering
        let sortedMessages = response.data.sorted { $0.createdAt < $1.createdAt }
        
        if force || messages.isEmpty {
            messages = sortedMessages
            return
        }
        
        // Create a map of existing messages by ID for quick lookup
        let existingMessageMap = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        
        // Process new messages, preserving IDs for existing messages
        let updatedMessages = sortedMessages.map { newMessage in
            if let existingMessage = existingMessageMap[newMessage.id] {
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
        
        // Only update if there are changes
        if updatedMessages != messages {
            messages = updatedMessages
        }
    }
    
    func retrieveMessages(threadId: String) async throws -> [MessageResponse] {
        guard networkMonitor.isConnected else {
            throw AppError.network(.invalidResponse)
        }
        
        let request = ListMessagesRequest(threadId: threadId, limit: 100, order: "desc")
        let response: ListMessagesResponse = try await service.sendRequest(request)
        return response.data.reversed() // Reverse to show oldest first
    }
} 
