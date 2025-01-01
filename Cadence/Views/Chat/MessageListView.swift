import SwiftUI

struct MessageListView: View {
    @ObservedObject var viewModel: AssistantViewModel
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        MessageView(message: message)
                            .id(message.id)
                            .transition(.opacity)
                    }
                    
                    if viewModel.isStreaming {
                        StreamingMessageView(response: viewModel.streamingResponse, viewModel: viewModel)
                            .id("streaming")
                            .transition(.opacity)
                    }
                }
                .onChange(of: viewModel.messages) { old, new in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: viewModel.streamingResponse) { old, new in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
        }
        .background(Constants.Colors.primaryBackground)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if viewModel.isStreaming {
            proxy.scrollTo("streaming", anchor: .bottom)
        } else if let lastId = viewModel.messages.last?.id {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
} 