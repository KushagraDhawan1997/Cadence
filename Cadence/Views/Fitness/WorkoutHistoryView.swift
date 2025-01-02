import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.timestamp, order: .reverse) private var workouts: [Workout]
    @State private var selectedType: WorkoutType?
    @State private var isEditing = false
    @State private var showingCreateSheet = false
    
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
    
    private func workoutTypesByCategory(_ category: WorkoutCategory) -> [WorkoutType] {
        WorkoutType.allCases.filter { $0.category == category }
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
                    } actions: {
                        Button(action: { showingCreateSheet = true }) {
                            Label("New Workout", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
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
                        
                        ForEach(WorkoutCategory.allCases, id: \.self) { category in
                            Menu {
                                ForEach(workoutTypesByCategory(category), id: \.self) { type in
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
                                Label(category.rawValue, systemImage: category.iconName)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Label("New Workout", systemImage: "plus")
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
            .sheet(isPresented: $showingCreateSheet) {
                NavigationStack {
                    CreateWorkoutView(modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Workout.self, configurations: config)
    
    // Add sample workouts
    let workout1 = Workout(type: .chestTriceps, duration: 45, notes: "Great chest day!")
    let workout2 = Workout(type: .cardio, duration: 30, notes: "Morning run")
    let workout3 = Workout(type: .hamstringsGlutes, duration: 60, notes: "Leg day!")
    
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