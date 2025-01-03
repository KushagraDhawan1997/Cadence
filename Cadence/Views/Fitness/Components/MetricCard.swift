import SwiftUI

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            // Icon & Title
            Label {
                Text(title)
                    .font(Design.Typography.caption())
                    .foregroundStyle(Design.Colors.secondary)
            } icon: {
                Image(systemName: icon)
                    .font(Design.Typography.caption())
                    .foregroundStyle(Design.Colors.primary)
            }
            
            // Value
            Text(value)
                .font(Design.Typography.title2(weight: .semibold))
                .foregroundStyle(Design.Colors.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Design.Spacing.md)
        .glassBackground()
    }
}

#Preview {
    HStack {
        MetricCard(icon: "dumbbell.fill", title: "EXERCISES", value: "8")
        MetricCard(icon: "number", title: "TOTAL SETS", value: "24")
        MetricCard(icon: "clock.fill", title: "DURATION", value: "45m")
    }
    .padding()
    .background(Design.Colors.groupedBackground)
} 
