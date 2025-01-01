import SwiftUI

struct MainContentView: View {
    @ObservedObject var viewModel: AssistantViewModel
    let networkMonitor: NetworkMonitor
    @Binding var showError: Bool
    
    var body: some View {
        ZStack {
            NetworkStatusView(networkMonitor: networkMonitor)
                .animation(.easeInOut, value: networkMonitor.isConnected)
            
            ThreadListView(
                viewModel: viewModel,
                showError: $showError
            )
            
            if viewModel.isLoading {
                LoadingView("Loading...")
                    .transition(.opacity)
            }
        }
    }
}