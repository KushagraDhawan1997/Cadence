import SwiftUI
import SwiftData

struct EditExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let exercise: Exercise
    
    @State private var name: String
    @State private var equipmentType: EquipmentType
    @State private var sets: [AddExerciseView.SetInput]
    
    init(exercise: Exercise) {
        self.exercise = exercise
        _name = State(initialValue: exercise.name)
        _equipmentType = State(initialValue: exercise.equipmentType)
        _sets = State(initialValue: exercise.sets.map { set in
            AddExerciseView.SetInput(
                reps: set.reps,
                weightType: set.weightType,
                weightValue: set.weightValue ?? 0,
                barWeight: set.barWeight ?? 20
            )
        })
    }
    
    private func save() {
        exercise.name = name
        exercise.equipmentType = equipmentType
        
        // Delete removed sets
        let existingSets = Set(exercise.sets)
        let updatedSetCount = sets.count
        
        if updatedSetCount < existingSets.count {
            for set in existingSets.dropFirst(updatedSetCount) {
                modelContext.delete(set)
            }
        }
        
        // Update existing sets and add new ones
        for (index, setInput) in sets.enumerated() {
            if index < exercise.sets.count {
                // Update existing set
                let set = exercise.sets[index]
                set.reps = setInput.reps
                set.weightType = setInput.weightType
                set.weightValue = setInput.weightValue
                set.barWeight = setInput.weightType == .perSide ? setInput.barWeight : nil
            } else {
                // Add new set
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
        }
        
        try? modelContext.save()
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        dismiss()
    }
    
    var body: some View {
        ExerciseFormView(
            name: $name,
            equipmentType: $equipmentType,
            sets: $sets,
            saveTitle: "Save",
            onSave: { save() },
            onCancel: { dismiss() }
        )
    }
}

#Preview {
    let preview = PreviewContainer.container
    let workout = try! preview.mainContext.fetch(FetchDescriptor<Workout>(sortBy: [.init(\Workout.timestamp)])).first { $0.exercises.count > 0 }!
    
    return EditExerciseView(exercise: workout.exercises.first!)
        .modelContainer(preview)
}
