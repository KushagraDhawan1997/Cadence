import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExercise = false
    @State private var isEditing = false
    
    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        try? modelContext.save()
    }
    
    var body: some View {
        List {
            // Empty section for spacing
            Section { }
            
            // Workout Info Section
            Section {
                // Timestamp
                LabeledContent {
                    Text(workout.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                } label: {
                    Text("Time")
                        .foregroundStyle(.secondary)
                }
                
                // Duration
                if let duration = workout.duration {
                    LabeledContent {
                        Text("\(duration) minutes")
                            .foregroundStyle(.secondary)
                    } label: {
                        Text("Duration")
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Notes
                if let notes = workout.notes {
                    LabeledContent {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    } label: {
                        Text("Notes")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Exercises Section
            Section {
                if workout.exercises.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("No Exercises")
                        } icon: {
                            Image(systemName: "dumbbell")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    } description: {
                        Text("Add your first exercise to this workout")
                    } actions: {
                        Button(action: { showingAddExercise = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.medium)
                                Text("Add Exercise")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ForEach(workout.exercises) { exercise in
                        ExerciseRow(exercise: exercise)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        deleteExercise(exercise)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                if !workout.exercises.isEmpty {
                    Text("Exercises")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(workout.type.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddExercise = true }) {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
            
            if !workout.exercises.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(workout: workout)
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    @State private var showingEditSheet = false
    
    var body: some View {
        Button {
            showingEditSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Exercise Header
                HStack(spacing: 12) {
                    Image(systemName: exercise.equipmentType.iconName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    
                    Text(exercise.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(exercise.equipmentType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Sets
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text("Set \(exercise.sets.firstIndex(of: set)! + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(width: 48, alignment: .leading)
                            
                            Spacer()
                            
                            if let weight = set.weightValue {
                                Group {
                                    switch set.weightType {
                                    case .perSide:
                                        if let barWeight = set.barWeight {
                                            Text("\(Int(weight))kg/side • \(Int(weight * 2 + barWeight))kg total")
                                        } else {
                                            Text("\(Int(weight))kg/side")
                                        }
                                    case .total:
                                        Text("\(Int(weight))kg")
                                    case .perDumbbell:
                                        Text("\(Int(weight))kg × 2")
                                    case .bodyweight:
                                        if weight > 0 {
                                            Text("+\(Int(weight))kg")
                                        }
                                    }
                                }
                                .foregroundStyle(.primary)
                                
                                Text("×")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 4)
                                
                                Text("\(set.reps)")
                                    .foregroundStyle(.primary)
                                    .contentTransition(.numericText())
                                
                                Text("reps")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                }
                .padding(.leading, 36)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditSheet) {
            EditExerciseView(exercise: exercise)
        }
    }
}

#Preview {
    let preview = PreviewContainer.container
    let workout = try! preview.mainContext.fetch(FetchDescriptor<Workout>(sortBy: [.init(\Workout.timestamp)])).first { $0.exercises.count > 0 }!
    
    return NavigationStack {
        WorkoutDetailView(workout: workout)
    }
    .modelContainer(preview)
} 