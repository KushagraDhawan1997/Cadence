import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @State private var messageText = ""
    @State private var showError = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            MessageListView(viewModel: viewModel)
            
            Divider()
            
            ChatInputView(
                messageText: $messageText,
                viewModel: viewModel,
                showError: $showError,
                onSend: sendMessage
            )
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            isInputFocused = true
        }
        .onDisappear {
            viewModel.cancelCurrentTask()
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        
        Task {
            do {
                try await viewModel.sendMessage(message)
            } catch {
                showError = true
            }
        }
    }
} 