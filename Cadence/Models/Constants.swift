import SwiftUI

enum Constants {
    enum Colors {
        // Use semantic colors for better dark/light mode support
        static let primaryBackground = Color(uiColor: .systemBackground)
        static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
        // Updated message bubble colors to match iOS Messages
        static let userMessageBubble = Color.blue
        static let assistantMessageBubble = Color(uiColor: .systemGray5)
        static let textPrimary = Color(uiColor: .label)
        static let textSecondary = Color(uiColor: .secondaryLabel)
    }
    
    enum Layout {
        static let messageCornerRadius: CGFloat = 16
        static let maxMessageWidth: CGFloat = UIScreen.main.bounds.width * 0.75
        static let defaultPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
    }
    
    enum Animations {
        static let defaultSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let slowSpring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
}
