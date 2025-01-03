import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(sort: \Workout.timestamp, order: .reverse) private var workouts: [Workout]
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    
    private func deleteWorkout(_ workout: Workout) {
        Design.Haptics.heavy()
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(workout)
            try? modelContext.save()
        }
    }
    
    private var workoutList: some View {
        List {
            ForEach(workouts) { workout in
                NavigationLink {
                    WorkoutDetailView(workout: workout)
                } label: {
                    WorkoutRow(workout: workout)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteWorkout(workout)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var createButton: some View {
        Button {
            Design.Haptics.light()
            showingCreateSheet = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(Design.Typography.title3())
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    EmptyWorkoutList {
                        showingCreateSheet = true
                    }
                } else {
                    workoutList
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    createButton
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
    WorkoutHistoryView()
        .modelContainer(PreviewContainer.container)
} 