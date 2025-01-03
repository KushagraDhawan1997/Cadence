import SwiftUI

struct SetInputView: View {
    @Binding var set: AddExerciseView.SetInput
    let setNumber: Int
    let equipmentType: EquipmentType
    let onDelete: () -> Void
    let isDeleteEnabled: Bool
    
    @State private var showingRepsPicker = false
    @State private var showingWeightPicker = false
    @State private var showingBarWeightPicker = false
    
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
        HStack(alignment: .center, spacing: 16) {
            // Set Number
            Text("\(setNumber)")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            // Reps Section
            VStack(alignment: .leading, spacing: 4) {
                Text("REPS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button {
                    showingRepsPicker = true
                } label: {
                    Text("\(set.reps)")
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(.primary)
                        .frame(minWidth: 32, alignment: .leading)
                        .contentTransition(.numericText())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Weight Section
            VStack(alignment: .trailing, spacing: 4) {
                Text(weightLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button {
                    showingWeightPicker = true
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(set.weightValue))")
                            .font(.title3.monospacedDigit().weight(.medium))
                            .contentTransition(.numericText())
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                if equipmentType == .barbell {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Bar:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            showingBarWeightPicker = true
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(Int(set.barWeight))")
                                    .font(.subheadline.monospacedDigit())
                                    .contentTransition(.numericText())
                                
                                Text("kg")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Total:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(set.weightValue * 2 + set.barWeight))")
                            .font(.subheadline.monospacedDigit())
                            .contentTransition(.numericText())
                        
                        Text("kg")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Delete Button
            if isDeleteEnabled {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                    impact.impactOccurred()
                    onDelete()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                        .imageScale(.large)
                }
            }
        }
        .padding(.vertical, 12)
        .sheet(isPresented: $showingRepsPicker) {
            NavigationStack {
                Picker("Reps", selection: $set.reps) {
                    ForEach(1...100, id: \.self) { value in
                        Text("\(value)")
                            .tag(value)
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
            .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $showingWeightPicker) {
            NavigationStack {
                WeightPicker(weight: $set.weightValue)
                    .navigationTitle(weightLabel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingWeightPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $showingBarWeightPicker) {
            NavigationStack {
                WeightPicker(weight: $set.barWeight, range: 0...50, step: 2.5)
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
            .presentationDetents([.height(260)])
        }
    }
}

struct WeightPicker: View {
    @Binding var weight: Double
    var range: ClosedRange<Double> = 0...1000
    var step: Double = 2.5
    
    private var wholeNumbers: [Int] {
        Array(stride(from: Int(range.lowerBound), through: Int(range.upperBound), by: 1))
    }
    
    private var decimalPart: Double {
        weight.truncatingRemainder(dividingBy: 1)
    }
    
    @State private var wholeNumber: Int = 0
    @State private var decimal: Double = 0
    
    init(weight: Binding<Double>, range: ClosedRange<Double> = 0...1000, step: Double = 2.5) {
        self._weight = weight
        self.range = range
        self.step = step
        
        // Initialize state
        let initialWeight = weight.wrappedValue
        _wholeNumber = State(initialValue: Int(initialWeight))
        _decimal = State(initialValue: initialWeight.truncatingRemainder(dividingBy: 1))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("Whole", selection: $wholeNumber) {
                ForEach(wholeNumbers, id: \.self) { number in
                    Text("\(number)")
                        .tag(number)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: wholeNumber) { _ in
                weight = Double(wholeNumber) + decimal
            }
            
            if step < 1 {
                Picker("Decimal", selection: $decimal) {
                    ForEach([0.0, 0.5], id: \.self) { decimal in
                        Text(String(format: "%.1f", decimal))
                            .tag(decimal)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .onChange(of: decimal) { _ in
                    weight = Double(wholeNumber) + decimal
                }
            }
        }
        .onAppear {
            wholeNumber = Int(weight)
            decimal = weight.truncatingRemainder(dividingBy: 1)
        }
    }
} 