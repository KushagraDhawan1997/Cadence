//
//  ContentView.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: AssistantViewModel
    @State private var showError = false
    @State private var showChat = false
    
    init() {
        _viewModel = StateObject(wrappedValue: AssistantViewModel(service: OpenAIService()))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.threads, id: \.id) { thread in
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
                        VStack(alignment: .leading, spacing: Constants.Layout.smallPadding) {
                            Text("Thread \(String(thread.id.suffix(4)))")
                                .font(.headline)
                                .foregroundColor(Constants.Colors.textPrimary)
                            Text(formatDate(Date(timeIntervalSince1970: TimeInterval(thread.createdAt))))
                                .font(.subheadline)
                                .foregroundColor(Constants.Colors.textSecondary)
                        }
                        .padding(.vertical, Constants.Layout.smallPadding)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    let threadToDelete = thread
                                    try await viewModel.deleteThread(threadToDelete)
                                } catch {
                                    showError = true
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Threads")
            .toolbar {
                Button(action: createThread) {
                    Label("New Thread", systemImage: "plus")
                        .font(.headline)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
        .task {
            do {
                try await viewModel.createThread()
            } catch {
                showError = true
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
        .submitLabel(.send)
        .onSubmit {
            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading {
                sendMessage()
            }
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
                    } else if viewModel.isLoading {
                        TypingIndicatorView()
                            .id("typing")
                            .transition(.opacity)
                    }
                }
                .onChange(of: viewModel.messages) { _, _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: viewModel.streamingResponse) { _, _ in
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
        } else if viewModel.isLoading {
            proxy.scrollTo("typing", anchor: .bottom)
        } else if let lastId = viewModel.messages.last?.id {
            proxy.scrollTo(lastId, anchor: .bottom)
        }
    }
}

struct MessageView: View {
    let message: MessageResponse
    @State private var isAnimating = false
    
    var body: some View {
        HStack {
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
        .padding(.vertical, Constants.Layout.smallPadding)
    }
    
    private var messageContent: some View {
        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
            ForEach(message.content, id: \.type) { content in
                if let text = content.text {
                    Text(text.value)
                        .textSelection(.enabled)
                        .foregroundColor(message.role == "user" ? .white : Constants.Colors.textPrimary)
                        .padding(.horizontal, Constants.Layout.defaultPadding)
                        .padding(.vertical, Constants.Layout.smallPadding)
                        .background(
                            message.role == "user" ?
                                Constants.Colors.userMessageBubble :
                                Constants.Colors.assistantMessageBubble
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.messageCornerRadius, style: .continuous))
                }
            }
        }
        .scaleEffect(isAnimating ? 1 : 0.9)
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
        HStack {
            if response.isEmpty {
                TypingIndicatorView()
            } else {
                messageContent
                    .frame(maxWidth: Constants.Layout.maxMessageWidth, alignment: .leading)
            }
            Spacer()
        }
        .padding(.horizontal, Constants.Layout.defaultPadding)
        .padding(.vertical, 2)
    }
    
    private var messageContent: some View {
        Text(response)
            .textSelection(.enabled)
            .foregroundColor(Constants.Colors.textPrimary)
            .padding(.horizontal, Constants.Layout.smallPadding)
            .padding(.vertical, Constants.Layout.smallPadding)
            .background(Constants.Colors.assistantMessageBubble)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.messageCornerRadius, style: .continuous))
            .scaleEffect(isAnimating ? 1 : 0.9)
            .opacity(isAnimating ? 1 : 0)
            .onAppear {
                withAnimation(Constants.Animations.defaultSpring) {
                    isAnimating = true
                }
            }
    }
}

struct TypingIndicatorView: View {
    @State private var showDots = false
    
    var body: some View {
        HStack {
            Spacer(minLength: Constants.Layout.defaultPadding)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .frame(width: 6, height: 6)
                        .opacity(showDots ? 1 : 0.5)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(0.2 * Double(index)),
                            value: showDots
                        )
                }
            }
            .padding(.horizontal, Constants.Layout.defaultPadding)
            .padding(.vertical, Constants.Layout.smallPadding)
            .background(Constants.Colors.assistantMessageBubble)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.messageCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer()
        }
        .padding(.vertical, Constants.Layout.smallPadding)
        .onAppear {
            showDots = true
        }
        .accessibilityElement(children: .ignore)
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

#Preview {
    ContentView()
}
