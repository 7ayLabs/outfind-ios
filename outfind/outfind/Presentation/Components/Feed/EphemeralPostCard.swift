import SwiftUI
import Combine

// MARK: - Ephemeral Post Card

/// Full-bleed post card with large images.
/// Action buttons are overlaid inside the image.
/// Supports video posts with live photo animation on hold.
struct EphemeralPostCard: View {
    let post: EpochPost
    let isPinned: Bool
    let isExiting: Bool
    let exitProgress: CGFloat

    let onReact: (String) -> Void
    let onTimeBranch: () -> Void
    let onPin: () -> Void
    let onSave: () -> Void
    let onStartJourney: () -> Void
    let onDivergent: () -> Void
    let onJoinEpoch: () -> Void
    let onAuthorTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var dragOffsetY: CGFloat = 0
    @State private var showSaveIndicator = false
    @State private var showJourneyIndicator = false
    @State private var cardScale: CGFloat = 1.0
    @State private var cardRotation: Double = 0
    @State private var appeared = false
    @State private var swipeIconScale: CGFloat = 0.5
    @State private var swipeIconOpacity: CGFloat = 0

    // Live photo state for videos
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var isLivePhotoPlaying = false

    private let swipeThreshold: CGFloat = 80
    private let maxSwipe: CGFloat = 200

    var body: some View {
        ZStack {
            // Swipe background actions
            swipeBackgroundActions

            // Main card that follows finger
            mainCard
                .offset(x: dragOffset, y: exitOffsetY + dragOffsetY)
                .rotationEffect(.degrees(cardRotation), anchor: .bottom)
                .scaleEffect(cardScale * exitScale)
                .opacity(exitOpacity)
                .gesture(post.isLapse || post.isSaved ? nil : swipeGesture)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    // MARK: - Exit Transforms

    private var exitOffsetY: CGFloat {
        isExiting ? -exitProgress * 60 : 0
    }

    private var exitScale: CGFloat {
        isExiting ? 1 - (exitProgress * 0.1) : 1
    }

    private var exitOpacity: CGFloat {
        isExiting ? 1 - exitProgress : 1
    }

    // MARK: - Main Card

    private var mainCard: some View {
        Group {
            if post.isLapse {
                lapseCard
            } else if post.hasImages {
                imageCard
            } else {
                textCard
            }
        }
    }

    // MARK: - Image Card (Full-Bleed with Overlaid Actions)

    private var imageCard: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed image with overlays
            imageContent
                .frame(height: 420)
                .clipped()
                .overlay(alignment: .topLeading) {
                    // Author overlay
                    authorOverlay
                        .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    // Timer and badges
                    VStack(alignment: .trailing, spacing: 8) {
                        // Countdown timer (always show unless saved/pinned)
                        if !post.isSaved && !isPinned {
                            CountdownTimer(createdAt: post.createdAt, style: .standard)
                        }

                        // Badge
                        if isPinned {
                            pinnedBadge
                        } else if post.isSaved {
                            savedBadge
                        }
                    }
                    .padding(12)
                }

            // Bottom gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 180)

            // Content + Actions overlay at bottom
            VStack(alignment: .leading, spacing: 12) {
                // Content text
                if !post.content.isEmpty {
                    Text(post.content)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .lineSpacing(4)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                }

                // Action bar inside image
                overlayActionBar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // Video indicator (top right of image area)
            if post.isVideo {
                videoIndicator
                    .position(x: UIScreen.main.bounds.width - 60, y: 360)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Overlay Action Bar (Inside Image)

    private var overlayActionBar: some View {
        HStack(spacing: 0) {
            // Like button
            OverlayActionButton(
                icon: post.hasLiked ? "heart.fill" : "heart",
                count: post.reactionCount,
                isActive: post.hasLiked,
                activeColor: .red
            ) {
                onReact(post.hasLiked ? "" : "❤️")
            }

            Spacer()

            // Journey button
            OverlayActionButton(
                icon: "point.3.connected.trianglepath.dotted",
                label: "Journey",
                isActive: false,
                activeColor: Theme.Colors.epochScheduled
            ) {
                onTimeBranch()
            }

            Spacer()

            // Share button
            OverlayActionButton(
                icon: "paperplane",
                isActive: false,
                activeColor: .white
            ) {
                // Share
            }

            Spacer()

            // Save button
            OverlayActionButton(
                icon: post.isSaved ? "bookmark.fill" : "bookmark",
                isActive: post.isSaved,
                activeColor: Theme.Colors.primaryFallback
            ) {
                onSave()
            }
        }
    }

    // MARK: - Image Content with Hold Gesture

    private var imageContent: some View {
        GeometryReader { geo in
            if let imageURL = post.imageURLs.first {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(hex: "1C1C1E"))
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .scaleEffect(isLivePhotoPlaying ? 1.08 : 1.0)
                            .blur(radius: isHolding && !isLivePhotoPlaying ? 2 : 0)
                            .overlay {
                                if isHolding && !isLivePhotoPlaying {
                                    holdProgressOverlay
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: isLivePhotoPlaying)
                    case .failure:
                        Rectangle()
                            .fill(Color(hex: "1C1C1E"))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(post.isVideo ? holdGesture : nil)
    }

    // MARK: - Hold Progress Overlay

    private var holdProgressOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: 12) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Hold to play")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Hold Gesture for Videos

    private var holdGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onChanged { _ in
                if !isHolding {
                    startHolding()
                }
            }
            .onEnded { _ in
                triggerLivePhoto()
            }
            .simultaneously(with:
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        cancelHolding()
                    }
            )
    }

    private func startHolding() {
        isHolding = true
        holdProgress = 0

        // Haptic
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Animate progress
        withAnimation(.linear(duration: 0.5)) {
            holdProgress = 1.0
        }
    }

    private func cancelHolding() {
        if !isLivePhotoPlaying {
            withAnimation(.easeOut(duration: 0.2)) {
                isHolding = false
                holdProgress = 0
            }
        }
    }

    private func triggerLivePhoto() {
        guard post.isVideo else { return }

        // Heavy haptic
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isLivePhotoPlaying = true
            isHolding = false
        }

        // Play for 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isLivePhotoPlaying = false
                holdProgress = 0
            }
        }
    }

    // MARK: - Video Indicator

    private var videoIndicator: some View {
        Group {
            if isLivePhotoPlaying {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)

                    Text("LIVE")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(.red)
                }
            }
        }
    }

    // MARK: - Author Overlay

    private var authorOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author info button
            Button(action: onAuthorTap) {
                HStack(spacing: 10) {
                    // Avatar
                    if let url = post.author.avatarURL {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            avatarPlaceholderSmall
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                        }
                    } else {
                        avatarPlaceholderSmall
                    }

                    // Name & handle
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.author.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        if let handle = post.author.handle {
                            Text(handle)
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                }
            }
            .buttonStyle(.plain)

            // Location tag (if available)
            if let locationName = post.author.locationName {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .semibold))

                    Text(locationName)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .fill(.black.opacity(0.4))
                }
            }
        }
    }

    private var avatarPlaceholderSmall: some View {
        Circle()
            .fill(.white.opacity(0.2))
            .frame(width: 36, height: 36)
            .overlay {
                Text(String(post.author.name.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }

    // MARK: - Text Card (No Image)

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            cardHeader
                .padding(.horizontal, 16)
                .padding(.top, 16)

            // Content
            Text(post.content)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineSpacing(5)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Action bar
            textCardActionBar
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 16)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            if isPinned { pinnedBadge.padding(12) }
            else if post.isSaved { savedBadge.padding(12) }
        }
    }

    // MARK: - Card Header (for text cards)

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Avatar
                Button(action: onAuthorTap) {
                    if let url = post.author.avatarURL {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            avatarPlaceholder
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    } else {
                        avatarPlaceholder
                    }
                }
                .buttonStyle(.plain)

                // Author info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.author.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        if let handle = post.author.handle {
                            Text(handle)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }

                    HStack(spacing: 4) {
                        Text(post.timeAgo)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Timer (if not saved/pinned)
                if !post.isSaved && !isPinned {
                    CountdownTimer(createdAt: post.createdAt, style: .compact)
                }
            }

            // Location tag
            if let locationName = post.author.locationName {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9, weight: .semibold))

                    Text(locationName)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.primaryFallback)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(Theme.Colors.primaryFallback.opacity(0.1))
                }
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Theme.Colors.primaryFallback.opacity(0.12))
            .frame(width: 44, height: 44)
            .overlay {
                Text(String(post.author.name.prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
    }

    // MARK: - Text Card Action Bar

    private var textCardActionBar: some View {
        HStack(spacing: 0) {
            ActionButton(
                icon: post.hasLiked ? "heart.fill" : "heart",
                count: post.reactionCount,
                isActive: post.hasLiked,
                activeColor: .red
            ) {
                onReact(post.hasLiked ? "" : "❤️")
            }

            Spacer()

            ActionButton(
                icon: "point.3.connected.trianglepath.dotted",
                label: "Journey",
                isActive: false,
                activeColor: Theme.Colors.epochScheduled
            ) {
                onTimeBranch()
            }

            Spacer()

            ActionButton(
                icon: "paperplane",
                isActive: false,
                activeColor: Theme.Colors.primaryFallback
            ) {
                // Share
            }

            Spacer()

            ActionButton(
                icon: post.isSaved ? "bookmark.fill" : "bookmark",
                isActive: post.isSaved,
                activeColor: Theme.Colors.primaryFallback
            ) {
                onSave()
            }
        }
    }

    // MARK: - Lapse Card

    private var lapseCard: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.epochActive.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.Colors.epochActive)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(post.epochName ?? "Live Lapse")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.epochActive)
                        .frame(width: 6, height: 6)

                    Text("\(post.participantCount ?? 0) present")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.epochActive)

                    Text("·")
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(post.author.firstName)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()

            CountdownTimer(createdAt: post.createdAt, style: .lapse)
        }
        .padding(16)
        .background(lapseBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.Colors.epochActive.opacity(0.2), lineWidth: 1)
        }
        .onTapGesture {
            onJoinEpoch()
        }
    }

    // MARK: - Backgrounds

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : .white
    }

    private var lapseBackground: Color {
        colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "F0FDF4")
    }

    // MARK: - Badges

    private var pinnedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "pin.fill")
                .font(.system(size: 10, weight: .bold))
            Text("Pinned")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.epochScheduled)
        }
    }

    private var savedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 10, weight: .bold))
            Text("Saved")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(Theme.Colors.primaryFallback)
        }
    }

    // MARK: - Swipe Actions

    private var swipeBackgroundActions: some View {
        GeometryReader { geo in
            ZStack {
                // Save background (swipe right) - revealed on left side
                HStack {
                    ZStack {
                        // Gradient background
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback,
                                Theme.Colors.primaryFallback.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        // Icon with animation
                        Image(systemName: showSaveIndicator ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(swipeIconScale)
                            .opacity(swipeIconOpacity)
                            .rotationEffect(.degrees(showSaveIndicator ? 0 : -15))
                    }
                    .frame(width: max(0, dragOffset))

                    Spacer()
                }
                .opacity(dragOffset > 0 ? 1 : 0)

                // Journey background (swipe left) - revealed on right side
                HStack {
                    Spacer()

                    ZStack {
                        // Gradient background
                        LinearGradient(
                            colors: [
                                Theme.Colors.epochScheduled.opacity(0.8),
                                Theme.Colors.epochScheduled
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        // Icon with animation
                        Image(systemName: "point.3.connected.trianglepath.dotted")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(swipeIconScale)
                            .opacity(swipeIconOpacity)
                            .rotationEffect(.degrees(showJourneyIndicator ? 0 : 15))
                    }
                    .frame(width: max(0, -dragOffset))
                }
                .opacity(dragOffset < 0 ? 1 : 0)
            }
            .frame(height: geo.size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Swipe Gesture (Horizontal priority - allows vertical scroll)

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                let translationX = value.translation.width
                let translationY = value.translation.height

                // Only activate horizontal swipe if gesture is more horizontal than vertical
                // This allows vertical scrolling to take priority
                guard abs(translationX) > abs(translationY) * 1.5 else {
                    return
                }

                // Horizontal drag with rubber band effect at edges
                if abs(translationX) > maxSwipe {
                    let overflow = abs(translationX) - maxSwipe
                    let resistance = 1 - (overflow / (overflow + 100))
                    dragOffset = (translationX > 0 ? maxSwipe : -maxSwipe) + (translationX > 0 ? 1 : -1) * overflow * resistance
                } else {
                    dragOffset = translationX
                }

                // Slight vertical following for natural feel
                dragOffsetY = max(-10, min(10, translationY * 0.3))

                // Calculate rotation based on drag (max ±8 degrees)
                let rotationAmount = (dragOffset / maxSwipe) * 8
                cardRotation = max(-8, min(8, rotationAmount))

                // Scale down slightly while dragging
                let dragProgress = abs(dragOffset) / swipeThreshold
                cardScale = 1 - (min(dragProgress, 1) * 0.05)

                // Icon animations based on progress
                let iconProgress = min(abs(dragOffset) / swipeThreshold, 1.0)
                swipeIconScale = 0.5 + (iconProgress * 0.7)
                swipeIconOpacity = iconProgress

                // Update indicators
                let passedThreshold = abs(dragOffset) > swipeThreshold
                if passedThreshold != showSaveIndicator && dragOffset > 0 {
                    showSaveIndicator = passedThreshold
                    if passedThreshold {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
                if passedThreshold != showJourneyIndicator && dragOffset < 0 {
                    showJourneyIndicator = passedThreshold
                    if passedThreshold {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            .onEnded { value in
                let translationX = value.translation.width
                let translationY = value.translation.height
                let velocity = value.velocity.width

                // Only process if it was a horizontal swipe
                guard abs(translationX) > abs(translationY) * 1.5 else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        resetSwipeState()
                    }
                    return
                }

                // Check if swipe passed threshold or has high velocity
                let passedRight = translationX > swipeThreshold || velocity > 500
                let passedLeft = translationX < -swipeThreshold || velocity < -500

                if passedRight && translationX > 0 {
                    // Animate card flying off to the right then snap back
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        dragOffset = 120
                        cardRotation = 12
                    }

                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    // Then snap back and trigger save
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            resetSwipeState()
                        }
                        onSave()
                    }
                } else if passedLeft && translationX < 0 {
                    // Animate card flying off to the left then snap back
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        dragOffset = -120
                        cardRotation = -12
                    }

                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    // Then snap back and trigger journey
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            resetSwipeState()
                        }
                        onStartJourney()
                    }
                } else {
                    // Snap back with spring animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                        resetSwipeState()
                    }
                }
            }
    }

    private func resetSwipeState() {
        dragOffset = 0
        dragOffsetY = 0
        cardScale = 1.0
        cardRotation = 0
        showSaveIndicator = false
        showJourneyIndicator = false
        swipeIconScale = 0.5
        swipeIconOpacity = 0
    }
}

// MARK: - Overlay Action Button (For Image Cards)

private struct OverlayActionButton: View {
    let icon: String
    var label: String? = nil
    var count: Int? = nil
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))

                if let count = count, count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 14, weight: .bold))
                } else if let label = label {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .foregroundStyle(isActive ? activeColor : .white)
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            .scaleEffect(isPressed ? 1.2 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 { return "\(count / 1000000)M" }
        if count >= 1000 { return "\(count / 1000)k" }
        return "\(count)"
    }
}

// MARK: - Action Button (For Text Cards)

private struct ActionButton: View {
    let icon: String
    var label: String? = nil
    var count: Int? = nil
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))

                if let count = count, count > 0 {
                    Text(formatCount(count))
                        .font(.system(size: 13, weight: .semibold))
                } else if let label = label {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .foregroundStyle(isActive ? activeColor : Theme.Colors.textSecondary)
            .scaleEffect(isPressed ? 1.15 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 { return "\(count / 1000000)M" }
        if count >= 1000 { return "\(count / 1000)k" }
        return "\(count)"
    }
}

// MARK: - Countdown Timer

struct CountdownTimer: View {
    let createdAt: Date
    var style: TimerStyle = .standard

    enum TimerStyle {
        case standard
        case lapse
        case compact
    }

    @State private var timeRemaining: TimeInterval = 0
    @State private var progress: CGFloat = 1.0
    @State private var isActive = true

    // Use Timer.publish for automatic cleanup when view disappears
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var maxDuration: TimeInterval {
        style == .lapse ? 900 : 300
    }

    private var timerColor: Color {
        if progress > 0.5 {
            switch style {
            case .lapse: return Theme.Colors.epochActive
            case .standard: return .white
            case .compact: return Theme.Colors.textTertiary
            }
        } else if progress > 0.2 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.error
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .lapse: return timerColor.opacity(0.12)
        case .standard: return .black.opacity(0.4)
        case .compact: return timerColor.opacity(0.1)
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(timerColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 18, height: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-90))
            }

            Text(formatTime(timeRemaining))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(timerColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(backgroundColor)
        }
        .onAppear {
            updateTime()
            isActive = true
        }
        .onDisappear {
            isActive = false
        }
        .onReceive(timer) { _ in
            guard isActive else { return }
            updateTime()
        }
    }

    private func updateTime() {
        let elapsed = Date().timeIntervalSince(createdAt)
        timeRemaining = max(0, maxDuration - elapsed)
        progress = CGFloat(timeRemaining / maxDuration)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Previews

#Preview("Image Posts") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(EpochPost.mockPosts().filter { $0.hasImages }.prefix(3)) { post in
                EphemeralPostCard(
                    post: post,
                    isPinned: false,
                    isExiting: false,
                    exitProgress: 0,
                    onReact: { _ in },
                    onTimeBranch: {},
                    onPin: {},
                    onSave: {},
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

#Preview("Dark Mode") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(EpochPost.mockPosts().prefix(4)) { post in
                EphemeralPostCard(
                    post: post,
                    isPinned: false,
                    isExiting: false,
                    exitProgress: 0,
                    onReact: { _ in },
                    onTimeBranch: {},
                    onPin: {},
                    onSave: {},
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
