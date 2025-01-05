import Foundation
import SwiftData

@Observable
class WorkoutService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createWorkout(type: String, duration: Int? = nil, notes: String? = nil) throws -> UUID {
        // Convert string type to WorkoutType enum
        guard let workoutType = WorkoutType.allCases.first(where: { $0.rawValue == type }) else {
            throw WorkoutError.invalidWorkoutType
        }
        
        // Create and insert workout
        let workout = Workout(
            type: workoutType,
            duration: duration,
            notes: notes
        )
        modelContext.insert(workout)
        try modelContext.save()
        
        return workout.id
    }
    
    func addExercise(workoutId: UUID, 
                     name: String, 
                     equipmentType: EquipmentType, 
                     sets: [[String: Any]]) throws -> Exercise {
        // 1. Get workout
        guard let workout = try modelContext.fetch(
            FetchDescriptor<Workout>(
                predicate: #Predicate<Workout> { $0.id == workoutId }
            )
        ).first else {
            throw WorkoutError.workoutNotFound
        }
        
        // 2. Create exercise
        let exercise = Exercise(
            name: name,
            equipmentType: equipmentType,
            workout: workout
        )
        modelContext.insert(exercise)
        
        // 3. Create and add sets
        for setData in sets {
            let reps = setData["reps"] as! Int
            let weightType = WeightType(rawValue: setData["weight_type"] as! String)!
            let weightValue = setData["weight_value"] as? Double
            let barWeight = setData["bar_weight"] as? Double
            
            let exerciseSet = ExerciseSet(
                reps: reps,
                weightType: weightType,
                weightValue: weightValue,
                barWeight: barWeight,
                exercise: exercise
            )
            modelContext.insert(exerciseSet)
            exercise.sets.append(exerciseSet)
        }
        
        // 4. Add to workout and save
        workout.exercises.append(exercise)
        try modelContext.save()
        
        return exercise
    }
}

enum WorkoutError: Error {
    case workoutNotFound
    case invalidWorkoutType
} 