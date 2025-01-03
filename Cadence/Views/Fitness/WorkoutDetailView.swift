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
        ScrollView {
            VStack(spacing: Design.Spacing.xl) {
                // Header Card
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Type & Category
                    HStack(alignment: .top) {
                        Image(systemName: workout.type.iconName)
                            .font(Design.Typography.title())
                            .foregroundStyle(Design.Colors.primary)
                            .frame(width: 56, height: 56)
                            .background(Design.Colors.primary.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                            Text(workout.type.displayName)
                                .font(Design.Typography.title2())
                            
                            Text(workout.type.category.rawValue)
                                .font(Design.Typography.subheadline())
                                .foregroundStyle(Design.Colors.secondary)
                        }
                        
                        Spacer()
                        
                        Text(workout.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(Design.Typography.subheadline())
                            .foregroundStyle(Design.Colors.secondary)
                    }
                    
                    // Metrics
                    HStack(spacing: Design.Spacing.md) {
                        // Exercise Count
                        VStack(spacing: Design.Spacing.xxs) {
                            Image(systemName: "dumbbell.fill")
                                .font(Design.Typography.title2())
                                .foregroundStyle(Design.Colors.primary)
                            
                            Text("\(workout.exercises.count)")
                                .font(Design.Typography.title())
                                .fontWeight(.semibold)
                                .foregroundStyle(Design.Colors.primary)
                                .monospacedDigit()
                            
                            Text("EXERCISES")
                                .font(Design.Typography.caption())
                                .foregroundStyle(Design.Colors.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Total Sets
                        VStack(spacing: Design.Spacing.xxs) {
                            Image(systemName: "number")
                                .font(Design.Typography.title2())
                                .foregroundStyle(Design.Colors.primary)
                            
                            Text("\(workout.exercises.reduce(0) { $0 + $1.sets.count })")
                                .font(Design.Typography.title())
                                .fontWeight(.semibold)
                                .foregroundStyle(Design.Colors.primary)
                                .monospacedDigit()
                            
                            Text("TOTAL SETS")
                                .font(Design.Typography.caption())
                                .foregroundStyle(Design.Colors.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Duration
                        if let duration = workout.duration {
                            VStack(spacing: Design.Spacing.xxs) {
                                Image(systemName: "clock.fill")
                                    .font(Design.Typography.title2())
                                    .foregroundStyle(Design.Colors.primary)
                                
                                Text("\(duration)")
                                    .font(Design.Typography.title())
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Design.Colors.primary)
                                    .monospacedDigit()
                                
                                Text("DURATION")
                                    .font(Design.Typography.caption())
                                    .foregroundStyle(Design.Colors.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .symbolRenderingMode(.hierarchical)
                    
                    if let notes = workout.notes {
                        Text(notes)
                            .font(Design.Typography.callout())
                            .foregroundStyle(Design.Colors.secondary)
                    }
                }
                .padding(Design.Spacing.lg)
                .glassBackground()
                
                // Exercises Section
                VStack(alignment: .leading, spacing: Design.Spacing.lg) {
                    // Section Header
                    HStack {
                        Text("Exercises")
                            .font(Design.Typography.title3())
                        
                        Spacer()
                        
                        Button(action: { 
                            Design.Haptics.light()
                            showingAddExercise = true 
                        }) {
                            Label("Add Exercise", systemImage: "plus")
                                .font(Design.Typography.body())
                                .foregroundStyle(Design.Colors.primary)
                        }
                    }
                    .padding(.horizontal, Design.Spacing.lg)
                    
                    if workout.exercises.isEmpty {
                        // Empty State
                        VStack(spacing: Design.Spacing.md) {
                            Text("No exercises yet")
                                .font(Design.Typography.headline())
                                .foregroundStyle(Design.Colors.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Design.Spacing.lg)
                    } else {
                        // Exercise List
                        LazyVStack(spacing: Design.Spacing.md) {
                            ForEach(workout.exercises) { exercise in
                                ExerciseCard(exercise: exercise) {
                                    Design.Haptics.light()
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteExercise(exercise)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Design.Spacing.lg)
                    }
                }
            }
            .padding(.vertical, Design.Spacing.lg)
        }
        .background(Design.Colors.groupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Workout", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(Design.Typography.title3())
                        .symbolRenderingMode(.hierarchical)
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