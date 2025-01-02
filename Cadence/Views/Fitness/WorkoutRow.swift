import SwiftUI

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: workout.type.iconName)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.tint)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.displayName)
                    .font(.headline)
                
                Group {
                    if !workout.exercises.isEmpty {
                        Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                    }
                    if let duration = workout.duration {
                        Text("\(duration) minutes")
                    }
                    if let notes = workout.notes {
                        Text(notes)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(workout.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
} 