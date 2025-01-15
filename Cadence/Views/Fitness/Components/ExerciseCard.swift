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
            VStack(alignment: .leading, spacing: Design.Spacing.md) {
                // Exercise Header
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                    
                    Text(exercise.equipmentType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !exercise.sets.isEmpty {
                    Divider()
                        .padding(.vertical, 2)
                    
                    // Sets
                    VStack(spacing: 0) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            if index > 0 {
                                Divider()
                            }
                            
                            HStack {
                                Text("Set \(index + 1)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(set.reps) reps")
                                    .font(.subheadline)
                                    .monospacedDigit()
                                
                                if let weightStr = formatWeight(for: set) {
                                    Text("·")
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    Text(weightStr)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .padding(Design.Spacing.lg)
        }
        .buttonStyle(.plain)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditExerciseView(exercise: exercise)
            }
            .presentationDragIndicator(.visible)
        }
    }
    
    private func formatWeight(for set: ExerciseSet) -> String? {
        guard let weight = set.weightValue else { return nil }
        
        switch set.weightType {
        case .perSide:
            if let barWeight = set.barWeight {
                return "\(Int(weight * 2 + barWeight))kg"
            } else {
                return "\(Int(weight))kg/side"
            }
        case .total:
            return "\(Int(weight))kg"
        case .perDumbbell:
            return "\(Int(weight))kg × 2"
        case .bodyweight:
            return weight > 0 ? "+\(Int(weight))kg" : nil
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
        .background(Color(.systemGroupedBackground))
} 

