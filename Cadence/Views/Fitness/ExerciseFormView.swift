import SwiftUI

struct ExerciseFormView: View {
    @Binding var name: String
    @Binding var equipmentType: EquipmentType
    @Binding var sets: [AddExerciseView.SetInput]
    @FocusState private var focusedField: Field?
    
    // Add state for suggestions
    @State private var suggestions: [ExerciseLibrary.Exercise] = []
    @State private var showSuggestions = false
    @State private var isValidExercise = false
    
    let saveTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    enum Field {
        case name
    }
    
    private func addSet() {
        Design.Haptics.light()
        
        if let lastSet = sets.last {
            withAnimation(.spring(response: 0.3)) {
                sets.append(AddExerciseView.SetInput(
                    reps: lastSet.reps,
                    weightType: lastSet.weightType,
                    weightValue: lastSet.weightValue,
                    barWeight: lastSet.barWeight
                ))
            }
        }
    }
    
    private func updateSuggestions() {
        guard !name.isEmpty else {
            suggestions = []
            showSuggestions = false
            return
        }
        
        // Filter exercises that match the input
        suggestions = ExerciseLibrary.exercises.filter { exercise in
            exercise.primaryName.lowercased().contains(name.lowercased()) ||
            exercise.variations.contains { $0.lowercased().contains(name.lowercased()) }
        }
        showSuggestions = !suggestions.isEmpty
        
        // Check if current name exactly matches any exercise
        isValidExercise = ExerciseLibrary.findExercise(named: name) != nil
    }
    
    private func selectExercise(_ exercise: ExerciseLibrary.Exercise) {
        name = exercise.primaryName
        showSuggestions = false
        isValidExercise = true
        Design.Haptics.light()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Exercise Details Section
                Section {
                    // Exercise Name
                    TextField("Exercise Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .onChange(of: name) { updateSuggestions() }
                        .overlay(alignment: .trailing) {
                            if !name.isEmpty {
                                HStack {
                                    if isValidExercise {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                    Button(action: { 
                                        name = "" 
                                        updateSuggestions()
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.trailing, 4)
                            }
                        }
                    
                    if showSuggestions {
                        ForEach(suggestions, id: \.primaryName) { exercise in
                            Button(action: { selectExercise(exercise) }) {
                                VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                                    Text(exercise.primaryName)
                                        .font(Design.Typography.body())
                                    
                                    HStack(spacing: Design.Spacing.xs) {
                                        Text(exercise.category.rawValue)
                                            .font(Design.Typography.caption())
                                            .foregroundStyle(Design.Colors.secondary)
                                        
                                        if exercise.isCompound {
                                            Text("Compound")
                                                .font(Design.Typography.caption())
                                                .foregroundStyle(Design.Colors.secondary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Equipment Type
                    Picker("Equipment", selection: $equipmentType) {
                        ForEach(EquipmentType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("DETAILS")
                        .fontWeight(.medium)
                }
                
                // Sets Section
                Section {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, _ in
                        SetInputView(
                            set: $sets[index],
                            setNumber: index + 1,
                            equipmentType: equipmentType,
                            onDelete: {
                                withAnimation(.spring(response: 0.3)) {
                                    sets.remove(at: index)
                                }
                                let impact = UIImpactFeedbackGenerator(style: .rigid)
                                impact.impactOccurred()
                            },
                            isDeleteEnabled: sets.count > 1
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color(.systemBackground))
                    }
                    
                    Button(action: addSet) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.medium)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.blue)
                            Text("Add Set")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    Text("SETS (\(sets.count))")
                        .fontWeight(.medium)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(name.isEmpty ? "New Exercise" : name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveTitle, action: onSave)
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                focusedField = .name
            }
        }
    }
} 