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
}
