import SwiftUI

// MARK: - Ephemeral Post Card

/// Minimalist post card with liquid glass effect.
/// Swipe left-to-right: Start a journey
/// Swipe right-to-left: Open divergent epoch branch
struct EphemeralPostCard: View {
    let post: EpochPost
    let isPinned: Bool
    let isExiting: Bool
    let exitProgress: CGFloat

    let onReact: (String) -> Void
    let onTimeBranch: () -> Void
    let onPin: () -> Void
    let onStartJourney: () -> Void
    let onDivergent: () -> Void
    let onJoinEpoch: () -> Void
    let onAuthorTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var showJourneyIndicator = false
    @State private var showDivergentIndicator = false
    @State private var cardScale: CGFloat = 1.0
    @State private var showEmojiPicker = false
    @State private var appeared = false

    private let swipeThreshold: CGFloat = 70
    private let maxSwipe: CGFloat = 100

    var body: some View {
        ZStack {
            // Background actions
            swipeBackgroundActions

            // Main card
            mainCard
                .offset(x: dragOffset + exitOffset)
                .scaleEffect(cardScale * exitScale)
                .opacity(exitOpacity)
                .rotation3DEffect(exitRotation, axis: (x: 0, y: 1, z: 0), anchor: .leading)
                .gesture(post.isLapse ? nil : swipeGesture)

            // Emoji picker overlay
            if showEmojiPicker {
                EmojiPickerOverlay(isPresented: $showEmojiPicker) { emoji in
                    onReact(emoji)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Exit Transforms

    private var exitOffset: CGFloat {
        isExiting ? -exitProgress * 250 : 0
    }

    private var exitScale: CGFloat {
        isExiting ? 1 - (exitProgress * 0.1) : 1
    }

    private var exitOpacity: CGFloat {
        isExiting ? 1 - (exitProgress * 0.8) : 1
    }

    private var exitRotation: Angle {
        isExiting ? .degrees(exitProgress * -8) : .zero
    }

    // MARK: - Main Card

    private var mainCard: some View {
        Group {
            if post.isLapse {
                lapseCard
            } else {
                regularCard
            }
        }
    }

    // MARK: - Lapse Card (Minimal - just message and join)

    private var lapseCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Epoch name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.epochName ?? "Lapse")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.epochActive)
                            .frame(width: 6, height: 6)

                        Text("\(post.participantCount ?? 0) present")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Text("·")
                            .foregroundStyle(Theme.Colors.textTertiary)

                        Text(post.author.firstName)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()
            }

            // Join button
            Button(action: onJoinEpoch) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))

                    Text("Join")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.Colors.primaryFallback)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(Theme.Spacing.md)
        .background { liquidGlassBackground }
        .overlay { glassStroke }
    }

    // MARK: - Regular Post Card

    private var regularCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Minimal header
            postHeader
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

            // Content
            Text(post.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineSpacing(5)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

            // Footer
            postFooter
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
        }
        .background { liquidGlassBackground }
        .overlay { glassStroke }
        .overlay(alignment: .topTrailing) {
            if isPinned {
                pinnedIndicator
            }
        }
    }

    // MARK: - Liquid Glass Background

    private var liquidGlassBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.08), Color.white.opacity(0.02)]
                                : [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
    }

    private var glassStroke: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.2 : 0.5),
                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Post Header

    private var postHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Avatar
            Button(action: onAuthorTap) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Text(String(post.author.name.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.author.firstName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(post.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Post Footer

    private var postFooter: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Animated emoji button
            AnimatedEmojiButton(
                hasReacted: post.userReaction != nil,
                onTap: {
                    if post.userReaction != nil {
                        onReact("")
                    } else {
                        onReact("❤️")
                    }
                },
                onLongPress: {
                    showEmojiPicker = true
                }
            )

            // Time branches
            TimeBranchButton(
                branchCount: post.commentCount + post.journeyCount,
                onTap: onTimeBranch
            )

            Spacer()

            // Swipe hint
            HStack(spacing: 4) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 11))

                Text("swipe")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
        }
    }

    // MARK: - Pinned Indicator

    private var pinnedIndicator: some View {
        Image(systemName: "pin.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Theme.Colors.epochScheduled)
            .padding(8)
            .background {
                Circle()
                    .fill(Theme.Colors.epochScheduled.opacity(0.15))
            }
            .offset(x: -8, y: -8)
    }

    // MARK: - Swipe Background Actions

    private var swipeBackgroundActions: some View {
        HStack(spacing: 0) {
            // Left side - Journey (swipe right reveals)
            HStack(spacing: 8) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 20, weight: .bold))

                if showJourneyIndicator {
                    Text("Journey")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: max(0, dragOffset), alignment: .center)
            .background(Theme.Colors.primaryFallback)
            .opacity(dragOffset > 0 ? 1 : 0)

            Spacer()

            // Right side - Divergent (swipe left reveals)
            HStack(spacing: 8) {
                if showDivergentIndicator {
                    Text("Branch")
                        .font(.system(size: 13, weight: .bold))
                }

                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 20, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: max(0, -dragOffset), alignment: .center)
            .background(Theme.Colors.epochScheduled)
            .opacity(dragOffset < 0 ? 1 : 0)
        }
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                let translation = value.translation.width

                // Apply resistance beyond threshold
                if abs(translation) > maxSwipe {
                    let overflow = abs(translation) - maxSwipe
                    let resistance = 1 - (overflow / (overflow + 80))
                    dragOffset = (translation > 0 ? maxSwipe : -maxSwipe) + (translation > 0 ? 1 : -1) * overflow * resistance
                } else {
                    dragOffset = translation
                }

                // Scale feedback
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    cardScale = 1 - (abs(dragOffset) / 800)
                    showJourneyIndicator = dragOffset > swipeThreshold
                    showDivergentIndicator = dragOffset < -swipeThreshold
                }

                // Haptic at threshold
                if abs(dragOffset) > swipeThreshold - 5 && abs(dragOffset) < swipeThreshold + 5 {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            }
            .onEnded { value in
                let translation = value.translation.width

                if translation > swipeThreshold {
                    // Journey action (swipe right)
                    triggerJourney()
                } else if translation < -swipeThreshold {
                    // Divergent action (swipe left)
                    triggerDivergent()
                }

                // Reset
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dragOffset = 0
                    cardScale = 1.0
                    showJourneyIndicator = false
                    showDivergentIndicator = false
                }
            }
    }

    private func triggerJourney() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        onStartJourney()
    }

    private func triggerDivergent() {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        onDivergent()
    }
}

// MARK: - Viewable Post Model

struct ViewablePost: Identifiable, Equatable {
    let id: UUID
    let data: EpochPost
    var isVisible: Bool = true

    init(post: EpochPost) {
        self.id = post.id
        self.data = post
    }

    static func == (lhs: ViewablePost, rhs: ViewablePost) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview

#Preview("Regular Posts") {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(EpochPost.mockPosts().filter { !$0.isLapse }.prefix(3)) { post in
                EphemeralPostCard(
                    post: post,
                    isPinned: false,
                    isExiting: false,
                    exitProgress: 0,
                    onReact: { _ in },
                    onTimeBranch: {},
                    onPin: {},
                    onStartJourney: {},
                    onDivergent: {},
                    onJoinEpoch: {},
                    onAuthorTap: {}
                )
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}

#Preview("Lapse Posts") {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(EpochPost.mockPosts().filter { $0.isLapse }.prefix(3)) { post in
                EphemeralPostCard(
                    post: post,
                    isPinned: false,
                    isExiting: false,
                    exitProgress: 0,
                    onReact: { _ in },
                    onTimeBranch: {},
                    onPin: {},
                    onStartJourney: {},
                    onDivergent: {},
                    onJoinEpoch: {},
                    onAuthorTap: {}
                )
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}

#Preview("Pinned") {
    EphemeralPostCard(
        post: EpochPost.mockPosts()[0],
        isPinned: true,
        isExiting: false,
        exitProgress: 0,
        onReact: { _ in },
        onTimeBranch: {},
        onPin: {},
        onStartJourney: {},
        onDivergent: {},
        onJoinEpoch: {},
        onAuthorTap: {}
    )
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(EpochPost.mockPosts().prefix(4)) { post in
                EphemeralPostCard(
                    post: post,
                    isPinned: post.id == EpochPost.mockPosts()[0].id,
                    isExiting: false,
                    exitProgress: 0,
                    onReact: { _ in },
                    onTimeBranch: {},
                    onPin: {},
                    onStartJourney: {},
                    onDivergent: {},
                    onJoinEpoch: {},
                    onAuthorTap: {}
                )
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
    .preferredColorScheme(.dark)
}
