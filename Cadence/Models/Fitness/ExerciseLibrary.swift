import Foundation

struct ExerciseLibrary {
    struct Exercise: Hashable {
        let primaryName: String
        let variations: [String]
        let category: WorkoutCategory
        let isCompound: Bool
        
        // Helper to check if a given name matches this exercise
        func matches(_ name: String) -> Bool {
            let lowercaseName = name.lowercased()
            return primaryName.lowercased() == lowercaseName ||
                   variations.map { $0.lowercased() }.contains(lowercaseName)
        }
    }
    
    enum WorkoutCategory: String {
        case push = "push"
        case pull = "pull"
        case legs = "legs"
        case other = "other"
    }
    
    // Common push exercises to start with
    static let exercises: [Exercise] = [
        .init(
            primaryName: "Bench Press",
            variations: ["Flat Bench", "BB Bench", "Barbell Bench Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Incline Bench Press",
            variations: ["Incline Bench", "Incline BB Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Overhead Press",
            variations: ["Military Press", "OHP", "Shoulder Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Tricep Pushdown",
            variations: ["Rope Pushdown", "Cable Tricep Extension"],
            category: .push,
            isCompound: false
        ),
        .init(
            primaryName: "Lateral Raise",
            variations: ["Side Raise", "Dumbbell Lateral Raise"],
            category: .push,
            isCompound: false
        ),
        .init(
            primaryName: "Dips",
            variations: ["Chest Dips", "Tricep Dips"],
            category: .push,
            isCompound: true
        )
    ]
    
    // Helper to find matching exercise
    static func findExercise(named name: String) -> Exercise? {
        exercises.first { $0.matches(name) }
    }
    
    // Helper to get exercises by category
    static func exercises(for category: WorkoutCategory) -> [Exercise] {
        exercises.filter { $0.category == category }
    }
} 