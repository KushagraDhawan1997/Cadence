import SwiftUI
import SwiftData

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let workout: Workout
    
    @State private var name = ""
    @State private var equipmentType = EquipmentType.barbell
    @State private var sets: [SetInput] = [SetInput()]
    
    struct SetInput: Identifiable {
        let id = UUID()
        var reps = 12
        var weightType = WeightType.perSide
        var weightValue: Double = 20
        var barWeight: Double = 20
    }
    
    private func save() {
        // Validate exercise against library
        guard let libraryExercise = ExerciseLibrary.findExercise(named: name) else {
            // If not found, could show an alert here
            return
        }
        
        let exercise = Exercise(name: libraryExercise.primaryName, equipmentType: equipmentType, workout: workout)
        modelContext.insert(exercise)
        
        for setInput in sets {
            let set = ExerciseSet(
                reps: setInput.reps,
                weightType: setInput.weightType,
                weightValue: setInput.weightValue,
                barWeight: setInput.weightType == .perSide ? setInput.barWeight : nil,
                exercise: exercise
            )
            modelContext.insert(set)
            exercise.sets.append(set)
        }
        
        workout.exercises.append(exercise)
        try? modelContext.save()
        
        Design.Haptics.medium()
        dismiss()
    }
    
    var body: some View {
        ExerciseFormView(
            name: $name,
            equipmentType: $equipmentType,
            sets: $sets,
            saveTitle: "Add",
            onSave: { save() },
            onCancel: { dismiss() }
        )
    }
}

#Preview {
    let container = PreviewContainer.container
    let workout = try! container.mainContext.fetch(FetchDescriptor<Workout>()).first!
    
    return NavigationStack {
        AddExerciseView(workout: workout)
            .modelContainer(container)
    }
}
