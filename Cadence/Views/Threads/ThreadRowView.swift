import SwiftUI

struct ThreadRowView: View {
    let thread: ThreadModel
    let viewModel: AssistantViewModel
    @Binding var showError: Bool
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        NavigationLink {
            ChatView(thread: thread, viewModel: viewModel)
                .task {
                    do {
                        try await viewModel.selectThread(thread)
                    } catch {
                        showError = true
                    }
                }
        } label: {
            HStack(spacing: Constants.Layout.defaultPadding) {
                Circle()
                    .fill(Constants.Colors.assistantMessageBubble)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(Constants.Colors.textSecondary)
                    }
                
                VStack(alignment: .leading, spacing: Constants.Layout.smallPadding) {
                    Text("Thread \(String(thread.id.suffix(4)))")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textPrimary)
                    Text(formatDate(Date(timeIntervalSince1970: TimeInterval(thread.createdAt))))
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
                Spacer()
                
                Spacer()
            }
            .padding(.vertical, Constants.Layout.smallPadding)
            .contentShape(Rectangle())
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteThread(thread)
                    } catch {
                        showError = true
                    }
                }
            } label: {
                Label {
                    Text("Delete")
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
    }
} 