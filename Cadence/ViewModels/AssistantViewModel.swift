import Foundation
import SwiftData

@MainActor
class AssistantViewModel: ObservableObject {
    // MARK: - Dependencies
    internal let service: APIClient
    internal let errorHandler: ErrorHandling
    internal let networkMonitor: NetworkMonitor
    internal let modelContext: ModelContext
    
    // MARK: - Published Properties
    @Published var threads: [ThreadModel] = [] {
        didSet {
            groupedThreads = groupThreadsByDate(threads)
        }
    }
    @Published var groupedThreads: [GroupedThreads] = []
    @Published var currentThread: ThreadModel?
    @Published var messages: [MessageResponse] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var streamingResponse: String = ""
    @Published var isStreaming = false
    @Published var isWaitingForResponse = false
    
    // Add task storage
    internal var currentTask: Task<Void, Error>?
    
    // MARK: - Initialization
    init(service: APIClient, errorHandler: ErrorHandling, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        self.service = service
        self.errorHandler = errorHandler
        self.networkMonitor = networkMonitor
        self.modelContext = modelContext
        
        // Load threads on init
        Task {
            await loadThreads()
        }
    }
}
