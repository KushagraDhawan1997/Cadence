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
        case push = "Push"
        case pull = "Pull"
        case legs = "Legs"
        case core = "Core"
        case cardio = "Cardio"
        case other = "Other"
    }
    
    // MARK: - Exercise Library
    static let exercises: [Exercise] = [
        // MARK: Push Exercises
        .init(
            primaryName: "Bench Press",
            variations: ["Flat Bench", "BB Bench", "Barbell Bench Press", "Flat Barbell Bench"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Incline Bench Press",
            variations: ["Incline Bench", "Incline BB Press", "Incline Barbell Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Decline Bench Press",
            variations: ["Decline Bench", "Decline BB Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Overhead Press",
            variations: ["Military Press", "OHP", "Shoulder Press", "Standing Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Dumbbell Bench Press",
            variations: ["DB Bench", "Flat DB Press", "Dumbbell Press"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Incline Dumbbell Press",
            variations: ["Incline DB Press", "Incline Dumbbell Bench"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Tricep Pushdown",
            variations: ["Rope Pushdown", "Cable Tricep Extension", "Tricep Extension"],
            category: .push,
            isCompound: false
        ),
        .init(
            primaryName: "Lateral Raise",
            variations: ["Side Raise", "Dumbbell Lateral Raise", "DB Lateral Raise"],
            category: .push,
            isCompound: false
        ),
        .init(
            primaryName: "Front Raise",
            variations: ["DB Front Raise", "Plate Front Raise"],
            category: .push,
            isCompound: false
        ),
        .init(
            primaryName: "Dips",
            variations: ["Chest Dips", "Tricep Dips", "Parallel Bar Dips"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Close Grip Bench Press",
            variations: ["CGBP", "Close Grip BP"],
            category: .push,
            isCompound: true
        ),
        .init(
            primaryName: "Skull Crushers",
            variations: ["Lying Tricep Extension", "EZ Bar Skull Crushers"],
            category: .push,
            isCompound: false
        ),
        
        // MARK: Pull Exercises
        .init(
            primaryName: "Barbell Row",
            variations: ["BB Row", "Bent Over Row", "Pendlay Row"],
            category: .pull,
            isCompound: true
        ),
        .init(
            primaryName: "Pull Up",
            variations: ["Chin Up", "Wide Grip Pull Up"],
            category: .pull,
            isCompound: true
        ),
        .init(
            primaryName: "Lat Pulldown",
            variations: ["Wide Grip Lat Pulldown", "Cable Lat Pulldown"],
            category: .pull,
            isCompound: true
        ),
        .init(
            primaryName: "Face Pull",
            variations: ["Cable Face Pull", "Rope Face Pull"],
            category: .pull,
            isCompound: false
        ),
        .init(
            primaryName: "Dumbbell Row",
            variations: ["Single Arm Row", "DB Row", "One Arm Row"],
            category: .pull,
            isCompound: true
        ),
        .init(
            primaryName: "Barbell Curl",
            variations: ["BB Curl", "Standing Barbell Curl"],
            category: .pull,
            isCompound: false
        ),
        .init(
            primaryName: "Dumbbell Curl",
            variations: ["DB Curl", "Standing Dumbbell Curl", "Alternating Curl"],
            category: .pull,
            isCompound: false
        ),
        .init(
            primaryName: "Hammer Curl",
            variations: ["DB Hammer Curl", "Standing Hammer Curl"],
            category: .pull,
            isCompound: false
        ),
        .init(
            primaryName: "Preacher Curl",
            variations: ["EZ Bar Preacher Curl", "DB Preacher Curl"],
            category: .pull,
            isCompound: false
        ),
        .init(
            primaryName: "Cable Row",
            variations: ["Seated Cable Row", "Low Row"],
            category: .pull,
            isCompound: true
        ),
        
        // MARK: Leg Exercises
        .init(
            primaryName: "Squat",
            variations: ["Back Squat", "Barbell Squat", "BB Squat"],
            category: .legs,
            isCompound: true
        ),
        .init(
            primaryName: "Front Squat",
            variations: ["BB Front Squat", "Barbell Front Squat"],
            category: .legs,
            isCompound: true
        ),
        .init(
            primaryName: "Romanian Deadlift",
            variations: ["RDL", "BB RDL", "Stiff Leg Deadlift"],
            category: .legs,
            isCompound: true
        ),
        .init(
            primaryName: "Leg Press",
            variations: ["45 Degree Leg Press", "Sled Leg Press"],
            category: .legs,
            isCompound: true
        ),
        .init(
            primaryName: "Bulgarian Split Squat",
            variations: ["Split Squat", "Rear Foot Elevated Split Squat"],
            category: .legs,
            isCompound: true
        ),
        .init(
            primaryName: "Leg Extension",
            variations: ["Machine Leg Extension", "Quad Extension"],
            category: .legs,
            isCompound: false
        ),
        .init(
            primaryName: "Leg Curl",
            variations: ["Hamstring Curl", "Lying Leg Curl", "Seated Leg Curl"],
            category: .legs,
            isCompound: false
        ),
        .init(
            primaryName: "Calf Raise",
            variations: ["Standing Calf Raise", "Seated Calf Raise", "Smith Machine Calf Raise"],
            category: .legs,
            isCompound: false
        ),
        .init(
            primaryName: "Hip Thrust",
            variations: ["BB Hip Thrust", "Glute Bridge"],
            category: .legs,
            isCompound: true
        ),
        .init(
            primaryName: "Lunges",
            variations: ["Walking Lunges", "DB Lunges", "BB Lunges"],
            category: .legs,
            isCompound: true
        ),
        
        // MARK: Core Exercises
        .init(
            primaryName: "Plank",
            variations: ["Forearm Plank", "High Plank"],
            category: .core,
            isCompound: false
        ),
        .init(
            primaryName: "Russian Twist",
            variations: ["Weighted Russian Twist", "Plate Russian Twist"],
            category: .core,
            isCompound: false
        ),
        .init(
            primaryName: "Cable Crunch",
            variations: ["Kneeling Cable Crunch", "Cable Woodchop"],
            category: .core,
            isCompound: false
        ),
        .init(
            primaryName: "Ab Wheel Rollout",
            variations: ["Ab Rollout", "Barbell Rollout"],
            category: .core,
            isCompound: true
        ),
        .init(
            primaryName: "Hanging Leg Raise",
            variations: ["Hanging Knee Raise", "Captain's Chair Leg Raise"],
            category: .core,
            isCompound: false
        ),
        .init(
            primaryName: "Dead Bug",
            variations: ["Weighted Dead Bug"],
            category: .core,
            isCompound: false
        ),
        
        // MARK: Cardio Exercises
        .init(
            primaryName: "Treadmill Run",
            variations: ["Running", "Jogging", "Sprint"],
            category: .cardio,
            isCompound: true
        ),
        .init(
            primaryName: "Rowing",
            variations: ["Row Machine", "Ergometer"],
            category: .cardio,
            isCompound: true
        ),
        .init(
            primaryName: "Cycling",
            variations: ["Bike", "Stationary Bike", "Spin Bike"],
            category: .cardio,
            isCompound: true
        ),
        .init(
            primaryName: "Jump Rope",
            variations: ["Skipping", "Skip Rope"],
            category: .cardio,
            isCompound: true
        ),
        .init(
            primaryName: "Burpee",
            variations: ["Burpees"],
            category: .cardio,
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
    
    // Helper to get compound exercises
    static func compoundExercises() -> [Exercise] {
        exercises.filter { $0.isCompound }
    }
    
    // Helper to get isolation exercises
    static func isolationExercises() -> [Exercise] {
        exercises.filter { !$0.isCompound }
    }
} 