import SwiftUI

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: workout.type.iconName)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.displayName)
                    .font(.headline)
                
                if let duration = workout.duration {
                    Text("\(duration) minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let notes = workout.notes {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(workout.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
} 