import SwiftUI

struct MessageView: View {
    let message: MessageResponse
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            if message.role == "assistant" {
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .leading)
                Spacer()
            } else {
                Spacer()
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .trailing)
            }
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, Constants.Layout.smallPadding / 2)
    }
    
    private var messageContent: some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: Constants.Layout.smallPadding / 2) {
            ForEach(Array(message.content.enumerated()), id: \.1.type) { index, content in
                if let text = content.text {
                    Text(LocalizedStringKey(text.value))
                        .textSelection(.enabled)
                        .foregroundColor(message.role == "user" ? .white : Constants.Colors.textPrimary)
                        .padding(.horizontal, Constants.Layout.defaultPadding)
                        .padding(.vertical, Constants.Layout.smallPadding)
                        .background(
                            message.role == "user" ?
                                Constants.Colors.userMessageBubble :
                                Constants.Colors.assistantMessageBubble
                        )
                        .cornerRadius(Constants.Layout.messageCornerRadius)
                        .padding(message.role == "user" ? .trailing : .leading, Constants.Layout.smallPadding)
                }
            }
        }
        .scaleEffect(isAnimating ? 1 : 0.97)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(Constants.Animations.defaultSpring) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == "assistant" ? "Assistant message" : "Your message")
    }
} 