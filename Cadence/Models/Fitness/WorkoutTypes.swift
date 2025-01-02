import Foundation

// Body part target defines the area focus
enum WorkoutType: String, Codable, CaseIterable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case core = "core"
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    case cardio = "cardio"
    case flexibility = "flexibility"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .upperBody: return "Upper Body"
        case .lowerBody: return "Lower Body"
        case .fullBody: return "Full Body"
        case .core: return "Core"
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.walk"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .core: return "figure.core.training"
        case .push: return "figure.boxing"
        case .pull: return "figure.climbing"
        case .legs: return "figure.run"
        case .cardio: return "heart.circle"
        case .flexibility: return "figure.flexibility"
        case .custom: return "figure.mixed.cardio"
        }
    }
}
