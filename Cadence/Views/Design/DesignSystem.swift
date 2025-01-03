import SwiftUI

enum Design {
    enum Colors {
        static let primary = Color.accentColor
        static let secondary = Color(uiColor: .secondaryLabel)
        static let background = Color(uiColor: .systemBackground)
        static let groupedBackground = Color(uiColor: .systemGroupedBackground)
        static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    }
    
    enum Typography {
        static func largeTitle(weight: Font.Weight = .regular) -> Font {
            .largeTitle.weight(weight)
        }
        
        static func title(weight: Font.Weight = .regular) -> Font {
            .title.weight(weight)
        }
        
        static func title2(weight: Font.Weight = .regular) -> Font {
            .title2.weight(weight)
        }
        
        static func title3(weight: Font.Weight = .regular) -> Font {
            .title3.weight(weight)
        }
        
        static func headline(weight: Font.Weight = .semibold) -> Font {
            .headline.weight(weight)
        }
        
        static func subheadline(weight: Font.Weight = .regular) -> Font {
            .subheadline.weight(weight)
        }
        
        static func body(weight: Font.Weight = .regular) -> Font {
            .body.weight(weight)
        }
        
        static func callout(weight: Font.Weight = .regular) -> Font {
            .callout.weight(weight)
        }
        
        static func caption(weight: Font.Weight = .medium) -> Font {
            .caption.weight(weight)
        }
        
        static func caption2(weight: Font.Weight = .regular) -> Font {
            .caption2.weight(weight)
        }
    }
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    enum Haptics {
        static func light() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        static func medium() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        static func heavy() {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        }
    }
}

// MARK: - View Modifiers

struct GlassBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Design.Colors.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func glassBackground() -> some View {
        modifier(GlassBackgroundModifier())
    }
} 