import SwiftUI

struct ThreadEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "bubble.left.and.bubble.right.fill")
        } description: {
            Text(message)
        } actions: {
            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }
} 