import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.timestamp, order: .reverse) private var workouts: [Workout]
    @State private var selectedType: WorkoutType?
    @State private var isEditing = false
    
    private var filteredWorkouts: [Workout] {
        guard let selectedType else { return workouts }
        return workouts.filter { workout in
            workout.type == selectedType
        }
    }
    
    private var groupedWorkouts: [(String, [Workout])] {
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            Calendar.current.startOfDay(for: workout.timestamp)
        }
        return grouped.map { (date, workouts) in
            (date.formatted(date: .abbreviated, time: .omitted), workouts)
        }.sorted { $0.0 > $1.0 }
    }
    
    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        try? modelContext.save()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredWorkouts.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text(selectedType == nil ? "No Workouts" : "No \(selectedType!.displayName) Workouts")
                        } icon: {
                            Image(systemName: selectedType?.iconName ?? "figure.run")
                        }
                    } description: {
                        Text(selectedType == nil ? 
                            "Start a chat to log your first workout" :
                            "Try a different workout type or clear the filter")
                    }
                } else {
                    List {
                        ForEach(groupedWorkouts, id: \.0) { date, dayWorkouts in
                            Section(date) {
                                ForEach(dayWorkouts) { workout in
                                    WorkoutRow(workout: workout)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                deleteWorkout(workout)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .navigationTitle(selectedType == nil ? "Workout History" : "Workout History • \(selectedType!.displayName)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { selectedType = nil }) {
                            HStack {
                                Text("All Workouts")
                                if selectedType == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Button(action: { selectedType = type }) {
                                HStack {
                                    Label(type.displayName, systemImage: type.iconName)
                                    if selectedType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                if !filteredWorkouts.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(isEditing ? "Done" : "Edit") {
                            isEditing.toggle()
                        }
                    }
                }
            }
        }
    }
}

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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    
    // Add sample workouts
    let workout1 = Workout(type: .upperBody, duration: 45, notes: "Great arm day!")
    let workout2 = Workout(type: .cardio, duration: 30, notes: "Morning run")
    let workout3 = Workout(type: .lowerBody, duration: 60, notes: "Leg day!")
    
    workout1.timestamp = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    workout2.timestamp = Calendar.current.date(byAdding: .hour, value: -3, to: Date())!
    
    container.mainContext.insert(workout1)
    container.mainContext.insert(workout2)
    container.mainContext.insert(workout3)
    
    return NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(container)
} 