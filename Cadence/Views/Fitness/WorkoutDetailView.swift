import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddExercise = false
    @State private var showingDeleteAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
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
        ScrollView {
            VStack(spacing: 24) {
                // Hero Image
                // Image("workout_background")
                //     .resizable()
                //     .aspectRatio(contentMode: .fit)
                //     .frame(maxWidth: 280)
                //     .clipShape(RoundedRectangle(cornerRadius: 12))
                //     .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 8)
                //     .padding(.horizontal)
                //     .padding(.top, 8)
                
                // Workout Info
                VStack(spacing: 20) {
                    // Title and Category
                    VStack(spacing: 4) {
                        Text(workout.type.displayName)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text(workout.type.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
                        Text(workout.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.top, 16)
                    
                    // Metrics
                    HStack(spacing: 32) {
                        // Exercise Count
                        VStack(spacing: 4) {
                            Text("\(workout.exercises.count)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Design.Colors.primary)
                            Text("Exercises")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Total Sets
                        VStack(spacing: 4) {
                            Text("\(workout.exercises.reduce(0) { $0 + $1.sets.count })")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Design.Colors.primary)
                            Text("Total Sets")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let duration = workout.duration {
                            VStack(spacing: 4) {
                                Text("\(duration)m")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Design.Colors.primary)
                                Text("Duration")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                Button {
                    Design.Haptics.light()
                    showingAddExercise = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.medium)
                        Text("Add Exercise")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Design.Colors.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                
                // Exercises List
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("EXERCISES")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    
                    if workout.exercises.isEmpty {
                        ContentUnavailableView {
                            Text("No Exercises")
                                .font(.title3)
                        } description: {
                            Text("Add exercises to your workout")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 48)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(workout.exercises) { exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    onTap: { Design.Haptics.light() },
                                    onDelete: {
                                        deleteExercise(exercise)
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .background(Color(colorScheme == .dark ? .black : .white))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .imageScale(.large)
                        .fontWeight(.semibold)
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
    let container = PreviewContainer.container
    let workout = try! container.mainContext.fetch(FetchDescriptor<Workout>(sortBy: [.init(\Workout.timestamp)])).first { $0.exercises.count > 0 }!
    
    return NavigationStack {
        WorkoutDetailView(workout: workout)
            .modelContainer(container)
    }
} 
