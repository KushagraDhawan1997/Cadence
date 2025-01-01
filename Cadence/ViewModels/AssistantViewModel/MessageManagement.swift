import Foundation

// MARK: - Message Management
extension AssistantViewModel {
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
    func updateMessages(threadId: String) async throws {
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
    
    func retrieveMessages(threadId: String) async throws -> [MessageResponse] {
        let request = ListMessagesRequest(threadId: threadId, limit: 100, order: "desc")
        let response: ListMessagesResponse = try await service.sendRequest(request)
        return response.data.reversed() // Reverse to show oldest first
    }
} 