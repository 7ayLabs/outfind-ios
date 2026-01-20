import SwiftUI

// MARK: - Echo Avatar View

/// Displays a ghostly avatar for users who have left an epoch
/// Features:
/// - Semi-transparent based on time since departure (24h decay)
/// - Subtle shimmer/pulse animation
/// - Ghost icon overlay
/// - "Left X hours ago" label
struct EchoAvatarView: View {
    let presence: Presence
    let size: CGFloat
    let showLabel: Bool

    @State private var shimmerPhase: CGFloat = 0

    init(presence: Presence, size: CGFloat = 60, showLabel: Bool = true) {
        self.presence = presence
        self.size = size
        self.showLabel = showLabel
    }

    private var opacity: Double {
        presence.echoOpacity
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Avatar with ghost effect
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback.opacity(0.3 * opacity),
                                Theme.Colors.primaryFallback.opacity(0.1 * opacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size + 8, height: size + 8)
                    .blur(radius: 2)

                // Avatar placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.backgroundTertiary.opacity(opacity),
                                Theme.Colors.backgroundSecondary.opacity(opacity * 0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay {
                        // Shimmer effect
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.15 * opacity),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(shimmerPhase * 360))
                    }

                // Person icon
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.4, weight: .regular))
                    .foregroundStyle(Theme.Colors.textSecondary.opacity(opacity))

                // Ghost indicator
                Image(systemName: "waveform")
                    .font(.system(size: size * 0.22, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback.opacity(opacity))
                    .offset(x: size * 0.35, y: -size * 0.35)
                    .opacity(shimmerPhase > 0.5 ? 1.0 : 0.6)
            }

            // Time label
            if showLabel, let timeLabel = presence.timeSinceLeft {
                Text(timeLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary.opacity(max(opacity, 0.5)))
            }
        }
        .onAppear {
            startShimmerAnimation()
        }
    }

    private func startShimmerAnimation() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            shimmerPhase = 1.0
        }
    }
}

// MARK: - Echo Avatar Row

/// Horizontal row of echo avatars with overflow indicator
struct EchoAvatarRow: View {
    let echoes: [Presence]
    let maxVisible: Int
    let avatarSize: CGFloat
    let onTap: ((Presence) -> Void)?

    init(
        echoes: [Presence],
        maxVisible: Int = 5,
        avatarSize: CGFloat = 50,
        onTap: ((Presence) -> Void)? = nil
    ) {
        self.echoes = echoes
        self.maxVisible = maxVisible
        self.avatarSize = avatarSize
        self.onTap = onTap
    }

    private var visibleEchoes: [Presence] {
        Array(echoes.prefix(maxVisible))
    }

    private var overflowCount: Int {
        max(0, echoes.count - maxVisible)
    }

    var body: some View {
        HStack(spacing: -avatarSize * 0.2) {
            ForEach(Array(visibleEchoes.enumerated()), id: \.element.id) { index, presence in
                Button {
                    onTap?(presence)
                } label: {
                    EchoAvatarView(presence: presence, size: avatarSize, showLabel: false)
                }
                .buttonStyle(ScaleButtonStyle())
                .zIndex(Double(visibleEchoes.count - index))
            }

            // Overflow indicator
            if overflowCount > 0 {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.backgroundTertiary)
                        .frame(width: avatarSize, height: avatarSize)

                    Text("+\(overflowCount)")
                        .font(.system(size: avatarSize * 0.3, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .zIndex(0)
            }
        }
    }
}

// MARK: - Echoes Section View

/// Complete section for displaying echoes with header and horizontal scroll
struct EchoesSectionView: View {
    let echoes: [Presence]
    let onEchoTap: ((Presence) -> Void)?

    @State private var hasAppeared = false

    init(echoes: [Presence], onEchoTap: ((Presence) -> Void)? = nil) {
        self.echoes = echoes
        self.onEchoTap = onEchoTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback.opacity(0.7))

                Text("Recent Echoes")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("\(echoes.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.backgroundTertiary)
                    }

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Description
            Text("People who were here recently")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.Spacing.md)

            // Horizontal scroll of echoes
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(echoes.enumerated()), id: \.element.id) { index, presence in
                        Button {
                            onEchoTap?(presence)
                        } label: {
                            EchoAvatarView(presence: presence, size: 60, showLabel: true)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 10)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                            value: hasAppeared
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .onAppear {
            hasAppeared = true
        }
    }
}

// MARK: - Preview

#Preview("Echo Avatar") {
    VStack(spacing: Theme.Spacing.lg) {
        Text("Echo Avatars at Different Decay Levels")
            .font(Typography.titleMedium)

        HStack(spacing: Theme.Spacing.md) {
            VStack {
                EchoAvatarView(
                    presence: Presence.mockEcho(epochId: 1, hoursAgo: 0.5),
                    size: 60
                )
                Text("0.5h ago")
                    .font(.caption)
            }

            VStack {
                EchoAvatarView(
                    presence: Presence.mockEcho(epochId: 1, hoursAgo: 6),
                    size: 60
                )
                Text("6h ago")
                    .font(.caption)
            }

            VStack {
                EchoAvatarView(
                    presence: Presence.mockEcho(epochId: 1, hoursAgo: 12),
                    size: 60
                )
                Text("12h ago")
                    .font(.caption)
            }

            VStack {
                EchoAvatarView(
                    presence: Presence.mockEcho(epochId: 1, hoursAgo: 20),
                    size: 60
                )
                Text("20h ago")
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Echoes Section") {
    VStack {
        EchoesSectionView(
            echoes: [
                Presence.mockEcho(epochId: 1, hoursAgo: 0.5),
                Presence.mockEcho(epochId: 1, hoursAgo: 2),
                Presence.mockEcho(epochId: 1, hoursAgo: 5),
                Presence.mockEcho(epochId: 1, hoursAgo: 10),
                Presence.mockEcho(epochId: 1, hoursAgo: 18),
            ]
        ) { presence in
            print("Tapped echo: \(presence.id)")
        }
    }
    .padding(.vertical)
    .background(Theme.Colors.background)
}
