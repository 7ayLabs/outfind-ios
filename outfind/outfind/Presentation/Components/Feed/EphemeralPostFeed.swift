import SwiftUI

// MARK: - Ephemeral Post Feed

/// A feed that displays posts with ephemeral behavior.
/// Posts that scroll past the top of the viewport disappear after a 1-second delay.
/// Scrolling back within the delay cancels the dismissal.
/// Swipe left-to-right: Start a journey
/// Swipe right-to-left: Open divergent epoch branch
struct EphemeralPostFeed: View {
    @Binding var posts: [EpochPost]
    @Binding var pinnedPostIds: Set<UUID>
    let onReact: (UUID, String) -> Void
    let onStartJourney: (UUID) -> Void
    let onDivergent: (UUID) -> Void
    let onJoinEpoch: (UUID) -> Void
    let onRefresh: () async -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Dismissal state
    @State private var pendingDismissals: [UUID: Task<Void, Never>] = [:]
    @State private var exitingPosts: Set<UUID> = []
    @State private var exitProgress: [UUID: CGFloat] = [:]

    // Entrance animation state
    @State private var appearedPosts: Set<UUID> = []

    // Time branch sheet
    @State private var selectedPostForBranches: EpochPost?
    @State private var showTimeBranchSheet = false

    // Empty state animation
    @State private var statsAppeared = false

    var body: some View {
        GeometryReader { outerGeo in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    // Pinned posts section (at top)
                    if !pinnedPostsList.isEmpty {
                        pinnedSection
                    }

                    // Regular posts
                    ForEach(regularPosts) { post in
                        postCard(post, in: outerGeo)
                            .padding(.horizontal, Theme.Spacing.md)
                    }

                    // Empty state
                    if posts.isEmpty {
                        emptyState
                    }

                    // Bottom spacer for tab bar
                    Spacer(minLength: 120)
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .refreshable {
                await onRefresh()
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showTimeBranchSheet) {
            if let post = selectedPostForBranches {
                TimeBranchSheet(
                    post: post,
                    isPresented: $showTimeBranchSheet,
                    onStartJourney: {
                        onStartJourney(post.id)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Computed Properties

    private var pinnedPostsList: [EpochPost] {
        posts.filter { pinnedPostIds.contains($0.id) }
    }

    private var regularPosts: [EpochPost] {
        posts.filter { !pinnedPostIds.contains($0.id) }
    }

    // MARK: - Pinned Section

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.epochScheduled)

                Text("Pinned")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Pinned posts
            ForEach(pinnedPostsList) { post in
                pinnedPostCard(post)
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.epochScheduled.opacity(0.05))
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Pinned Post Card

    @ViewBuilder
    private func pinnedPostCard(_ post: EpochPost) -> some View {
        EphemeralPostCard(
            post: post,
            isPinned: true,
            isExiting: false,
            exitProgress: 0,
            onReact: { emoji in onReact(post.id, emoji) },
            onTimeBranch: {
                selectedPostForBranches = post
                showTimeBranchSheet = true
            },
            onPin: { unpinPost(post.id) },
            onStartJourney: { onStartJourney(post.id) },
            onDivergent: { onDivergent(post.id) },
            onJoinEpoch: { onJoinEpoch(post.id) },
            onAuthorTap: { /* Navigate to author */ }
        )
    }

    // MARK: - Post Card

    @ViewBuilder
    private func postCard(_ post: EpochPost, in outerGeo: GeometryProxy) -> some View {
        let isExiting = exitingPosts.contains(post.id)
        let exitProg = exitProgress[post.id] ?? 0
        let hasAppeared = appearedPosts.contains(post.id)

        EphemeralPostCard(
            post: post,
            isPinned: false,
            isExiting: isExiting,
            exitProgress: exitProg,
            onReact: { emoji in onReact(post.id, emoji) },
            onTimeBranch: {
                selectedPostForBranches = post
                showTimeBranchSheet = true
            },
            onPin: { pinPost(post.id) },
            onStartJourney: { onStartJourney(post.id) },
            onDivergent: { onDivergent(post.id) },
            onJoinEpoch: { onJoinEpoch(post.id) },
            onAuthorTap: { /* Navigate to author */ }
        )
        // Entrance animation
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
        .scaleEffect(hasAppeared ? 1 : 0.97)
        .background {
            GeometryReader { cardGeo in
                Color.clear
                    .onChange(of: cardGeo.frame(in: .global).maxY) { _, maxY in
                        handleScrollPosition(for: post.id, maxY: maxY, viewportTop: outerGeo.frame(in: .global).minY)
                    }
            }
        }
        .onAppear {
            cancelDismissTimer(post.id)
            animateEntrance(post.id)
        }
        .onDisappear {
            startDismissTimer(post.id)
        }
    }

    // MARK: - Pin/Unpin Actions

    private func pinPost(_ id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pinnedPostIds.insert(id)
        }
        cancelDismissTimer(id)

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }

    private func unpinPost(_ id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pinnedPostIds.remove(id)
        }
    }

    // MARK: - Entrance Animation

    private func animateEntrance(_ id: UUID) {
        guard !appearedPosts.contains(id) else { return }

        let delay = Double(posts.firstIndex(where: { $0.id == id }) ?? 0) * 0.06

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                _ = appearedPosts.insert(id)
            }
        }
    }

    // MARK: - Scroll Position Handler

    private func handleScrollPosition(for postId: UUID, maxY: CGFloat, viewportTop: CGFloat) {
        // Don't dismiss pinned posts or lapse posts
        guard !pinnedPostIds.contains(postId),
              let post = posts.first(where: { $0.id == postId }),
              !post.isLapse else { return }

        let isPastViewport = maxY < viewportTop + 50

        if isPastViewport && !pendingDismissals.keys.contains(postId) {
            startDismissTimer(postId)
        } else if !isPastViewport {
            cancelDismissTimer(postId)
        }
    }

    // MARK: - Dismiss Timer

    private func startDismissTimer(_ id: UUID) {
        guard !pinnedPostIds.contains(id),
              !pendingDismissals.keys.contains(id),
              !exitingPosts.contains(id) else { return }

        pendingDismissals[id] = Task {
            try? await Task.sleep(for: .seconds(1))

            guard !Task.isCancelled else { return }

            await MainActor.run {
                animateExit(id)
            }
        }
    }

    private func cancelDismissTimer(_ id: UUID) {
        pendingDismissals[id]?.cancel()
        pendingDismissals.removeValue(forKey: id)

        if exitingPosts.contains(id) {
            withAnimation(.easeOut(duration: 0.15)) {
                exitingPosts.remove(id)
                exitProgress.removeValue(forKey: id)
            }
        }
    }

    // MARK: - Exit Animation

    private func animateExit(_ id: UUID) {
        withAnimation(.easeOut(duration: 0.1)) {
            exitingPosts.insert(id)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            exitProgress[id] = 1.0
        }

        Task {
            try? await Task.sleep(for: .milliseconds(350))

            await MainActor.run {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    posts.removeAll { $0.id == id }
                    exitingPosts.remove(id)
                    exitProgress.removeValue(forKey: id)
                    pendingDismissals.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: 100)

            ZStack {
                Circle()
                    .stroke(Theme.Colors.primaryFallback.opacity(0.2), lineWidth: 2)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: statsAppeared ? 1 : 0)
                    .stroke(Theme.Colors.primaryFallback, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: statsAppeared)

                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback)
                    .scaleEffect(statsAppeared ? 1 : 0.5)
                    .opacity(statsAppeared ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.4), value: statsAppeared)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("All caught up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Pull to refresh for new posts")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            if !pinnedPostsList.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11, weight: .bold))

                    Text("\(pinnedPostsList.count) pinned")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.epochScheduled)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Theme.Colors.epochScheduled.opacity(0.1))
                }
            }

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                statsAppeared = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var posts = EpochPost.mockPosts()
        @State private var pinnedPostIds: Set<UUID> = []

        var body: some View {
            EphemeralPostFeed(
                posts: $posts,
                pinnedPostIds: $pinnedPostIds,
                onReact: { id, emoji in
                    if let index = posts.firstIndex(where: { $0.id == id }) {
                        if emoji.isEmpty {
                            posts[index].userReaction = nil
                        } else {
                            posts[index].userReaction = emoji
                            posts[index].reactions[emoji, default: 0] += 1
                        }
                    }
                },
                onStartJourney: { id in
                    print("Start journey from post \(id)")
                },
                onDivergent: { id in
                    print("Open divergent branch from post \(id)")
                },
                onJoinEpoch: { id in
                    print("Join epoch from post \(id)")
                },
                onRefresh: {
                    try? await Task.sleep(for: .seconds(1))
                    posts = EpochPost.mockPosts()
                }
            )
            .background(Theme.Colors.background)
        }
    }

    return PreviewWrapper()
}

#Preview("Empty State") {
    struct EmptyPreviewWrapper: View {
        @State private var posts: [EpochPost] = []
        @State private var pinnedPostIds: Set<UUID> = []

        var body: some View {
            EphemeralPostFeed(
                posts: $posts,
                pinnedPostIds: $pinnedPostIds,
                onReact: { _, _ in },
                onStartJourney: { _ in },
                onDivergent: { _ in },
                onJoinEpoch: { _ in },
                onRefresh: {
                    try? await Task.sleep(for: .seconds(1))
                    posts = EpochPost.mockPosts()
                }
            )
            .background(Theme.Colors.background)
        }
    }

    return EmptyPreviewWrapper()
}

#Preview("Dark Mode") {
    struct DarkPreviewWrapper: View {
        @State private var posts = EpochPost.mockPosts()
        @State private var pinnedPostIds: Set<UUID> = []

        var body: some View {
            EphemeralPostFeed(
                posts: $posts,
                pinnedPostIds: $pinnedPostIds,
                onReact: { _, _ in },
                onStartJourney: { _ in },
                onDivergent: { _ in },
                onJoinEpoch: { _ in },
                onRefresh: {
                    try? await Task.sleep(for: .seconds(1))
                    posts = EpochPost.mockPosts()
                }
            )
            .background(Theme.Colors.background)
            .preferredColorScheme(.dark)
        }
    }

    return DarkPreviewWrapper()
}
