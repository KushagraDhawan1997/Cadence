import SwiftUI

struct ThreadGroupHeaderView: View {
    let group: AssistantViewModel.GroupedThreads
    
    var body: some View {
        HStack {
            Text(group.title)
                .font(.headline)
                .foregroundStyle(Constants.Colors.textPrimary)
            Spacer()
            Text("\(group.count)")
                .font(.subheadline)
                .foregroundStyle(Constants.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Constants.Colors.secondaryBackground)
                .clipShape(Capsule())
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }
} 