import SwiftUI

// MARK: - Home View

/// Main home view with ephemeral feed behavior.
/// Posts disappear permanently after being scrolled past (1-second delay).
/// Protocol-aligned: ephemeral data only persists during active epochs.
struct HomeView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    // Data state
    @State private var posts: [EpochPost] = []
    @State private var currentUser: User?
    @State private var pinnedPostIds: Set<UUID> = []

    // UI state
    @State private var isLoading = true
    @State private var showNotificationsSheet = false
    @State private var showPostComposer = false
    @State private var notificationCount: Int = 4

    // Computed counts for header
    private var ephemeralCount: Int {
        posts.filter { !pinnedPostIds.contains($0.id) }.count
    }

    private var pinnedCount: Int {
        pinnedPostIds.count
    }

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with avatar, stats, and action buttons
                    HomeHeader(
                        user: currentUser,
                        ephemeralCount: ephemeralCount,
                        pinnedCount: pinnedCount,
                        notificationCount: notificationCount,
                        onAvatarTap: {
                            // Navigate to profile
                        },
                        onNotificationsTap: {
                            showNotificationsSheet = true
                        },
                        onMessagesTap: {
                            // Navigate to messages
                        }
                    )
                    .padding(.top, Theme.Spacing.sm)
                    .padding(.bottom, Theme.Spacing.sm)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: ephemeralCount)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pinnedCount)

                    if isLoading {
                        loadingView
                    } else {
                        // Ephemeral Post Feed with swipe gestures and emoji reactions
                        EphemeralPostFeed(
                            posts: $posts,
                            pinnedPostIds: $pinnedPostIds,
                            onReact: { postId, emoji in
                                reactToPost(postId, with: emoji)
                            },
                            onStartJourney: { postId in
                                startJourney(from: postId)
                            },
                            onDivergent: { postId in
                                openDivergentBranch(from: postId)
                            },
                            onJoinEpoch: { postId in
                                joinEpoch(from: postId)
                            },
                            onRefresh: {
                                await loadPosts()
                            }
                        )
                    }
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

    func openDivergentBranch(from postId: UUID) {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        // TODO: Navigate to divergent epoch branch creation
        // coordinator.navigate(to: .createDivergentEpoch(fromPostId: postId))
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
