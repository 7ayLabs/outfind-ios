import SwiftUI

// MARK: - Messages List View (Web3 Green Theme)

/// Main messages list view displaying all epoch conversations
/// Features segmented tabs for "My Epochs" vs "Joined" with green web3 styling
struct MessagesListView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedConversation: Conversation?
    @State private var selectedFilter: ConversationFilter = .myEpochs

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if filteredConversations.isEmpty {
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
                // Segmented filter control
                segmentedControl
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.xs)
                    .padding(.bottom, Theme.Spacing.sm)

                // Search bar
                searchBar
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.sm)

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

    // MARK: - Segmented Control

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(ConversationFilter.allCases, id: \.self) { filter in
                segmentButton(for: filter)
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.backgroundTertiary)
        }
    }

    private func segmentButton(for filter: ConversationFilter) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Text(filter.displayTitle)
                    .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .medium))

                // Count badge
                let count = conversationCount(for: filter)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(selectedFilter == filter ? .white : Theme.Colors.neonGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(selectedFilter == filter ? Theme.Colors.neonGreen : Theme.Colors.neonGreen.opacity(0.15))
                        }
                }
            }
            .foregroundStyle(selectedFilter == filter ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                if selectedFilter == filter {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.surface)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .strokeBorder(Theme.Colors.neonGreen.opacity(0.3), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func conversationCount(for filter: ConversationFilter) -> Int {
        switch filter {
        case .myEpochs:
            return conversations.filter { $0.isCreatedByCurrentUser }.count
        case .joined:
            return conversations.filter { !$0.isCreatedByCurrentUser }.count
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
        // First filter by segment
        let segmentFiltered: [Conversation]
        switch selectedFilter {
        case .myEpochs:
            segmentFiltered = conversations.filter { $0.isCreatedByCurrentUser }
        case .joined:
            segmentFiltered = conversations.filter { !$0.isCreatedByCurrentUser }
        }

        // Then filter by search text
        if searchText.isEmpty {
            return segmentFiltered
        }
        return segmentFiltered.filter { conversation in
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
