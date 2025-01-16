import SwiftUI

struct ChatInputView: View {
    @Binding var messageText: String
    @FocusState private var isInputFocused: Bool
    @ObservedObject var viewModel: AssistantViewModel
    @Binding var showError: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.Layout.smallPadding) {
            HStack(spacing: Constants.Layout.smallPadding) {
                TextField("Type your message", text: $messageText, axis: .vertical)
                    .padding(Constants.Layout.defaultPadding)
                    .background(Constants.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.largeCornerRadius))
                    .disabled(viewModel.isLoading)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .textInputAutocapitalization(.sentences)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            Constants.Colors.textSecondary : .accentColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .animation(.easeInOut, value: messageText)
            }
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, Constants.Layout.smallPadding)
        .background(.ultraThinMaterial)
        .onAppear {
            isInputFocused = true
        }
    }
}

#Preview {
    let container = PreviewContainer.container
    let viewModel = AssistantViewModel(
        service: PreviewContainer.service,
        errorHandler: PreviewContainer.errorHandler,
        networkMonitor: PreviewContainer.networkMonitor,
        modelContext: container.mainContext
    )
    
    @State var messageText = ""
    @State var showError = false
    
    return ChatInputView(
        messageText: $messageText,
        viewModel: viewModel,
        showError: $showError,
        onSend: {}
    )
    .modelContainer(container)
} 