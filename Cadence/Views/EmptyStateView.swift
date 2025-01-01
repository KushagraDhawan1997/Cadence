import SwiftUI

struct EmptyStateView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @State private var showError = false
    
    var body: some View {
        ContentUnavailableView {
            Label("No Threads", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Create a new thread to start chatting")
        } actions: {
            Button(action: createThread) {
                Label("New Thread", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
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