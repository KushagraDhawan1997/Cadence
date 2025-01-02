import Foundation
import SwiftData

@Model
final class Workout {
    var id: UUID
    var type: WorkoutType
    var duration: Int?
    var notes: String?
    var timestamp: Date
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    
    init(type: WorkoutType, duration: Int? = nil, notes: String? = nil) {
        self.id = UUID()
        self.type = type
        self.duration = duration
        self.notes = notes
        self.timestamp = Date()
        self.exercises = []
    }
} 
