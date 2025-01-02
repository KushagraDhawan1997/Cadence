import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showError = false
    @StateObject private var viewModel: AssistantViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    
    init(service: APIClient, errorHandler: ErrorHandling, networkMonitor: NetworkMonitor) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(service: service, errorHandler: errorHandler, networkMonitor: networkMonitor))
        self.networkMonitor = networkMonitor
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ThreadListView(viewModel: viewModel, showError: $showError)
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.fill")
            }
            .tag(0)
            
            WorkoutHistoryView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

#Preview {
    // Create preview-specific dependencies
    let previewContainer = try! ModelContainer(for: Workout.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let previewContext = ModelContext(previewContainer)
    
    // Create dependencies
    let networkMonitor = NetworkMonitor()
    let errorHandler = ErrorHandler()
    let apiService = OpenAIService(
        networkMonitor: networkMonitor,
        errorHandler: errorHandler,
        modelContext: previewContext
    )
    
    return ContentView(
        service: apiService,
        errorHandler: errorHandler,
        networkMonitor: networkMonitor
    )
    .modelContainer(previewContainer)
}
