import SwiftUI
import SwiftData

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            // Header
            HStack(alignment: .center, spacing: Design.Spacing.md) {
                Image(systemName: workout.type.iconName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Design.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(Design.Colors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.type.displayName)
                        .font(.system(.body, design: .default))
                        .fontWeight(.medium)
                    
                    Text(workout.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.footnote))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Metrics
            HStack(spacing: Design.Spacing.lg) {
                Label {
                    Text("\(workout.exercises.count)")
                        .fontWeight(.medium)
                        .monospacedDigit() +
                    Text(" exercises")
                } icon: {
                    Image(systemName: "dumbbell.fill")
                        .frame(width: 20)
                }
                
                if let duration = workout.duration {
                    Label {
                        Text("\(duration)")
                            .fontWeight(.medium)
                            .monospacedDigit() +
                        Text("m")
                    } icon: {
                        Image(systemName: "clock.fill")
                            .frame(width: 20)
                    }
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.hierarchical)
            .padding(.leading, 52)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
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
        List {
            WorkoutRow(workout: workout)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.insetGrouped)
        .modelContainer(container)
    }
}

#Preview {
    WorkoutRowPreview()
} 
