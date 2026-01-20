import SwiftUI

// MARK: - HomeView Supporting Components
// Components extracted from HomeView to reduce file size

// MARK: - Epoch Card Style

enum EpochCardStyle {
    case live
    case standard
}

// MARK: - Epoch Scroll Card (Horizontal)

struct EpochScrollCard: View {
    let epoch: Epoch
    let style: EpochCardStyle
    let isFavorite: Bool
    var journey: LapseJourney?
    let onFavoriteTap: () -> Void
    var onJourneyTap: (() -> Void)?
    let onTap: () -> Void

    private var cardWidth: CGFloat {
        style == .live ? 280 : 200
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Area
                ZStack(alignment: .topTrailing) {
                    // Placeholder gradient
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: cardGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: style == .live ? 140 : 120)

                    // Journey badge (bottom left)
                    if let journey = journey {
                        VStack {
                            Spacer()
                            HStack {
                                Button {
                                    onJourneyTap?()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                                            .font(.system(size: 9, weight: .medium))

                                        Text(journey.title)
                                            .font(.system(size: 10, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background {
                                        Capsule()
                                            .fill(Color.black.opacity(0.5))
                                    }
                                }
                                .buttonStyle(ScaleButtonStyle())

                                Spacer()
                            }
                            .padding(8)
                        }
                    }

                    // Live badge
                    if epoch.state == .active {
                        VStack {
                            HStack {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 6, height: 6)

                                    Text("LIVE")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(Theme.Colors.epochActive)
                                }

                                Spacer()
                            }
                            .padding(8)

                            Spacer()
                        }
                    }

                    // Favorite button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onFavoriteTap) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(isFavorite ? Theme.Colors.error : .white)
                                    .frame(width: 32, height: 32)
                                    .background {
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                    }
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }

                // Info Area
                VStack(alignment: .leading, spacing: 4) {
                    Text(epoch.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.Colors.textTertiary)

                        Text("\(epoch.participantCount) people")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    if style == .live {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.warning)

                            Text(formatTimeLeft(epoch.timeUntilNextPhase))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.Colors.warning)
                        }
                    }
                }
                .padding(Theme.Spacing.sm)
            }
            .frame(width: cardWidth)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var cardGradientColors: [Color] {
        switch epoch.state {
        case .active:
            return [Theme.Colors.epochActive, Theme.Colors.epochActive.opacity(0.7)]
        case .scheduled:
            return [Theme.Colors.epochScheduled, Theme.Colors.epochScheduled.opacity(0.7)]
        default:
            return [Theme.Colors.primaryFallback, Theme.Colors.primaryFallback.opacity(0.7)]
        }
    }

    private func formatTimeLeft(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        }
        return "\(minutes)m left"
    }
}

// MARK: - Epoch Grid Card

struct EpochGridCard: View {
    let epoch: Epoch
    let isFavorite: Bool
    var journey: LapseJourney?
    let onFavoriteTap: () -> Void
    var onJourneyTap: (() -> Void)?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Area
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.primaryFallback.opacity(0.8), Theme.Colors.primaryFallback.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)

                    // Journey badge (bottom left)
                    if let journey = journey {
                        VStack {
                            Spacer()
                            HStack {
                                Button {
                                    onJourneyTap?()
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                                            .font(.system(size: 8, weight: .medium))

                                        Text("\(journey.orderOf(epochId: epoch.id) ?? 1)/\(journey.epochCount)")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background {
                                        Capsule()
                                            .fill(Color.black.opacity(0.5))
                                    }
                                }
                                .buttonStyle(ScaleButtonStyle())

                                Spacer()
                            }
                            .padding(6)
                        }
                    }

                    // Favorite button (top right)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onFavoriteTap) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(isFavorite ? Theme.Colors.error : .white)
                                    .frame(width: 28, height: 28)
                                    .background {
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                    }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                }

                // Info Area
                VStack(alignment: .leading, spacing: 4) {
                    Text(epoch.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(2)

                    // Rating/Participants
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.warning)

                        Text("\(epoch.participantCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("participants")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // State badge
                    Text(epoch.state.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(stateColor)
                }
                .padding(Theme.Spacing.sm)
            }
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var stateColor: Color {
        switch epoch.state {
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        default: return Theme.Colors.textSecondary
        }
    }
}

// MARK: - Person Card

struct PersonCard: View {
    let user: MockUser

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: user.avatarURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Circle()
                            .fill(Theme.Colors.backgroundTertiary)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(Circle())

                // Status indicator
                Circle()
                    .fill(user.status.color)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.Colors.background, lineWidth: 2)
                    }
            }

            Text(user.name.components(separatedBy: " ").first ?? user.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

// MARK: - Echo Person Card

/// Card for displaying echo (ghost) presences in the People Nearby section
struct EchoPersonCard: View {
    let presence: Presence

    @State private var shimmerPhase: CGFloat = 0

    private var opacity: Double {
        presence.echoOpacity
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Ghost Avatar
            ZStack(alignment: .bottomTrailing) {
                // Avatar with opacity based on decay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.backgroundTertiary.opacity(opacity),
                                Theme.Colors.backgroundSecondary.opacity(opacity * 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay {
                        // Shimmer effect
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.1 * opacity),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(shimmerPhase * 360))
                    }
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.textTertiary.opacity(opacity))
                    }

                // Ghost indicator (replaces status)
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.2))
                        .frame(width: 18, height: 18)

                    Image(systemName: "waveform")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Theme.Colors.primaryFallback.opacity(opacity))
                }
            }

            // Time since left
            if let timeLabel = presence.timeSinceLeft {
                Text(timeLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary.opacity(max(opacity, 0.5)))
                    .lineLimit(1)
            } else {
                Text("Echo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
            }
        }
        .frame(width: 80)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
            ) {
                shimmerPhase = 1.0
            }
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Presence Signal Button (7ay-presence protocol)

/// Button to open 7ay-presence protocol modal
/// Shows active state when network is connected
/// Optimized: Removed continuous pulse animation for CPU efficiency
struct PresenceSignalButton: View {
    let isActive: Bool
    let action: () -> Void

    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        Button {
            triggerAnimation()
            action()
        } label: {
            ZStack {
                // Static ring when active (no animation)
                if isActive {
                    Circle()
                        .stroke(Theme.Colors.primaryFallback.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 50)
                }

                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay {
                        if isActive {
                            Circle()
                                .strokeBorder(Theme.Colors.primaryFallback.opacity(0.5), lineWidth: 1.5)
                        } else {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }

                // Signal icon
                IconView(.nearby, size: .md, color: isActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(iconScale)
            }
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private func triggerAnimation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            iconRotation = 15
            iconScale = 1.2
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
            iconRotation = 0
            iconScale = 1.0
        }
    }
}

// MARK: - Notification Bell Button (Liquid Glass)

/// Notification button with liquid glass style
struct NotificationBellButton: View {
    let notificationCount: Int
    let action: () -> Void

    @State private var bellRotation: Double = 0
    @State private var dotScale: CGFloat = 1.0

    private var hasNotifications: Bool {
        notificationCount > 0
    }

    var body: some View {
        Button {
            triggerAnimation()
            action()
        } label: {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }

                // Bell icon
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .rotationEffect(.degrees(bellRotation))

                // Notification dot
                if hasNotifications {
                    Circle()
                        .fill(Theme.Colors.error)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle()
                                .strokeBorder(Theme.Colors.background, lineWidth: 2)
                        }
                        .scaleEffect(dotScale)
                        .offset(x: 10, y: -10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hasNotifications)
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private func triggerAnimation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Bell ring animation
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            bellRotation = 15
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3).delay(0.1)) {
            bellRotation = -15
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3).delay(0.2)) {
            bellRotation = 10
        }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5).delay(0.3)) {
            bellRotation = 0
        }
    }
}

// MARK: - Wallet Sheet View

struct WalletSheetView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var currentUser: User?
    @State private var isDisconnecting = false
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("Profile")
                .font(Typography.titleLarge)
                .foregroundStyle(Theme.Colors.textPrimary)

            if isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.xl)
            } else if let user = currentUser {
                profileCard(for: user)

                Spacer()

                Button {
                    disconnect()
                } label: {
                    HStack {
                        if isDisconnecting {
                            ProgressView()
                                .tint(Theme.Colors.error)
                                .scaleEffect(0.8)
                        }
                        Text("Disconnect")
                            .font(Typography.titleSmall)
                    }
                    .foregroundStyle(Theme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                    }
                }
                .buttonStyle(AnimatedButtonStyle())
                .disabled(isDisconnecting)
            } else {
                Text("Not connected")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.vertical, Theme.Spacing.xl)
            }

            SecondaryButton("Done") {
                dismiss()
            }
        }
        .padding()
        .background(Theme.Colors.background)
        .task {
            isLoading = true
            currentUser = await dependencies.authenticationRepository.currentUser
            isLoading = false
        }
    }

    @ViewBuilder
    private func profileCard(for user: User) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 80, height: 80)

                IconView(user.authMethod.isWallet ? .wallet : .google, size: .xl, color: Theme.Colors.primaryFallback)
            }

            VStack(spacing: Theme.Spacing.xxs) {
                if let displayName = user.displayName {
                    Text(displayName)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(user.displayIdentifier)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    private func disconnect() {
        isDisconnecting = true
        Task {
            try? await dependencies.authenticationRepository.disconnect()
            await MainActor.run {
                dismiss()
                coordinator.handleWalletDisconnected()
            }
        }
    }
}

// MARK: - Presence Network Sheet View (7ay-presence protocol)

/// Sheet view for 7ay-presence network status and controls
/// Enables peer-to-peer communication via 7ay network without internet
struct PresenceNetworkSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isNetworkActive: Bool

    @State private var nearbyPeers: Int = 0
    @State private var isScanning = false
    @State private var hasAppeared = false
    @State private var isSheetVisible = false
    @State private var ringScale: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var centerIconRotation: Double = 0
    @State private var centerIconScale: CGFloat = 1.0
    @State private var scanningIndicatorScale: CGFloat = 1.0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Drag indicator
            Capsule()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, Theme.Spacing.xs)

            // Header with title
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("7ay-presence")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("7ay network")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                // Live status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(isNetworkActive ? Theme.Colors.success : Theme.Colors.textTertiary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(scanningIndicatorScale)

                    Text(isNetworkActive ? (isScanning ? "Scanning" : "Active") : "Off")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isNetworkActive ? Theme.Colors.success : Theme.Colors.textTertiary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(isNetworkActive ? Theme.Colors.success.opacity(0.15) : Theme.Colors.backgroundTertiary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Network visualization (compact)
            ZStack {
                // Animated pulse rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Theme.Colors.primaryFallback.opacity(isNetworkActive ? 0.25 - Double(index) * 0.08 : 0.08),
                            lineWidth: 1.5
                        )
                        .frame(
                            width: CGFloat(60 + index * 30),
                            height: CGFloat(60 + index * 30)
                        )
                        .scaleEffect(ringScale[index])
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: hasAppeared)
                }

                // Center button/icon
                Button {
                    toggleNetwork()
                } label: {
                    ZStack {
                        // Glow effect when active
                        if isNetworkActive {
                            Circle()
                                .fill(Theme.Colors.primaryFallback.opacity(0.3))
                                .frame(width: 70, height: 70)
                                .blur(radius: 10)
                        }

                        Circle()
                            .frame(width: 60, height: 60)
                            .background {
                                if isNetworkActive {
                                    Circle()
                                        .fill(Theme.Colors.primaryFallback.opacity(0.2))
                                } else {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        isNetworkActive
                                            ? Theme.Colors.primaryFallback.opacity(0.5)
                                            : Color.white.opacity(0.2),
                                        lineWidth: 1.5
                                    )
                            }

                        IconView(
                            .nearby,
                            size: .lg,
                            color: isNetworkActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary
                        )
                        .rotationEffect(.degrees(centerIconRotation))
                        .scaleEffect(centerIconScale)
                    }
                }
                .buttonStyle(AnimatedButtonStyle())
            }
            .frame(height: 150)
            .onAppear {
                hasAppeared = true
            }

            // Stats row (compact horizontal)
            HStack(spacing: Theme.Spacing.sm) {
                statCard(
                    icon: .participants,
                    value: "\(nearbyPeers)",
                    label: "Peers",
                    color: Theme.Colors.primaryFallback
                )

                statCard(
                    icon: .radar,
                    value: isNetworkActive ? "50m" : "--",
                    label: "Range",
                    color: Theme.Colors.info
                )

                statCard(
                    icon: .bolt,
                    value: isNetworkActive ? "Low" : "--",
                    label: "Latency",
                    color: Theme.Colors.success
                )
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Info text (shorter)
            Text("Tap the signal icon to \(isNetworkActive ? "disconnect from" : "join") the mesh network.")
                .font(Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Action button
            Button {
                toggleNetwork()
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    if isScanning {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: isNetworkActive ? "wifi.slash" : "wifi")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Text(isNetworkActive ? "Disconnect" : "Activate")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    if isNetworkActive {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.Colors.error)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.Colors.primaryGradient)
                    }
                }
            }
            .buttonStyle(AnimatedButtonStyle())
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .background(Theme.Colors.background)
        .onAppear {
            isSheetVisible = true
            hasAppeared = true
            startAnimations()
        }
        .onDisappear {
            isSheetVisible = false
            stopAnimations()
        }
        .onChange(of: isScanning) { _, _ in
            if isSheetVisible { startAnimations() }
        }
        .onChange(of: isNetworkActive) { _, _ in
            if isSheetVisible { startAnimations() }
        }
    }

    private func statCard(icon: AppIcon, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                IconView(icon, size: .xs, color: color)
                    .scaleEffect(isNetworkActive ? 1.0 : 0.9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isNetworkActive)

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(color.opacity(isNetworkActive ? 0.3 : 0.1), lineWidth: 1)
        }
    }

    private func startAnimations() {
        guard isSheetVisible else { return }
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            while !Task.isCancelled && isSheetVisible {
                // Scanning indicator animation
                if isScanning {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        scanningIndicatorScale = 1.3
                    }
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    guard !Task.isCancelled else { break }
                    withAnimation(.easeInOut(duration: 0.6)) {
                        scanningIndicatorScale = 1.0
                    }
                    try? await Task.sleep(nanoseconds: 600_000_000)
                }

                // Ring breathing animation when active
                if isNetworkActive && !isScanning {
                    withAnimation(.easeInOut(duration: 2.0)) {
                        ringScale = [1.05, 1.08, 1.1]
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    guard !Task.isCancelled else { break }
                    withAnimation(.easeInOut(duration: 2.0)) {
                        ringScale = [1.0, 1.0, 1.0]
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                } else if !isNetworkActive {
                    // Idle - just wait
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }

    private func stopAnimations() {
        animationTask?.cancel()
        animationTask = nil
        withAnimation(.easeOut(duration: 0.2)) {
            ringScale = [1.0, 1.0, 1.0]
            scanningIndicatorScale = 1.0
        }
    }

    private func toggleNetwork() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Icon animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            centerIconRotation = isNetworkActive ? -15 : 15
            centerIconScale = 1.2
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
            centerIconRotation = 0
            centerIconScale = 1.0
        }

        if isNetworkActive {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isNetworkActive = false
                isScanning = false
                nearbyPeers = 0
                ringScale = [1.0, 1.0, 1.0]
            }
        } else {
            isScanning = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isNetworkActive = true
            }

            // Simulate finding peers
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard isSheetVisible else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isScanning = false
                    nearbyPeers = Int.random(in: 2...12)
                }
            }
        }
    }
}

// MARK: - Notifications Sheet View

/// Sheet view for displaying user notifications
struct NotificationsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notificationCount: Int

    @State private var notifications: [NotificationItem] = NotificationItem.sampleNotifications
    @State private var hasAppeared = false
    @State private var clearAllScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Theme.Spacing.xs) {
                Capsule()
                    .fill(Theme.Colors.textTertiary.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, Theme.Spacing.xs)

                HStack {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Notifications")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        // Unread count badge
                        let unreadCount = notifications.filter { !$0.isRead }.count
                        if unreadCount > 0 {
                            Text("\(unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule()
                                        .fill(Theme.Colors.primaryFallback)
                                }
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Spacer()

                    if !notifications.isEmpty {
                        Button {
                            triggerClearAll()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("Clear")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .scaleEffect(clearAllScale)
                        }
                        .buttonStyle(AnimatedButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(.bottom, Theme.Spacing.sm)

            // Content
            if notifications.isEmpty {
                emptyState
            } else {
                notificationsList
            }
        }
        .background(Theme.Colors.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                hasAppeared = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()

            ZStack {
                // Animated rings
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(Theme.Colors.textTertiary.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat(90 + index * 30), height: CGFloat(90 + index * 30))
                        .scaleEffect(hasAppeared ? 1.0 : 0.8)
                        .opacity(hasAppeared ? 1.0 : 0)
                        .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: hasAppeared)
                }

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    }

                Image(systemName: "bell.slash")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2), value: hasAppeared)
            }

            VStack(spacing: 4) {
                Text("All Caught Up!")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("No new notifications")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .opacity(hasAppeared ? 1.0 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)

            Spacer()
        }
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(notifications.enumerated()), id: \.element.id) { index, notification in
                    NotificationRow(notification: notification, animationDelay: Double(index) * 0.05) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            notifications.removeAll { $0.id == notification.id }
                            updateNotificationCount()
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func triggerClearAll() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            clearAllScale = 0.9
        }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.1)) {
            clearAllScale = 1.0
        }

        // Use Task-based staggered removal to avoid memory leak from DispatchQueue closures
        Task { @MainActor in
            while !notifications.isEmpty {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s delay
                guard !notifications.isEmpty else { break }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    notifications.removeLast()
                    updateNotificationCount()
                }
            }
        }
    }

    private func updateNotificationCount() {
        notificationCount = notifications.count
    }
}

// MARK: - Notification Item Model

struct NotificationItem: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool

    enum NotificationType {
        case epochActive
        case epochEnding
        case presenceValidated
        case newPeer
        case system

        var icon: AppIcon {
            switch self {
            case .epochActive: return .epochActive
            case .epochEnding: return .timer
            case .presenceValidated: return .presenceValidated
            case .newPeer: return .participants
            case .system: return .info
            }
        }

        var color: Color {
            switch self {
            case .epochActive: return Theme.Colors.epochActive
            case .epochEnding: return Theme.Colors.warning
            case .presenceValidated: return Theme.Colors.success
            case .newPeer: return Theme.Colors.primaryFallback
            case .system: return Theme.Colors.info
            }
        }
    }

    static var sampleNotifications: [NotificationItem] {
        [
            NotificationItem(
                type: .epochActive,
                title: "Epoch Now Active",
                message: "\"Downtown Meetup\" has started! Join now to participate.",
                timestamp: Date().addingTimeInterval(-300),
                isRead: false
            ),
            NotificationItem(
                type: .presenceValidated,
                title: "Presence Validated",
                message: "Your presence at \"Coffee Shop Hangout\" was validated by 5 peers.",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            NotificationItem(
                type: .newPeer,
                title: "New Peer Nearby",
                message: "3 new users joined the 7ay-presence network near you.",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true
            ),
            NotificationItem(
                type: .epochEnding,
                title: "Epoch Ending Soon",
                message: "\"Park Festival\" ends in 15 minutes. Finalize your presence!",
                timestamp: Date().addingTimeInterval(-10800),
                isRead: true
            )
        ]
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: NotificationItem
    let animationDelay: Double
    let onDismiss: () -> Void

    @State private var hasAppeared = false
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0

    init(notification: NotificationItem, animationDelay: Double = 0, onDismiss: @escaping () -> Void) {
        self.notification = notification
        self.animationDelay = animationDelay
        self.onDismiss = onDismiss
    }

    var body: some View {
        Button {
            triggerTapAnimation()
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(notification.type.color.opacity(0.12))
                        .frame(width: 40, height: 40)

                    IconView(notification.type.icon, size: .sm, color: notification.type.color)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top) {
                        Text(notification.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(timeAgo(notification.timestamp))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    Text(notification.message)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // Unread dot
                if !notification.isRead {
                    Circle()
                        .fill(Theme.Colors.primaryFallback)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }
            .padding(Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        notification.isRead
                            ? Color.white.opacity(0.1)
                            : notification.type.color.opacity(0.25),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(AnimatedButtonStyle())
        .opacity(hasAppeared ? 1 : 0)
        .offset(x: hasAppeared ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(animationDelay)) {
                hasAppeared = true
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDismiss()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func triggerTapAnimation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            iconScale = 1.2
            iconRotation = 10
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconRotation = 0
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - Animated Button Style

struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
