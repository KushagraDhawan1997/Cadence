import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.timestamp, order: .reverse, animation: .default) private var workouts: [Workout]
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
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        withAnimation {
            modelContext.delete(workout)
            try? modelContext.save()
        }
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
                                    NavigationLink(value: workout) {
                                        WorkoutRow(workout: workout)
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        deleteWorkout(dayWorkouts[index])
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
            .navigationDestination(for: Workout.self) { workout in
                WorkoutDetailView(workout: workout)
            }
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
                            withAnimation {
                                isEditing.toggle()
                            }
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
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(PreviewContainer.container)
} 