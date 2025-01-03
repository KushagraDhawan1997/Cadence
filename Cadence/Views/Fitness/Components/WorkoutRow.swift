import SwiftUI
import SwiftData

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            // Header
            HStack(spacing: Design.Spacing.md) {
                Image(systemName: workout.type.iconName)
                    .font(Design.Typography.title2())
                    .foregroundStyle(Design.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(Design.Colors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                    Text(workout.type.displayName)
                        .font(Design.Typography.headline())
                    
                    Text(workout.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(Design.Typography.subheadline())
                        .foregroundStyle(Design.Colors.secondary)
                }
            }
            
            // Metrics
            HStack(spacing: Design.Spacing.sm) {
                // Exercise Count
                Label("\(workout.exercises.count) exercises", systemImage: "dumbbell.fill")
                    .labelStyle(.titleAndIcon)
                
                if !workout.exercises.isEmpty {
                    Text("•")
                    
                    // Total Sets
                    Label("\(workout.exercises.reduce(0) { $0 + $1.sets.count }) sets", systemImage: "number")
                        .labelStyle(.titleAndIcon)
                }
                
                if let duration = workout.duration {
                    Text("•")
                    
                    // Duration
                    Label("\(duration)m", systemImage: "clock.fill")
                        .labelStyle(.titleAndIcon)
                }
            }
            .font(Design.Typography.subheadline())
            .foregroundStyle(Design.Colors.secondary)
            .symbolRenderingMode(.hierarchical)
        }
    }
}

struct WorkoutRowPreview: View {
    let container: ModelContainer
    let workout: Workout
    
    init() {
        container = PreviewContainer.container
        let context = container.mainContext
        
        workout = Workout(type: .chestTriceps)
        workout.duration = 45
        
        let exercise = Exercise(name: "Bench Press", equipmentType: .barbell, workout: workout)
        exercise.sets = [
            ExerciseSet(reps: 10, weightType: .perSide, weightValue: 20, barWeight: 20, exercise: exercise),
            ExerciseSet(reps: 8, weightType: .perSide, weightValue: 25, barWeight: 20, exercise: exercise)
        ]
        workout.exercises.append(exercise)
        
        context.insert(workout)
    }
    
    var body: some View {
        WorkoutRow(workout: workout)
            .padding()
            .background(Design.Colors.groupedBackground)
            .modelContainer(container)
    }
}

#Preview {
    WorkoutRowPreview()
} 
