import SwiftUI

struct ExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        Button {
            onTap()
            showingEditSheet = true
        } label: {
            VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                ExerciseHeader(name: exercise.name, equipmentType: exercise.equipmentType)
                
                if !exercise.sets.isEmpty {
                    SetGrid(sets: exercise.sets)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Design.Spacing.lg)
            .glassBackground()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditExerciseView(exercise: exercise)
            }
        }
    }
}

#Preview {
    let exercise = Exercise(name: "Bench Press", equipmentType: .barbell)
    exercise.sets = [
        ExerciseSet(reps: 10, weightType: .perSide, weightValue: 20, barWeight: 20, exercise: exercise),
        ExerciseSet(reps: 8, weightType: .perSide, weightValue: 25, barWeight: 20, exercise: exercise),
        ExerciseSet(reps: 6, weightType: .perSide, weightValue: 30, barWeight: 20, exercise: exercise)
    ]
    
    return ExerciseCard(exercise: exercise) {}
        .padding()
        .background(Design.Colors.groupedBackground)
        .modelContainer(for: [Exercise.self, ExerciseSet.self])
} 