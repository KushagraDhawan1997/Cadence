import SwiftUI

struct EmptyWorkoutList: View {
    let action: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("No Workouts", systemImage: "dumbbell.fill")
        } description: {
            Text("Your workout history will appear here.")
        } actions: {
            Button {
                Design.Haptics.light()
                action()
            } label: {
                Label("Create Workout", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    EmptyWorkoutList {}
        .background(Design.Colors.groupedBackground)
} 