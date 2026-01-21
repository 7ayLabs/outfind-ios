import SwiftUI

// MARK: - Home Header

/// Header component for the home view with user avatar, ephemeral stats, and action buttons.
/// Layout: [Avatar] [Stats] ----spacer---- [Notifications] [Messages]
struct HomeHeader: View {
    let user: User?
    var ephemeralCount: Int = 0
    var pinnedCount: Int = 0
    var notificationCount: Int = 0
    var onAvatarTap: () -> Void = {}
    var onNotificationsTap: () -> Void = {}
    var onMessagesTap: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
    @State private var statsAppeared = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // User Avatar
            avatarButton

            // Ephemeral Stats
            if ephemeralCount > 0 || pinnedCount > 0 {
                ephemeralStatsView
                    .opacity(statsAppeared ? 1 : 0)
                    .offset(x: statsAppeared ? 0 : -10)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: Theme.Spacing.xs) {
                notificationButton
                messagesButton
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                statsAppeared = true
            }
        }
    }

    // MARK: - Ephemeral Stats View

    private var ephemeralStatsView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Ephemeral count
            if ephemeralCount > 0 {
                HStack(spacing: 6) {
                    // Pulsing dot
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.epochActive.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .scaleEffect(statsAppeared ? 1.3 : 1.0)
                            .opacity(statsAppeared ? 0 : 1)
                            .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: statsAppeared)

                        Circle()
                            .fill(Theme.Colors.epochActive)
                            .frame(width: 6, height: 6)
                    }

                    Text("\(ephemeralCount)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .contentTransition(.numericText())

                    Text("live")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(colorScheme == .dark
                              ? Theme.Colors.epochActive.opacity(0.15)
                              : Theme.Colors.epochActive.opacity(0.1))
                        .overlay {
                            Capsule()
                                .strokeBorder(Theme.Colors.epochActive.opacity(0.3), lineWidth: 1)
                        }
                }
            }

            // Pinned count
            if pinnedCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.Colors.epochScheduled)

                    Text("\(pinnedCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.epochScheduled)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(colorScheme == .dark
                              ? Theme.Colors.epochScheduled.opacity(0.15)
                              : Theme.Colors.epochScheduled.opacity(0.1))
                        .overlay {
                            Capsule()
                                .strokeBorder(Theme.Colors.epochScheduled.opacity(0.3), lineWidth: 1)
                        }
                }
            }
        }
    }

    // MARK: - Avatar Button

    private var avatarButton: some View {
        Button(action: onAvatarTap) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 40, height: 40)

                if let avatarURL = user?.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        userInitialsView
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    userInitialsView
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var userInitialsView: some View {
        Group {
            if let displayName = user?.displayName, let firstChar = displayName.first {
                Text(String(firstChar).uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
        }
    }

    // MARK: - Notification Button

    private var notificationButton: some View {
        Button(action: onNotificationsTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(Theme.Colors.backgroundSecondary)
                    }

                // Notification badge
                if notificationCount > 0 {
                    Circle()
                        .fill(Theme.Colors.error)
                        .frame(width: 8, height: 8)
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Messages Button

    private var messagesButton: some View {
        Button(action: onMessagesTap) {
            Image(systemName: "message")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.backgroundSecondary)
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview("With Stats") {
    VStack {
        HomeHeader(
            user: User.mockWallet,
            ephemeralCount: 12,
            pinnedCount: 3,
            notificationCount: 5,
            onAvatarTap: { print("Avatar tapped") },
            onNotificationsTap: { print("Notifications tapped") },
            onMessagesTap: { print("Messages tapped") }
        )

        Spacer()
    }
    .background(Theme.Colors.background)
}

#Preview("Dark Mode") {
    VStack {
        HomeHeader(
            user: User.mockWallet,
            ephemeralCount: 8,
            pinnedCount: 2,
            notificationCount: 3
        )

        Spacer()
    }
    .background(Theme.Colors.background)
    .preferredColorScheme(.dark)
}

#Preview("No Stats") {
    VStack {
        HomeHeader(
            user: nil,
            notificationCount: 0
        )

        Spacer()
    }
    .background(Theme.Colors.background)
}
