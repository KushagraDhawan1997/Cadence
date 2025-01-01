import SwiftUI

struct TypingIndicatorView: View {
    var body: some View {
        ProgressView()
            .padding(.vertical, 8)
            .padding(.horizontal)
            .accessibilityLabel("Assistant is typing")
    }
} 