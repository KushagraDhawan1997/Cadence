import SwiftUI

struct ExerciseHeader: View {
    let name: String
    let equipmentType: EquipmentType
    
    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            Image(systemName: equipmentType.iconName)
                .font(Design.Typography.title3())
                .foregroundStyle(Design.Colors.primary)
                .frame(width: 36, height: 36)
                .background(Design.Colors.primary.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: Design.Spacing.xxs) {
                Text(name)
                    .font(Design.Typography.headline())
                
                Text(equipmentType.displayName)
                    .font(Design.Typography.subheadline())
                    .foregroundStyle(Design.Colors.secondary)
            }
        }
    }
}

#Preview {
    ExerciseHeader(name: "Bench Press", equipmentType: .barbell)
        .padding()
        .background(Design.Colors.groupedBackground)
} 