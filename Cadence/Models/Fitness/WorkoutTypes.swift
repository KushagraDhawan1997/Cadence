import Foundation

// Body part target defines the area focus
enum WorkoutType: String, Codable, CaseIterable {
    // Push Pull Legs Split
    case push = "push"
    case pull = "pull"
    case legs = "legs"
    
    // Upper Body Specific
    case chestTriceps = "chest_triceps"
    case backBiceps = "back_biceps"
    case shoulders = "shoulders"
    case arms = "arms"
    
    // Lower Body Specific
    case quadsCalves = "quads_calves"
    case hamstringsGlutes = "hamstrings_glutes"
    
    // Full Body
    case fullBody = "full_body"
    case core = "core"
    
    // Cardio & Others
    case cardio = "cardio"
    case hiit = "hiit"
    case flexibility = "flexibility"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        // PPL
        case .push: return "Push"
        case .pull: return "Pull"
        case .legs: return "Legs"
        // Upper Body
        case .chestTriceps: return "Chest & Triceps"
        case .backBiceps: return "Back & Biceps"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        // Lower Body
        case .quadsCalves: return "Quads & Calves"
        case .hamstringsGlutes: return "Hamstrings & Glutes"
        // Full Body
        case .fullBody: return "Full Body"
        case .core: return "Core"
        // Cardio & Others
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .flexibility: return "Flexibility"
        case .custom: return "Custom"
        }
    }
    
    var iconName: String {
        switch self {
        // PPL
        case .push: return "figure.strengthtraining.traditional"
        case .pull: return "figure.climbing"
        case .legs: return "figure.walk"
        // Upper Body
        case .chestTriceps: return "figure.arms.open"
        case .backBiceps: return "figure.mixed.cardio"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.american.football"
        // Lower Body
        case .quadsCalves: return "figure.run"
        case .hamstringsGlutes: return "figure.step.training"
        // Full Body
        case .fullBody: return "figure.mixed.cardio"
        case .core: return "figure.core.training"
        // Cardio & Others
        case .cardio: return "heart.circle"
        case .hiit: return "figure.highintensity.intervaltraining"
        case .flexibility: return "figure.flexibility"
        case .custom: return "figure.mixed.cardio"
        }
    }
    
    // Helper property to group workouts
    var category: WorkoutCategory {
        switch self {
        case .push, .pull, .chestTriceps, .backBiceps, .shoulders, .arms:
            return .upperBody
        case .legs, .quadsCalves, .hamstringsGlutes:
            return .lowerBody
        case .fullBody, .core:
            return .fullBody
        case .cardio, .hiit:
            return .cardio
        case .flexibility, .custom:
            return .other
        }
    }
}

// For organizing workouts in the filter menu
enum WorkoutCategory: String, CaseIterable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.walk"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "heart.circle"
        case .other: return "figure.flexibility"
        }
    }
}
