import SwiftUI

struct StreamingMessageView: View {
    let response: String
    @State private var isAnimating = false
    let viewModel: AssistantViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            if response.isEmpty {
                TypingIndicatorView()
                    .padding(.leading, Constants.Layout.defaultPadding)
            } else {
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .leading)
                    .padding(.leading, Constants.Layout.defaultPadding)
                Spacer()
            }
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, Constants.Layout.smallPadding)
    }
    
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding / 2) {
            Text(LocalizedStringKey(response))
                .textSelection(.enabled)
                .foregroundColor(Constants.Colors.textPrimary)
                .padding(.horizontal, Constants.Layout.defaultPadding)
                .padding(.vertical, Constants.Layout.smallPadding)
                .background(Constants.Colors.assistantMessageBubble)
                .cornerRadius(Constants.Layout.messageCornerRadius)
        }
        .scaleEffect(isAnimating ? 1 : 0.97)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(Constants.Animations.defaultSpring) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Assistant is responding")
    }
} 