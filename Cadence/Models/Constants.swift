// Create a new file: Constants.swift

import SwiftUI

enum Constants {
    enum Colors {
        static let primaryBackground = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        static let userMessageBubble = Color.blue
        static let assistantMessageBubble = Color(uiColor: .secondarySystemFill)
    }
    
    enum Images {
        static let assistantAvatar = Image(systemName: "brain.head.profile")
        static let userAvatar = Image(systemName: "person.circle.fill")
        static let sendButton = Image(systemName: "arrow.up.circle.fill")
        static let loadingIndicator = Image(systemName: "ellipsis.bubble.fill")
    }
    
    enum Layout {
        static let messageCornerRadius: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let maxMessageWidth: CGFloat = UIScreen.main.bounds.width * 0.75
    }
}

// End of file. No additional code.
