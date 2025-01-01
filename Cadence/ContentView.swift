//
//  ContentView.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI

protocol MessageBubbleShape: Shape {}

struct ContentView: View {
    @StateObject private var viewModel: AssistantViewModel
    @ObservedObject private var networkMonitor: NetworkMonitor
    @State private var showError = false
    @State private var showChat = false
    
    init(service: APIClient, errorHandler: ErrorHandling, networkMonitor: NetworkMonitor) {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(service: service, errorHandler: errorHandler))
        self.networkMonitor = networkMonitor
    }
    
    var body: some View {
        NavigationStack {
            MainContentView(
                viewModel: viewModel,
                networkMonitor: networkMonitor,
                showError: $showError
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func createThread() {
        Task {
            do {
                try await viewModel.createThread()
            } catch {
                showError = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MainContentView: View {
    @ObservedObject var viewModel: AssistantViewModel
    let networkMonitor: NetworkMonitor
    @Binding var showError: Bool
    
    var body: some View {
        ZStack {
            // Network Status remains on top
            NetworkStatusView(networkMonitor: networkMonitor)
                .animation(.easeInOut, value: networkMonitor.isConnected)
            
            // Modified main content with grouped threads
            ThreadListView(
                viewModel: viewModel,
                showError: $showError
            )
            
            // Loading overlay remains the same
            if viewModel.isLoading {
                LoadingView("Loading...")
                    .transition(.opacity)
            }
        }
    }
}

struct ThreadListView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @Binding var showError: Bool
    
    var body: some View {
        mainContent
    }
    
    private var mainContent: some View {
        List {
            ForEach(viewModel.groupedThreads) { group in
                ThreadGroupSectionView(
                    group: group,
                    viewModel: viewModel,
                    showError: $showError
                )
            }
        }
        .navigationTitle("Threads")
        .toolbar {
            Button(action: createThread) {
                Label("New Thread", systemImage: "plus")
                    .font(.headline)
            }
            .disabled(viewModel.isLoading)
        }
        .overlay {
            if viewModel.groupedThreads.isEmpty && !viewModel.isLoading {
                EmptyStateView(viewModel: viewModel)
            }
        }
    }
    
    private func createThread() {
        Task {
            do {
                try await viewModel.createThread()
            } catch {
                showError = true
            }
        }
    }
}

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
            ChatView(viewModel: viewModel)
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

struct ChatView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @State private var messageText = ""
    @State private var showError = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            MessageListView(viewModel: viewModel)
            
            Divider()
            
            ChatInputView(
                messageText: $messageText,
                viewModel: viewModel,
                showError: $showError,
                onSend: sendMessage
            )
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            isInputFocused = true
        }
        .onDisappear {
            viewModel.cancelCurrentTask()
        }
    }
    
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        messageText = ""
        
        Task {
            do {
                try await viewModel.sendMessage(message)
            } catch {
                showError = true
            }
        }
    }
}

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

struct MessageView: View {
    let message: MessageResponse
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            if message.role == "assistant" {
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .leading)
                Spacer()
            } else {
                Spacer()
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .trailing)
            }
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, Constants.Layout.smallPadding / 2)
    }
    
    private var messageContent: some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: Constants.Layout.smallPadding / 2) {
            ForEach(Array(message.content.enumerated()), id: \.1.type) { index, content in
                if let text = content.text {
                    Text(LocalizedStringKey(text.value))
                        .textSelection(.enabled)
                        .foregroundColor(message.role == "user" ? .white : Constants.Colors.textPrimary)
                        .padding(.horizontal, Constants.Layout.defaultPadding)
                        .padding(.vertical, Constants.Layout.smallPadding)
                        .background(
                            message.role == "user" ?
                                Constants.Colors.userMessageBubble :
                                Constants.Colors.assistantMessageBubble
                        )
                        .cornerRadius(Constants.Layout.messageCornerRadius)
                        .padding(message.role == "user" ? .trailing : .leading, Constants.Layout.smallPadding)
                }
            }
        }
        .scaleEffect(isAnimating ? 1 : 0.97)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(Constants.Animations.defaultSpring) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.role == "assistant" ? "Assistant message" : "Your message")
    }
}

struct StreamingMessageView: View {
    let response: String
    @State private var isAnimating = false
    let viewModel: AssistantViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            if response.isEmpty {
                TypingIndicatorView()
                    .padding(.leading, Constants.Layout.defaultPadding)
            } else {
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .leading)
                    .padding(.leading, Constants.Layout.defaultPadding)
                Spacer()
            }
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, Constants.Layout.smallPadding)
    }
    
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding / 2) {
            Text(LocalizedStringKey(response))
                .textSelection(.enabled)
                .foregroundColor(Constants.Colors.textPrimary)
                .padding(.horizontal, Constants.Layout.defaultPadding)
                .padding(.vertical, Constants.Layout.smallPadding)
                .background(Constants.Colors.assistantMessageBubble)
                .cornerRadius(Constants.Layout.messageCornerRadius)
        }
        .scaleEffect(isAnimating ? 1 : 0.97)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(Constants.Animations.defaultSpring) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Assistant is responding")
    }
}

struct StreamingMessagePreview: View {
    var body: some View {
        VStack(spacing: 20) {
            // Empty state (typing indicator)
            StreamingMessageView(
                response: "",
                viewModel: PreviewContainer().makePreviewViewModel()
            )
            
            // Filled state (with response)
            StreamingMessageView(
                response: "This is a streaming response.",
                viewModel: PreviewContainer().makePreviewViewModel()
            )
        }
        .padding()
    }
}

struct TypingIndicatorView: View {
    var body: some View {
        ProgressView()
            .padding(.vertical, 8)
            .padding(.horizontal)
            .accessibilityLabel("Assistant is typing")
    }
}

struct ChatInputView: View {
    @Binding var messageText: String
    @FocusState private var isInputFocused: Bool
    @ObservedObject var viewModel: AssistantViewModel
    @Binding var showError: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.Layout.smallPadding) {
            HStack(spacing: Constants.Layout.smallPadding) {
                TextField("Type your message", text: $messageText, axis: .vertical)
                    .padding(Constants.Layout.defaultPadding)
                    .background(Constants.Colors.secondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.largeCornerRadius))
                    .disabled(viewModel.isLoading)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .textInputAutocapitalization(.sentences)
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            Constants.Colors.textSecondary : .accentColor)
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .animation(.easeInOut, value: messageText)
            }
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, Constants.Layout.smallPadding)
        .background(.ultraThinMaterial)
        .onAppear {
            isInputFocused = true
        }
    }
}

struct EmptyStateView: View {
    @ObservedObject var viewModel: AssistantViewModel
    @State private var showError = false
    
    var body: some View {
        ContentUnavailableView {
            Label("No Threads", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Create a new thread to start chatting")
        } actions: {
            Button(action: createThread) {
                Label("New Thread", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func createThread() {
        Task {
            do {
                try await viewModel.createThread()
            } catch {
                showError = true
            }
        }
    }
}

struct PreviewContainer: View {
    var body: some View {
        let container = DependencyContainer.shared
        container.registerServices()
        
        return Group {
            if let service = container.resolve(APIClient.self),
               let errorHandler = container.resolve(ErrorHandling.self),
               let networkMonitor = container.resolve(NetworkMonitor.self) {
                ContentView(service: service, errorHandler: errorHandler, networkMonitor: networkMonitor)
            } else {
                Text("Failed to initialize services")
            }
        }
    }
}

extension PreviewContainer {
    func makePreviewViewModel() -> AssistantViewModel {
        let container = DependencyContainer.shared
        container.registerServices()
        guard let service = container.resolve(APIClient.self),
              let errorHandler = container.resolve(ErrorHandling.self) else {
            fatalError("Failed to create preview dependencies")
        }
        return AssistantViewModel(service: service, errorHandler: errorHandler)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContainer()
    }
}
