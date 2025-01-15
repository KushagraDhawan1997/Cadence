import SwiftUI
import SwiftData

@MainActor
struct PreviewContainer {
    static var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Workout.self, Exercise.self, ExerciseSet.self,
            configurations: config
        )
        
        // Create sample data
        let context = container.mainContext
        let workout1 = Workout(type: .chestTriceps, duration: 45, notes: "Great chest day!")
        let workout2 = Workout(type: .cardio, duration: 30, notes: "Morning run")
        let workout3 = Workout(type: .hamstringsGlutes, duration: 60, notes: "Leg day!")
        
        workout1.timestamp = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        workout2.timestamp = Calendar.current.date(byAdding: .hour, value: -3, to: Date())!
        
        context.insert(workout1)
        context.insert(workout2)
        context.insert(workout3)
        
        let benchPress = Exercise(name: "Bench Press", equipmentType: .barbell, workout: workout1)
        let tricepExtension = Exercise(name: "Tricep Extension", equipmentType: .cable, workout: workout1)
        
        context.insert(benchPress)
        context.insert(tricepExtension)
        
        let set1 = ExerciseSet(reps: 12, weightType: .perSide, weightValue: 20, barWeight: 20, exercise: benchPress)
        let set2 = ExerciseSet(reps: 10, weightType: .perSide, weightValue: 25, barWeight: 20, exercise: benchPress)
        let set3 = ExerciseSet(reps: 15, weightType: .total, weightValue: 20, exercise: tricepExtension)
        
        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        
        workout1.exercises = [benchPress, tricepExtension]
        benchPress.sets = [set1, set2]
        tricepExtension.sets = [set3]
        
        try? context.save()
        return container
    }()
    
    // Preview dependencies
    static let networkMonitor: NetworkMonitor = NetworkMonitor()
    static let errorHandler: ErrorHandler = ErrorHandler()
    
    static var service: APIClient {
        OpenAIService(
            networkMonitor: networkMonitor,
            errorHandler: errorHandler,
            modelContext: container.mainContext
        )
    }
} 
