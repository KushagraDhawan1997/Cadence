import Foundation
import SwiftData

// MARK: - Thread Management
extension AssistantViewModel {
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
                
                // Save to persistence
                let stored = StoredThread(from: newThread)
                modelContext.insert(stored)
                try modelContext.save()
                
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
                // Force update messages when switching threads
                try await updateMessages(threadId: thread.id, force: true)
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
        
        // Delete from persistence
        let threadId = thread.id // Capture the ID to use in predicate
        let descriptor = FetchDescriptor<StoredThread>(predicate: #Predicate<StoredThread> { storedThread in
            storedThread.id == threadId
        })
        if let storedThread = try? modelContext.fetch(descriptor).first {
            modelContext.delete(storedThread)
            try? modelContext.save()
        }
        
        // TODO: Add API call for thread deletion when available
        // try await service.deleteThread(thread.id)
    }
    
    func groupThreadsByDate(_ threads: [ThreadModel]) -> [GroupedThreads] {
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
        
        return ThreadGroup.allCases.map { group in
            GroupedThreads(id: group, threads: grouped[group, default: []])
        }
    }
} 