import Foundation
import SwiftData

@Model
final class StoredThread {
    var id: String
    var title: String
    var createdAt: Int
    @Relationship(deleteRule: .cascade) var storedMessages: [StoredMessage]
    
    init(from thread: ThreadModel) {
        self.id = thread.id
        self.title = "Thread \(thread.id.suffix(4))"
        self.createdAt = thread.createdAt
        self.storedMessages = []
    }
}

@Model
final class StoredMessage {
    var id: String
    var content: String
    var role: String
    var createdAt: Int
    var threadId: String
    
    init(from message: MessageResponse) {
        self.id = message.id
        self.content = message.content.first?.text?.value ?? ""
        self.role = message.role
        self.createdAt = message.createdAt
        self.threadId = message.threadId
    }
}

extension AssistantViewModel {
    enum ThreadGroup: String, CaseIterable {
        case today = "Today"
        case yesterday = "Yesterday"
        case lastWeek = "Last Week"
        case earlier = "Earlier"
    }
    
    struct GroupedThreads: Identifiable {
        let id: ThreadGroup
        let threads: [ThreadModel]
        var title: String { id.rawValue }
        var count: Int { threads.count }
    }
} 