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
        .navigationTitle("Chats")
        .toolbar {
            Button(action: createThread) {
                Label("New Chat", systemImage: "plus")
                    .font(.headline)
            }
            .disabled(viewModel.isLoading)
        }
        .overlay {
            if viewModel.groupedThreads.isEmpty && !viewModel.isLoading {
                ThreadEmptyStateView(
                    title: "No Chats Yet",
                    message: "Start a new conversation with your AI assistant",
                    buttonTitle: "New Chat",
                    action: createThread
                )
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