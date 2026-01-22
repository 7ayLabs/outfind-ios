import SwiftUI

// MARK: - Ephemeral Post Feed

/// A feed that displays posts with ephemeral behavior organized by sections.
/// Posts fade upward and vanish when 20% scrolled off the top of the viewport.
/// Saved posts are preserved and don't vanish.
/// Swipe left-to-right: SAVE post (prevents vanishing)
/// Swipe right-to-left: Start a journey
struct EphemeralPostFeed: View {
    @Binding var posts: [EpochPost]
    @Binding var pinnedPostIds: Set<UUID>
    @Binding var savedPosts: [EpochPost]
    let onReact: (UUID, String) -> Void
    let onStartJourney: (UUID) -> Void
    let onSave: (UUID) -> Void
    let onJoinEpoch: (UUID) -> Void
    let onRefresh: () async -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Dismissal state (no timer needed - immediate vanish)
    @State private var exitingPosts: Set<UUID> = []
    @State private var exitProgress: [UUID: CGFloat] = [:]
    @State private var postHeights: [UUID: CGFloat] = [:]
    @State private var processedExits: Set<UUID> = []

    // Entrance animation state
    @State private var appearedPosts: Set<UUID> = []

    // Time branch sheet
    @State private var selectedPostForBranches: EpochPost?
    @State private var showTimeBranchSheet = false

    // Save sheet
    @State private var savedPostForSheet: EpochPost?
    @State private var showSavedSheet = false

    // Create epoch sheet
    @State private var showCreateEpoch = false

    // Empty state animation
    @State private var statsAppeared = false

    // Feed filter tabs
    @State private var selectedFilter: FeedFilter = .forYou
    @Namespace private var filterAnimation

    // Visibility threshold - vanish at 75% off screen (25% visible)
    private let vanishThreshold: CGFloat = 0.25

    // MARK: - Feed Filter Enum

    enum FeedFilter: String, CaseIterable {
        case forYou = "For You"
        case following = "Following"
        case nearby = "Nearby"
        case `private` = "Private"

        var icon: String {
            switch self {
            case .forYou: return "sparkles"
            case .following: return "person.2.fill"
            case .nearby: return "location.fill"
            case .private: return "lock.fill"
            }
        }
    }

    // MARK: - Computed Properties

    private var pinnedPostsList: [EpochPost] {
        posts.filter { pinnedPostIds.contains($0.id) }
    }

    private var nearbyPosts: [EpochPost] {
        posts.filter {
            !pinnedPostIds.contains($0.id) &&
            !$0.isSaved &&
            $0.sectionType == .nearby
        }
    }

    private var privatePosts: [EpochPost] {
        posts.filter {
            !pinnedPostIds.contains($0.id) &&
            !$0.isSaved &&
            $0.sectionType == .private
        }
    }

    private var followingPosts: [EpochPost] {
        posts.filter {
            !pinnedPostIds.contains($0.id) &&
            !$0.isSaved &&
            $0.sectionType == .following
        }
    }

    private var trendingPosts: [EpochPost] {
        posts.filter {
            !pinnedPostIds.contains($0.id) &&
            !$0.isSaved &&
            $0.sectionType == .trending
        }
    }

    // Filtered posts based on selected tab
    private var filteredPosts: [EpochPost] {
        let basePosts = posts.filter {
            !pinnedPostIds.contains($0.id) && !$0.isSaved
        }

        switch selectedFilter {
        case .forYou:
            return basePosts // Show all
        case .following:
            return basePosts.filter { $0.sectionType == .following }
        case .nearby:
            return basePosts.filter { $0.sectionType == .nearby }
        case .private:
            return basePosts.filter { $0.sectionType == .private }
        }
    }

    var body: some View {
        GeometryReader { outerGeo in
            VStack(spacing: 0) {
                // Filter tabs
                filterTabBar

                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        // Pinned posts section (at top)
                        if !pinnedPostsList.isEmpty {
                            pinnedSection
                        }

                        // Saved posts section
                        if !savedPosts.isEmpty {
                            savedSection
                        }

                        // Filtered posts based on selected tab
                        ForEach(filteredPosts) { post in
                            postCard(post, in: outerGeo)
                                .padding(.horizontal, Theme.Spacing.md)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity
                                ))
                        }

                        // Empty state for filter
                        if filteredPosts.isEmpty && !posts.isEmpty {
                            filterEmptyState
                        }

                        // Empty state
                        if posts.isEmpty {
                            emptyState
                        }

                        // Bottom spacer for tab bar
                        Spacer(minLength: 120)
                    }
                    .padding(.top, Theme.Spacing.sm)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedFilter)
                }
                .refreshable {
                    await onRefresh()
                }
                .scrollIndicators(.hidden)
            }
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
        .sheet(isPresented: $showSavedSheet) {
            if let post = savedPostForSheet {
                SavedInsightsSheet(
                    isPresented: $showSavedSheet,
                    savedPost: post,
                    allSavedPosts: savedPosts,
                    onCreateNew: {
                        showSavedSheet = false
                        // Trigger create action
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showCreateEpoch) {
            UnifiedComposerView()
        }
    }

    // MARK: - Filter Tab Bar

    private var filterTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(FeedFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }

                // Add Epoch button
                addEpochButton
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 8)
        }
        .background {
            Rectangle()
                .fill(Theme.Colors.background)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        }
    }

    // MARK: - Add Epoch Button

    private var addEpochButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showCreateEpoch = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))

                Text("Epoch")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Theme.Colors.primaryFallback)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .strokeBorder(Theme.Colors.primaryFallback, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }
        }
        .buttonStyle(.plain)
    }

    private func filterTab(_ filter: FeedFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count = filterCount(for: filter)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(filter.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))

                if count > 0 && isSelected {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? .white : Theme.Colors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.25) : Theme.Colors.backgroundSecondary)
                        }
                }
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(filterColor(for: filter))
                        .matchedGeometryEffect(id: "filterBg", in: filterAnimation)
                } else {
                    Capsule()
                        .fill(Theme.Colors.backgroundSecondary.opacity(0.5))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func filterCount(for filter: FeedFilter) -> Int {
        switch filter {
        case .forYou: return posts.filter { !pinnedPostIds.contains($0.id) && !$0.isSaved }.count
        case .following: return followingPosts.count
        case .nearby: return nearbyPosts.count
        case .private: return privatePosts.count
        }
    }

    private func filterColor(for filter: FeedFilter) -> Color {
        switch filter {
        case .forYou: return Theme.Colors.primaryFallback
        case .following: return Theme.Colors.info
        case .nearby: return Theme.Colors.epochActive
        case .private: return Theme.Colors.epochScheduled
        }
    }

    // MARK: - Filter Empty State

    private var filterEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(filterColor(for: selectedFilter).opacity(0.5))

            VStack(spacing: 4) {
                Text("No \(selectedFilter.rawValue) posts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Check back later or try another filter")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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

    // MARK: - Saved Section

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                Text("Saved")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Text("\(savedPosts.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Preview of saved posts (max 2)
            ForEach(savedPosts.prefix(2)) { post in
                savedPostPreview(post)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            // View all button if more than 2
            if savedPosts.count > 2 {
                Button {
                    if let firstPost = savedPosts.first {
                        savedPostForSheet = firstPost
                        showSavedSheet = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("View all \(savedPosts.count) saved")
                            .font(.system(size: 13, weight: .medium))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.primaryFallback.opacity(0.05))
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Saved Post Preview

    private func savedPostPreview(_ post: EpochPost) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Avatar
            Circle()
                .fill(Theme.Colors.primaryFallback.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(post.author.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(post.author.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(post.content)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Time saved
            Text(post.savedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark
                      ? Theme.Colors.backgroundSecondary
                      : Color.white)
        }
        .onTapGesture {
            savedPostForSheet = post
            showSavedSheet = true
        }
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
            onSave: { handleSave(post) },
            onStartJourney: { onStartJourney(post.id) },
            onDivergent: { /* No longer used */ },
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
            onSave: { handleSave(post) },
            onStartJourney: { onStartJourney(post.id) },
            onDivergent: { /* No longer used */ },
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
                    .onAppear {
                        // Store card height for visibility calculation
                        postHeights[post.id] = cardGeo.size.height
                    }
                    .onChange(of: cardGeo.frame(in: .global)) { _, frame in
                        handleVisibility(
                            postId: post.id,
                            cardFrame: frame,
                            viewportFrame: outerGeo.frame(in: .global),
                            isSaved: post.isSaved
                        )
                    }
            }
        }
        .onAppear {
            animateEntrance(post.id)
        }
    }

    // MARK: - Handle Save

    private func handleSave(_ post: EpochPost) {
        // Mark as saved
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            var savedPost = posts[index]
            savedPost.isSaved = true
            savedPost.savedAt = Date()
            posts[index] = savedPost

            // Call save callback
            onSave(post.id)

            // Show saved sheet
            savedPostForSheet = savedPost
            showSavedSheet = true

            // Haptic
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
        }
    }

    // MARK: - Pin/Unpin Actions

    private func pinPost(_ id: UUID) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pinnedPostIds.insert(id)
        }

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

    // MARK: - Visibility Handler (20% Threshold)

    private func handleVisibility(
        postId: UUID,
        cardFrame: CGRect,
        viewportFrame: CGRect,
        isSaved: Bool
    ) {
        // Don't dismiss saved, pinned, or lapse posts
        guard !isSaved,
              !pinnedPostIds.contains(postId),
              let post = posts.first(where: { $0.id == postId }),
              !post.isLapse,
              !exitingPosts.contains(postId),
              !processedExits.contains(postId) else { return }

        let cardHeight = cardFrame.height
        guard cardHeight > 0 else { return }

        let viewportTop = viewportFrame.minY
        let cardTop = cardFrame.minY
        let cardBottom = cardFrame.maxY

        // Calculate how much of the card is visible
        let visibleTop = max(viewportTop, cardTop)
        let visibleBottom = cardBottom
        let visibleHeight = max(0, visibleBottom - visibleTop)
        let visibilityRatio = visibleHeight / cardHeight

        // Check if scrolled above viewport
        let isAboveViewport = cardTop < viewportTop

        // Trigger exit when 20% off screen (80% visible) and card is above viewport
        if isAboveViewport && visibilityRatio <= vanishThreshold {
            // Mark as processed immediately to prevent duplicate triggers
            processedExits.insert(postId)
            animateVerticalExit(postId)
        }
    }

    // MARK: - Vertical Exit Animation (Upward)

    private func animateVerticalExit(_ id: UUID) {
        // Start exit animation immediately (no delay)
        withAnimation(.easeOut(duration: 0.1)) {
            exitingPosts.insert(id)
        }

        // Animate upward fade
        withAnimation(.easeOut(duration: 0.35)) {
            exitProgress[id] = 1.0
        }

        // Remove after animation completes
        Task {
            try? await Task.sleep(for: .milliseconds(350))

            await MainActor.run {
                // Light haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                withAnimation(.easeOut(duration: 0.2)) {
                    posts.removeAll { $0.id == id }
                    exitingPosts.remove(id)
                    exitProgress.removeValue(forKey: id)
                    postHeights.removeValue(forKey: id)
                    // Keep in processedExits to prevent re-triggering
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

            // Show counts for pinned and saved
            HStack(spacing: Theme.Spacing.md) {
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

                if !savedPosts.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 11, weight: .bold))

                        Text("\(savedPosts.count) saved")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    }
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
        @State private var savedPosts: [EpochPost] = []

        var body: some View {
            EphemeralPostFeed(
                posts: $posts,
                pinnedPostIds: $pinnedPostIds,
                savedPosts: $savedPosts,
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
                onSave: { id in
                    if let post = posts.first(where: { $0.id == id }) {
                        savedPosts.append(post)
                    }
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
        @State private var savedPosts: [EpochPost] = []

        var body: some View {
            EphemeralPostFeed(
                posts: $posts,
                pinnedPostIds: $pinnedPostIds,
                savedPosts: $savedPosts,
                onReact: { _, _ in },
                onStartJourney: { _ in },
                onSave: { _ in },
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
        @State private var savedPosts: [EpochPost] = []

        var body: some View {
            EphemeralPostFeed(
                posts: $posts,
                pinnedPostIds: $pinnedPostIds,
                savedPosts: $savedPosts,
                onReact: { _, _ in },
                onStartJourney: { _ in },
                onSave: { _ in },
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
