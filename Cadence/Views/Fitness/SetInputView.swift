import SwiftUI

struct SetInputView: View {
    @Binding var set: AddExerciseView.SetInput
    let setNumber: Int
    let equipmentType: EquipmentType
    let onDelete: () -> Void
    
    @State private var showingRepsPicker = false
    @State private var showingWeightPicker = false
    @State private var showingBarWeightPicker = false
    
    init(set: Binding<AddExerciseView.SetInput>, 
         setNumber: Int,
         equipmentType: EquipmentType,
         onDelete: @escaping () -> Void) {
        self._set = set
        self.setNumber = setNumber
        self.equipmentType = equipmentType
        self.onDelete = onDelete
        
        // Update weight type based on equipment
        if set.wrappedValue.weightType == .perSide && equipmentType != .barbell {
            set.weightType.wrappedValue = defaultWeightType(for: equipmentType)
        }
    }
    
    private func defaultWeightType(for equipment: EquipmentType) -> WeightType {
        switch equipment {
        case .barbell:
            return .perSide
        case .dumbbell:
            return .perDumbbell
        case .cable, .machine:
            return .total
        case .bodyweight:
            return .bodyweight
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Number
            Text("Set \(setNumber)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // Reps
            Button {
                showingRepsPicker = true
            } label: {
                Text("\(set.reps)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .foregroundStyle(Design.Colors.primary)
                + Text(" reps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            // Weight
            Button {
                showingWeightPicker = true
            } label: {
                Group {
                    if set.weightType == .perSide {
                        Text("\(Int(set.weightValue))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .monospacedDigit()
                            .foregroundStyle(Design.Colors.primary)
                        + Text("/side")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(Int(set.weightValue))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .monospacedDigit()
                            .foregroundStyle(Design.Colors.primary)
                        + Text("kg")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle()) // This ensures taps only work on visible elements
        .sheet(isPresented: $showingRepsPicker) {
            NavigationStack {
                Picker("Reps", selection: $set.reps) {
                    ForEach(1...50, id: \.self) { reps in
                        Text("\(reps)")
                            .tag(reps)
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("Reps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingRepsPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(240)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingWeightPicker) {
            NavigationStack {
                VStack {
                    Picker("Weight", selection: $set.weightValue) {
                        ForEach(0...200, id: \.self) { weight in
                            Text("\(weight)")
                                .tag(Double(weight))
                        }
                    }
                    .pickerStyle(.wheel)
                    
                    if set.weightType == .perSide {
                        Button("Set Bar Weight (\(Int(set.barWeight))kg)") {
                            showingBarWeightPicker = true
                        }
                        .padding(.top)
                    }
                }
                .navigationTitle("Weight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingWeightPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingBarWeightPicker) {
            NavigationStack {
                Picker("Bar Weight", selection: $set.barWeight) {
                    ForEach([10, 15, 20, 25], id: \.self) { weight in
                        Text("\(weight)kg")
                            .tag(Double(weight))
                    }
                }
                .pickerStyle(.wheel)
                .navigationTitle("Bar Weight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingBarWeightPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.height(240)])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    @State var set = AddExerciseView.SetInput()
    
    return SetInputView(
        set: $set,
        setNumber: 1,
        equipmentType: .barbell,
        onDelete: {}
    )
    .padding()
    .modelContainer(PreviewContainer.container)
} 