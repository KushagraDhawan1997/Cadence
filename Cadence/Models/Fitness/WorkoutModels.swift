import Foundation

struct Exercise: Codable {
    let name: String
    let sets: Int
    let reps: Int
}

struct Workout: Codable {
    let type: WorkoutType
    let duration: Int
    let exercises: [Exercise]?
    let notes: String?
    let timestamp: Date
    
    init(type: WorkoutType, duration: Int, exercises: [Exercise]? = nil, notes: String? = nil) {
        self.type = type
        self.duration = duration
        self.exercises = exercises
        self.notes = notes
        self.timestamp = Date()
    }
} 