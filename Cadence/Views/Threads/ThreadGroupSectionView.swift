import SwiftUI

struct ThreadGroupSectionView: View {
    let group: AssistantViewModel.GroupedThreads
    let viewModel: AssistantViewModel
    @Binding var showError: Bool
    
    var body: some View {
        Section {
            ForEach(group.threads) { thread in
                ThreadRowView(thread: thread, viewModel: viewModel, showError: $showError)
                    .transition(.opacity.combined(with: .slide))
            }
        } header: {
            ThreadGroupHeaderView(group: group)
        }
    }
} 