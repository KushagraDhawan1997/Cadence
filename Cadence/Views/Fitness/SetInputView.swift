import SwiftUI

struct SetInputView: View {
    @Binding var set: AddExerciseView.SetInput
    let setNumber: Int
    let equipmentType: EquipmentType
    let onDelete: () -> Void
    let isDeleteEnabled: Bool
    
    init(set: Binding<AddExerciseView.SetInput>, 
         setNumber: Int,
         equipmentType: EquipmentType,
         onDelete: @escaping () -> Void,
         isDeleteEnabled: Bool) {
        self._set = set
        self.setNumber = setNumber
        self.equipmentType = equipmentType
        self.onDelete = onDelete
        self.isDeleteEnabled = isDeleteEnabled
        
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
        case .bodyweight:
            return .bodyweight
        case .machine, .cable:
            return .total
        }
    }
    
    private var weightLabel: String {
        switch equipmentType {
        case .barbell:
            return "PER SIDE"
        case .dumbbell:
            return "PER DUMBBELL"
        case .bodyweight:
            return "ADDED WEIGHT"
        case .machine, .cable:
            return "WEIGHT"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Left Side: Set Number & Reps
            HStack(spacing: 16) {
                // Set Number
                ZStack {
                    Circle()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text("\(setNumber)")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                // Reps Controls
                VStack(alignment: .leading, spacing: 4) {
                    Text("REPS")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        Button {
                            if set.reps > 1 {
                                set.reps -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.blue)
                                .imageScale(.large)
                        }
                        
                        Text("\(set.reps)")
                            .font(.title3)
                            .monospacedDigit()
                            .frame(minWidth: 24)
                        
                        Button {
                            set.reps += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                                .imageScale(.large)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Right Side: Weight Input
            VStack(alignment: .trailing, spacing: 8) {
                // Weight Value
                VStack(alignment: .trailing, spacing: 4) {
                    Text(weightLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(set.weightValue))")
                            .font(.title)
                            .monospacedDigit()
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Bar Weight (if applicable)
                if equipmentType == .barbell {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Bar:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(set.barWeight))")
                            .font(.callout)
                            .monospacedDigit()
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Total Weight
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Total:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(set.weightValue * 2 + set.barWeight))")
                            .font(.callout)
                            .monospacedDigit()
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if equipmentType == .dumbbell {
                    // Total Weight for dumbbells
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Total:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(set.weightValue * 2))")
                            .font(.callout)
                            .monospacedDigit()
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Delete Button
            if isDeleteEnabled {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .imageScale(.large)
                }
            }
        }
        .padding(.vertical, 8)
        .listRowSeparator(.visible)
        .listRowBackground(Color.clear)
    }
} 