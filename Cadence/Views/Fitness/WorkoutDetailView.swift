import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddExercise = false
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    private func deleteExercise(_ exercise: Exercise) {
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(exercise)
            try? modelContext.save()
        }
    }
    
    private func deleteWorkout() {
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        modelContext.delete(workout)
        try? modelContext.save()
    }
    
    var body: some View {
        List {
            // Details Section
            Section {
                // Workout Type
                HStack {
                    Image(systemName: workout.type.iconName)
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.type.displayName)
                            .font(.headline)
                        
                        Text(workout.type.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let duration = workout.duration {
                    Label("\(duration) minutes", systemImage: "clock")
                }
                
                if let notes = workout.notes {
                    Label(notes, systemImage: "note.text")
                }
            } header: {
                Text("DETAILS")
                    .fontWeight(.medium)
            }
            
            // Exercises Section
            Section {
                if workout.exercises.isEmpty {
                    Button(action: { showingAddExercise = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.medium)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)
                            Text("Add Exercise")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(workout.exercises) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            deleteExercise(workout.exercises[index])
                        }
                    }
                    
                    Button(action: { showingAddExercise = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.medium)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)
                            Text("Add Exercise")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("EXERCISES (\(workout.exercises.count))")
                    .fontWeight(.medium)
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !workout.exercises.isEmpty {
                        Button(action: { isEditing.toggle() }) {
                            Label(isEditing ? "Done" : "Edit Exercises", 
                                  systemImage: isEditing ? "checkmark" : "pencil")
                        }
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            NavigationStack {
                AddExerciseView(workout: workout)
            }
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    @State private var showingEditSheet = false
    
    var body: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .soft)
            impact.impactOccurred()
            showingEditSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Exercise Header
                HStack(spacing: 12) {
                    Image(systemName: exercise.equipmentType.iconName)
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                    
                    Text(exercise.name)
                        .font(.headline)
                }
                
                // Sets Summary
                if !exercise.sets.isEmpty {
                    HStack(spacing: 4) {
                        Label("\(exercise.sets.count) sets", systemImage: "number")
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Label("\(exercise.sets[0].reps) reps", systemImage: "repeat")
                            .foregroundStyle(.secondary)
                        
                        if let weightStr = formatWeight(for: exercise.sets[0]) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Label(weightStr, systemImage: "scalemass")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                    .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EditExerciseView(exercise: exercise)
            }
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
    let preview = PreviewContainer.container
    let workout = try! preview.mainContext.fetch(FetchDescriptor<Workout>(sortBy: [.init(\Workout.timestamp)])).first { $0.exercises.count > 0 }!
    
    return NavigationStack {
        WorkoutDetailView(workout: workout)
    }
    .modelContainer(preview)
} 