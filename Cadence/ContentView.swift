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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Thread \(String(thread.id.suffix(4)))")
                                .font(.headline)
                            Text(formatDate(Date(timeIntervalSince1970: TimeInterval(thread.createdAt))))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
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
                    Image(systemName: "plus")
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
            // Messages List
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.messages, initial: true) { _, newMessages in
                        if let lastId = newMessages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                HStack {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isLoading)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                    
                    Button(action: sendMessage) {
                        Image(systemName: viewModel.isLoading ? "clock" : "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .padding(.leading, 8)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
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

struct MessageView: View {
    let message: MessageResponse
    
    var body: some View {
        HStack {
            if message.role == "assistant" {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 2)
                
                ForEach(message.content, id: \.type) { content in
                    if let text = content.text {
                        Text(text.value)
                            .textSelection(.enabled)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: message.role == "assistant" ? .trailing : .leading)
            .padding(12)
            .background(message.role == "assistant" ?
                       Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            if message.role == "user" {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    ContentView()
}
