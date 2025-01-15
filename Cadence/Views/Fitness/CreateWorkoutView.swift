import SwiftUI
import SwiftData

struct WorkoutTypeRow: View {
    let type: WorkoutType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(type.displayName)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

struct WorkoutTypeSelectionView: View {
    @Binding var selectedType: WorkoutType
    @Environment(\.dismiss) private var dismiss
    
    private func workoutTypesByCategory(_ category: WorkoutCategory) -> [WorkoutType] {
        WorkoutType.allCases.filter { $0.category == category }
    }
    
    var body: some View {
        List {
            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                Section(category.rawValue) {
                    ForEach(workoutTypesByCategory(category), id: \.self) { type in
                        WorkoutTypeRow(
                            type: type,
                            isSelected: type == selectedType
                        ) {
                            selectedType = type
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle("Workout Type")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreateWorkoutView: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: WorkoutType = .chestTriceps
    @State private var duration: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    WorkoutTypeSelectionView(selectedType: $selectedType)
                } label: {
                    HStack {
                        Text("Type")
                        Spacer()
                        Text(selectedType.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Workout Type")
            } footer: {
                Text(selectedType.category.rawValue)
                    .foregroundStyle(.secondary)
            }
            
            Section("Details") {
                HStack {
                    Text("Duration")
                    Spacer()
                    TextField("Minutes", text: $duration)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(1...5)
            }
        }
        .navigationTitle("New Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    let workout = Workout(
                        type: selectedType,
                        duration: Int(duration),
                        notes: notes.isEmpty ? nil : notes
                    )
                    modelContext.insert(workout)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateWorkoutView(modelContext: ModelContext(try! ModelContainer(for: Workout.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))))
    }
} 