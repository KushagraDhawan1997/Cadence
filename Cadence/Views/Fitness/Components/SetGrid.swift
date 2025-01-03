import SwiftUI

struct SetGrid: View {
    let sets: [ExerciseSet]
    
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            // Sets Header
            Text("SETS")
                .font(Design.Typography.caption())
                .foregroundStyle(Design.Colors.secondary)
            
            // Sets Grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Design.Spacing.sm), count: 3),
                spacing: Design.Spacing.sm
            ) {
                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    VStack(spacing: Design.Spacing.xxs) {
                        Text("Set \(index + 1)")
                            .font(Design.Typography.caption())
                            .foregroundStyle(Design.Colors.secondary)
                        
                        Text("\(set.reps)")
                            .font(Design.Typography.title3())
                            .monospacedDigit()
                        
                        if let weightStr = formatWeight(for: set) {
                            Text(weightStr)
                                .font(Design.Typography.caption())
                                .foregroundStyle(Design.Colors.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Design.Spacing.xs)
                    .background(Design.Colors.secondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

#Preview {
    let exercise = Exercise(name: "Bench Press", equipmentType: .barbell)
    let sets = [
        ExerciseSet(reps: 10, weightType: .perSide, weightValue: 20, barWeight: 20, exercise: exercise),
        ExerciseSet(reps: 8, weightType: .perSide, weightValue: 25, barWeight: 20, exercise: exercise),
        ExerciseSet(reps: 6, weightType: .perSide, weightValue: 30, barWeight: 20, exercise: exercise)
    ]
    
    return SetGrid(sets: sets)
        .padding()
        .background(Design.Colors.groupedBackground)
        .modelContainer(for: [Exercise.self, ExerciseSet.self])
} 