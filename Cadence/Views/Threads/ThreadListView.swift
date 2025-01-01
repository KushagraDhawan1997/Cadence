import SwiftUI

struct ThreadListView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @Binding var showError: Bool
    
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        List {
            ForEach(viewModel.groupedThreads) { group in
                ThreadGroupSectionView(
                    group: group,
                    viewModel: viewModel,
                    showError: $showError
                )
            }
        }
        .navigationTitle("Threads")
        .toolbar {
            Button(action: createThread) {
                Label("New Thread", systemImage: "plus")
                    .font(.headline)
            }
            .disabled(viewModel.isLoading)
        }
        .overlay {
            if viewModel.groupedThreads.isEmpty && !viewModel.isLoading {
                EmptyStateView(viewModel: viewModel)
            }
        }
    }
    
    private func createThread() {
        Task {
            do {
                try await viewModel.createThread()
            } catch {
                showError = true
            }
        }
    }
} 