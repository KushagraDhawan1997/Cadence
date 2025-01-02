import Foundation
import SwiftData

enum EquipmentType: String, Codable, CaseIterable {
    case barbell = "barbell"
    case dumbbell = "dumbbell"
    case machine = "machine"
    case bodyweight = "bodyweight"
    case cable = "cable"
    
    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .cable: return "Cable"
        }
    }
    
    var iconName: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell"
        case .machine: return "figure.cross.training"
        case .bodyweight: return "figure.walk"
        case .cable: return "figure.mixed.cardio"
        }
    }
}

enum WeightType: String, Codable, CaseIterable {
    case perSide = "per_side"      // For barbell (weight per side)
    case total = "total"           // For machines, total barbell weight
    case perDumbbell = "per_db"    // For dumbbells (weight per dumbbell)
    case bodyweight = "bodyweight"  // For bodyweight exercises
    
    var displayName: String {
        switch self {
        case .perSide: return "Per Side"
        case .total: return "Total Weight"
        case .perDumbbell: return "Per Dumbbell"
        case .bodyweight: return "Bodyweight"
        }
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var equipmentType: EquipmentType
    var sets: [ExerciseSet]
    var workout: Workout?
    var timestamp: Date
    
    init(name: String, equipmentType: EquipmentType, workout: Workout? = nil) {
        self.id = UUID()
        self.name = name
        self.equipmentType = equipmentType
        self.sets = []
        self.workout = workout
        self.timestamp = Date()
    }
}

@Model
final class ExerciseSet {
    var id: UUID
    var reps: Int
    var weightType: WeightType
    var weightValue: Double?
    var barWeight: Double?
    var exercise: Exercise?
    var timestamp: Date
    
    init(reps: Int, 
         weightType: WeightType, 
         weightValue: Double? = nil,
         barWeight: Double? = nil,
         exercise: Exercise? = nil) {
        self.id = UUID()
        self.reps = reps
        self.weightType = weightType
        self.weightValue = weightValue
        self.barWeight = barWeight
        self.exercise = exercise
        self.timestamp = Date()
    }
    
    var totalWeight: Double? {
        guard let weightValue = weightValue else { return nil }
        
        switch weightType {
        case .perSide:
            // If it's per side, multiply by 2 and add bar weight
            let plateWeight = weightValue * 2
            return (barWeight ?? 0) + plateWeight
        case .total, .perDumbbell:
            // For total weight or dumbbells, just return the weight value
            return weightValue
        case .bodyweight:
            // For bodyweight, return nil or could return user's body weight if we track that
            return nil
        }
    }
} 