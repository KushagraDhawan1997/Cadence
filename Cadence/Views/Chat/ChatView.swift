import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @State private var messageText = ""
    @State private var showError = false
    @State private var showDisconnectedAlert = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
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
        .navigationTitle("Thread \(viewModel.currentThread?.id.suffix(4) ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .alert("No Connection", isPresented: $showDisconnectedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Please check your internet connection and try again.")
        }
        .onAppear {
            isInputFocused = true
            
            // Check connection on appear
            if !viewModel.networkMonitor.isConnected {
                showDisconnectedAlert = true
            }
        }
        .onDisappear {
            viewModel.cleanupCurrentTask()
        }
        .onChange(of: viewModel.networkMonitor.isConnected) { oldValue, newValue in
            if !newValue {
                showDisconnectedAlert = true
            }
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        guard viewModel.networkMonitor.isConnected else {
            showDisconnectedAlert = true
            return
        }
        
        messageText = ""
        isInputFocused = false
        
        Task {
            do {
                try await viewModel.sendMessage(message)
                isInputFocused = true
            } catch {
                showError = true
                isInputFocused = true
            }
        }
    }
} 