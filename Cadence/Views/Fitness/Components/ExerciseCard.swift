import SwiftUI
import SwiftData

struct ExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingEditSheet = false
    
    var body: some View {
        Button {
            onTap()
            showingEditSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                // Exercise Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(exercise.equipmentType.displayName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                if !exercise.sets.isEmpty {
                    // Sets
                    VStack(spacing: 0) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                            if index > 0 {
                                Divider()
                                    .padding(.vertical, 8)
                            }
                            
                            HStack {
                                Text("Set \(index + 1)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(set.reps) reps")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .monospacedDigit()
                                
                                if let weightStr = formatWeight(for: set) {
                                    Text("·")
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 4)
                                    
                                    Text(weightStr)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Design.Colors.primary)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
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
    let container = PreviewContainer.container
    let context = container.mainContext
    
    let exercise = Exercise(name: "Bench Press", equipmentType: .barbell)
    exercise.sets = [
        ExerciseSet(reps: 10, weightType: .perSide, weightValue: 20, barWeight: 20, exercise: exercise),
        ExerciseSet(reps: 8, weightType: .perSide, weightValue: 25, barWeight: 20, exercise: exercise),
        ExerciseSet(reps: 6, weightType: .perSide, weightValue: 30, barWeight: 20, exercise: exercise)
    ]
    
    context.insert(exercise)
    
    return ExerciseCard(exercise: exercise, onTap: {}, onDelete: {})
        .padding()
        .background(Color(.systemGroupedBackground))
        .modelContainer(container)
} 

