import SwiftUI

// MARK: - Chat Detail View

/// Chat thread view for a specific epoch conversation
/// Displays messages with real-time updates and input bar
struct ChatDetailView: View {
    let conversation: Conversation

    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else {
                    messagesScrollView
                }

                MessageInputBar(text: $messageText) {
                    sendMessage()
                }
            }
        }
        .navigationTitle(conversation.epochTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerView
            }

            ToolbarItem(placement: .topBarTrailing) {
                epochInfoButton
            }
        }
        .task {
            await loadMessages()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(conversation.epochEmoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 0) {
                Text(conversation.epochTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("\(conversation.participantCount) participants")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Epoch Info Button

    private var epochInfoButton: some View {
        Button {
            // Show epoch info
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Epoch header
                    epochHeader
                        .padding(.vertical, Theme.Spacing.lg)

                    // Messages
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    // Bottom spacer for input bar
                    Color.clear
                        .frame(height: Theme.Spacing.sm)
                        .id("bottom")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Epoch Header

    private var epochHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Epoch emoji
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    .frame(width: 64, height: 64)

                Text(conversation.epochEmoji)
                    .font(.system(size: 32))
            }

            // Epoch info
            VStack(spacing: Theme.Spacing.xxs) {
                Text(conversation.epochTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("\(conversation.participantCount) people in this epoch")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            // State badge
            if conversation.state == .archived {
                Text("This epoch has ended")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.backgroundTertiary)
                    }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.primaryFallback)
            Spacer()
        }
    }

    // MARK: - Actions

    private func loadMessages() async {
        isLoading = true

        do {
            let fetchedMessages = try await dependencies.messageRepository.fetchMessages(conversationId: conversation.id)
            await MainActor.run {
                messages = fetchedMessages
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        messageText = ""

        Task {
            do {
                let newMessage = try await dependencies.messageRepository.sendMessage(
                    epochId: conversation.epochId,
                    content: content
                )
                await MainActor.run {
                    messages.append(newMessage)
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatDetailView(conversation: Conversation.sampleConversations[0])
    }
    .environment(\.dependencies, .shared)
}
