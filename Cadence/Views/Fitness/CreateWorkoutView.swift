import SwiftUI
import SwiftData

struct CreateWorkoutView: View {
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: WorkoutType = .upperBody
    @State private var duration: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    List {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                                dismiss()
                            } label: {
                                HStack {
                                    Label(type.displayName, systemImage: type.iconName)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if type == selectedType {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Workout Type")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Type")
                        Spacer()
                        Label(selectedType.displayName, systemImage: selectedType.iconName)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Workout Type")
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