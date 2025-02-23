import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showError = false
    @StateObject private var viewModel: AssistantViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    
    init(service: APIClient, errorHandler: ErrorHandling, networkMonitor: NetworkMonitor, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(
            service: service,
            errorHandler: errorHandler,
            networkMonitor: networkMonitor,
            modelContext: modelContext
        ))
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
    let container = try! ModelContainer(for: PreviewContainer.schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    return ContentView(
        service: PreviewContainer.service,
        errorHandler: PreviewContainer.errorHandler,
        networkMonitor: PreviewContainer.networkMonitor,
        modelContext: container.mainContext
    )
    .modelContainer(container)
}
