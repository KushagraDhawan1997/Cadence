import Foundation
import SwiftData

// MARK: - Persistence Management
extension AssistantViewModel {
    func loadThreads() async {
        do {
            // Always load from persistence first
            let descriptor = FetchDescriptor<StoredThread>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            let storedThreads = try modelContext.fetch(descriptor)
            
            // Convert stored threads to API model
            threads = storedThreads.map { stored in
                ThreadModel(id: stored.id, object: "thread", createdAt: stored.createdAt)
            }
            
            // If we have a current thread, load its messages
            if let currentThread = currentThread,
               let storedThread = storedThreads.first(where: { $0.id == currentThread.id }) {
                messages = storedThread.storedMessages.map { stored in
                    MessageResponse(
                        id: stored.id,
                        object: "thread.message",
                        createdAt: stored.createdAt,
                        threadId: stored.threadId,
                        role: stored.role,
                        content: [MessageContent(
                            type: "text",
                            text: TextContent(value: stored.content, annotations: nil)
                        )]
                    )
                }.sorted { $0.createdAt < $1.createdAt }
            }
            
            // If online, sync with API
            if networkMonitor.isConnected {
                let request = ListThreadsRequest()
                let response: ListThreadsResponse = try await service.sendRequest(request)
                threads = response.data
                
                // Update stored threads
                await syncStoredThreads(with: threads)
            }
        } catch {
            self.error = error
        }
    }
    
    private func syncStoredThreads(with apiThreads: [ThreadModel]) async {
        let descriptor = FetchDescriptor<StoredThread>()
        do {
            let storedThreads = try modelContext.fetch(descriptor)
            
            // Remove stored threads that no longer exist in API
            for stored in storedThreads {
                if !apiThreads.contains(where: { $0.id == stored.id }) {
                    modelContext.delete(stored)
                }
            }
            
            // Add or update stored threads from API
            for thread in apiThreads {
                if let stored = storedThreads.first(where: { $0.id == thread.id }) {
                    stored.createdAt = thread.createdAt
                } else {
                    let stored = StoredThread(from: thread)
                    modelContext.insert(stored)
                }
            }
            
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
    
    func syncStoredMessages(threadId: String, with apiMessages: [MessageResponse]) async {
        guard let storedThread = try? modelContext.fetch(FetchDescriptor<StoredThread>(
            predicate: #Predicate<StoredThread> { thread in
                thread.id == threadId
            }
        )).first else { return }
        
        do {
            // Remove old messages
            storedThread.storedMessages = []
            
            // Add new messages
            for message in apiMessages {
                let stored = StoredMessage(from: message)
                storedThread.storedMessages.append(stored)
            }
            
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
} 