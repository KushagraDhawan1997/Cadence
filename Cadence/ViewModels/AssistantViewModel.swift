import Foundation

// MARK: - Custom Errors removed since we're using AppError

@MainActor
class AssistantViewModel: ObservableObject {
    // MARK: - Dependencies
    internal let service: APIClient
    internal let errorHandler: ErrorHandling
    
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
    init(service: APIClient, errorHandler: ErrorHandling) {
        self.service = service
        self.errorHandler = errorHandler
    }
}
