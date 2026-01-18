import SwiftUI

// MARK: - Messages List View (Snapchat-inspired)

/// Main messages list view displaying all epoch conversations
/// Inspired by Snapchat's clean, minimal conversation list
struct MessagesListView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedConversation: Conversation?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Settings action
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .navigationDestination(item: $selectedConversation) { conversation in
                ChatDetailView(conversation: conversation)
            }
        }
        .task {
            await loadConversations()
        }
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)

                // Conversations
                ForEach(filteredConversations) { conversation in
                    ConversationRow(conversation: conversation) {
                        selectedConversation = conversation
                    }

                    // Divider with indent for avatar
                    if conversation.id != filteredConversations.last?.id {
                        Divider()
                            .padding(.leading, 78)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable {
            await loadConversations()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("Search conversations...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(Theme.Colors.backgroundTertiary)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Colors.primaryFallback)

            Text("Loading messages...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("No Messages Yet")
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Join an epoch to start chatting with others")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Computed Properties

    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { conversation in
            conversation.epochTitle.localizedCaseInsensitiveContains(searchText) ||
            conversation.lastMessagePreview.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Data Loading

    private func loadConversations() async {
        isLoading = conversations.isEmpty

        do {
            let fetchedConversations = try await dependencies.messageRepository.fetchConversations()
            await MainActor.run {
                conversations = fetchedConversations
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MessagesListView()
        .environment(\.dependencies, .shared)
}
