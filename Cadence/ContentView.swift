import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: AssistantViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    @State private var showError = false
    @State private var showChat = false
    
    init(service: APIClient, errorHandler: ErrorHandling, networkMonitor: NetworkMonitor) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(service: service, errorHandler: errorHandler, networkMonitor: networkMonitor))
        self.networkMonitor = networkMonitor
    }
    
    var body: some View {
        NavigationStack {
            MainContentView(
                viewModel: viewModel,
                networkMonitor: networkMonitor,
                showError: $showError
            )
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

// MARK: - Preview Helpers
extension ContentView {
    static func createPreview() -> ContentView {
        let networkMonitor = NetworkMonitor()
        let container = DependencyContainer.shared
        container.registerServices()
        container.register(NetworkMonitor.self, instance: networkMonitor)
        
        guard let service = container.resolve(APIClient.self),
              let errorHandler = container.resolve(ErrorHandling.self),
              let networkMonitor = container.resolve(NetworkMonitor.self) else {
            fatalError("Failed to initialize preview dependencies")
        }
        
        return ContentView(
            service: service,
            errorHandler: errorHandler,
            networkMonitor: networkMonitor
        )
    }
}

#Preview {
    ContentView.createPreview()
}
