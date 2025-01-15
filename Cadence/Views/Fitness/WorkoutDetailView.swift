import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddExercise = false
    @State private var showingDeleteAlert = false
    
    private func deleteExercise(_ exercise: Exercise) {
        Design.Haptics.heavy()
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(exercise)
            try? modelContext.save()
        }
    }
    
    private func deleteWorkout() {
        Design.Haptics.heavy()
        modelContext.delete(workout)
        try? modelContext.save()
        dismiss()
    }
    
    var body: some View {
        List {
            // Info Section
            Section {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(workout.type.category.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 12)
                
                // Metrics
                HStack {
                    // Exercise Count
                    VStack {
                        Text("\(workout.exercises.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Design.Colors.primary)
                        Text("Exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Total Sets
                    VStack {
                        Text("\(workout.exercises.reduce(0) { $0 + $1.sets.count })")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Design.Colors.primary)
                        Text("Total Sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    if let duration = workout.duration {
                        // Duration
                        VStack {
                            Text("\(duration)m")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Design.Colors.primary)
                            Text("Duration")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 12)
            } footer: {
                Text(workout.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }
            
            // Exercises Section
            Section {
                if workout.exercises.isEmpty {
                    ContentUnavailableView {
                        Text("No Exercises")
                            .font(.title3)
                    } description: {
                        Text("Add exercises to your workout")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .listRowInsets(EdgeInsets(top: 48, leading: 16, bottom: 48, trailing: 16))
                } else {
                    ForEach(workout.exercises) { exercise in
                        ExerciseCard(exercise: exercise) {
                            Design.Haptics.light()
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteExercise(exercise)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Exercises")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        Design.Haptics.light()
                        showingAddExercise = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Design.Colors.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            NavigationStack {
                AddExerciseView(workout: workout)
            }
            .presentationDragIndicator(.visible)
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
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
