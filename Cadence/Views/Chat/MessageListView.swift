import SwiftUI

struct MessageListView: View {
    let messages: [MessageResponse]
    @ObservedObject var viewModel: AssistantViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(messages) { message in
                    MessageView(message: message)
                }
                
                if viewModel.isStreaming {
                    StreamingMessageView(
                        response: viewModel.streamingResponse,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.vertical, Constants.Layout.smallPadding)
        }
    }
} 