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
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteWorkout(workout)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.visible)
    }
    
    private var createButton: some View {
        Button {
            Design.Haptics.light()
            showingCreateSheet = true
        } label: {
            Label("Create Workout", systemImage: "plus")
                .font(.body.weight(.medium))
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
                ToolbarItem(placement: .primaryAction) {
                    createButton
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                NavigationStack {
                    CreateWorkoutView(modelContext: modelContext)
                }
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
            .modelContainer(PreviewContainer.container)
    }
} 
