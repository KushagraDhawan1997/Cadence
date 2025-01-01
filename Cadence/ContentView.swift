import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: AssistantViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    @State private var showError = false
    @State private var showChat = false
    
    init(service: APIClient, errorHandler: ErrorHandling, networkMonitor: NetworkMonitor) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(service: service, errorHandler: errorHandler))
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

#Preview {
    // Initialize preview dependencies
    let networkMonitor = NetworkMonitor()
    let container = DependencyContainer.shared
    container.registerServices()
    
    if let service = container.resolve(APIClient.self),
       let errorHandler = container.resolve(ErrorHandling.self) {
        return ContentView(
            service: service,
            errorHandler: errorHandler,
            networkMonitor: networkMonitor
        )
    } else {
        return Text("Failed to initialize preview")
    }
}