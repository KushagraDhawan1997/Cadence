import SwiftUI

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: workout.type.iconName)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(workout.type.displayName)
                    .font(.headline)
                
                // Subtitle
                HStack(spacing: 4) {
                    if !workout.exercises.isEmpty {
                        Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Time
            Text(workout.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
} 