import Foundation

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