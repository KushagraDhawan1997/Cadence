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
            VStack(spacing: 0) {
                // Exercise Name & Equipment
                List {
                    Section {
                        TextField("Exercise Name", text: $name)
                            .font(.title3)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .name)
                            .listRowBackground(Color.clear)
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
                        .pickerStyle(.navigationLink)
                    }
                }
                .listStyle(.insetGrouped)
                
                // Sets
                VStack(alignment: .leading, spacing: 0) {
                    Text("SETS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
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
                                .transition(.scale.combined(with: .opacity))
                                .padding(.horizontal, 20)
                                
                                if index < sets.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 20)
                                }
                            }
                            
                            Button(action: addSet) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .imageScale(.medium)
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Add Set")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 20)
                        }
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
                .background(.secondary.opacity(0.1))
            }
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