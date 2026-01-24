import SwiftUI

// MARK: - Home View

/// Main home view with ephemeral feed behavior.
/// Posts fade upward and vanish when 20% scrolled off the top (immediate).
/// Swipe right to save posts (prevents vanishing).
/// Protocol-aligned: ephemeral data only persists during active epochs.
struct HomeView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    // Data state
    @State private var posts: [EpochPost] = []
    @State private var currentUser: User?
    @State private var pinnedPostIds: Set<UUID> = []
    @State private var savedPosts: [EpochPost] = []

    // UI state
    @State private var isLoading = true
    @State private var showNotificationsSheet = false
    @State private var showPostComposer = false
    @State private var notificationCount: Int = 4

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else {
                    // Ephemeral Post Feed with scrollable header
                    EphemeralPostFeed(
                        posts: $posts,
                        pinnedPostIds: $pinnedPostIds,
                        savedPosts: $savedPosts,
                        onReact: { postId, emoji in
                            reactToPost(postId, with: emoji)
                        },
                        onStartJourney: { postId in
                            startJourney(from: postId)
                        },
                        onSave: { postId in
                            savePost(postId)
                        },
                        onJoinEpoch: { postId in
                            joinEpoch(from: postId)
                        },
                        onRefresh: {
                            await loadPosts()
                        },
                        header: {
                            HomeHeader(
                                notificationCount: notificationCount,
                                onNotificationsTap: {
                                    showNotificationsSheet = true
                                },
                                onMessagesTap: {
                                    // Navigate to messages
                                }
                            )
                        }
                    )
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsSheetView(notificationCount: $notificationCount)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPostComposer) {
                SimplePostComposerView { newPost in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        posts.insert(newPost, at: 0)
                    }
                }
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Theme.Colors.primaryFallback, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
            }

            Text("Loading your feed...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - HomeView Actions

extension HomeView {
    func loadData() async {
        isLoading = true

        // Load current user
        let user = await dependencies.authenticationRepository.currentUser

        // Load posts
        await loadPosts()

        await MainActor.run {
            currentUser = user
            isLoading = false
        }
    }

    func loadPosts() async {
        // Load posts (mock for now)
        let fetchedPosts = EpochPost.mockPosts()

        await MainActor.run {
            // Only add new posts, don't reset
            if posts.isEmpty {
                posts = fetchedPosts
            } else {
                // Simulate new posts arriving
                let newPosts = EpochPost.mockPosts()
                for post in newPosts where !posts.contains(where: { $0.id == post.id }) {
                    posts.insert(post, at: 0)
                }
            }
        }
    }

    func reactToPost(_ postId: UUID, with emoji: String) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if let index = posts.firstIndex(where: { $0.id == postId }) {
            if emoji.isEmpty {
                // Remove reaction
                if let currentReaction = posts[index].userReaction {
                    posts[index].reactions[currentReaction, default: 1] -= 1
                    if posts[index].reactions[currentReaction] == 0 {
                        posts[index].reactions.removeValue(forKey: currentReaction)
                    }
                }
                posts[index].userReaction = nil
                posts[index].hasLiked = false
            } else {
                // Add/change reaction
                if let currentReaction = posts[index].userReaction {
                    // Remove old reaction
                    posts[index].reactions[currentReaction, default: 1] -= 1
                    if posts[index].reactions[currentReaction] == 0 {
                        posts[index].reactions.removeValue(forKey: currentReaction)
                    }
                }
                // Add new reaction
                posts[index].userReaction = emoji
                posts[index].reactions[emoji, default: 0] += 1
                posts[index].hasLiked = true
                posts[index].reactionCount = posts[index].reactions.values.reduce(0, +)
            }
        }
    }

    func savePost(_ postId: UUID) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Find the post and add to saved posts
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            var savedPost = posts[index]
            savedPost.isSaved = true
            savedPost.savedAt = Date()

            // Update in posts array
            posts[index] = savedPost

            // Add to saved posts if not already there
            if !savedPosts.contains(where: { $0.id == postId }) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    savedPosts.insert(savedPost, at: 0)
                }
            }
        }
    }

    func startJourney(from postId: UUID) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Navigate to journey creation with the post context
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                posts[index].journeyCount += 1
            }
        }

        // TODO: Navigate to journey creation view
        // coordinator.navigate(to: .createJourney(fromPostId: postId))
    }

    func joinEpoch(from postId: UUID) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // Find the epoch from the lapse post and join it
        if let post = posts.first(where: { $0.id == postId }) {
            // TODO: Navigate to epoch and join
            // coordinator.navigate(to: .activeEpoch(epochId: post.epochId))
        }
    }

    @ViewBuilder
    func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        case .journeyDetail(let journeyId):
            JourneyDetailView(journeyId: journeyId)
        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}

#Preview("Dark Mode") {
    HomeView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
        .preferredColorScheme(.dark)
}
