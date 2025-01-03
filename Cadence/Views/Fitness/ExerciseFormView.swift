import SwiftUI

struct ExerciseFormView: View {
    @Binding var name: String
    @Binding var equipmentType: EquipmentType
    @Binding var sets: [AddExerciseView.SetInput]
    @FocusState private var focusedField: Field?
    
    let saveTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    enum Field {
        case name
    }
    
    private func addSet() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
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
    
    var body: some View {
        NavigationStack {
            List {
                // Exercise Details Section
                Section {
                    // Exercise Name
                    TextField("Exercise Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .overlay(alignment: .trailing) {
                            if !name.isEmpty {
                                Button(action: { name = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .padding(.trailing, 4)
                            }
                        }
                    
                    // Equipment Type
                    Picker("Equipment", selection: $equipmentType) {
                        ForEach(EquipmentType.allCases, id: \.self) { type in
                            Label {
                                Text(type.displayName)
                            } icon: {
                                Image(systemName: type.iconName)
                                    .foregroundStyle(.tint)
                            }
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