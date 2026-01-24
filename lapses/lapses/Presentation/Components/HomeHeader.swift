import SwiftUI

// MARK: - Home Header

/// Minimal header with centered logo and action buttons.
struct HomeHeader: View {
    var notificationCount: Int = 0
    var onNotificationsTap: () -> Void = {}
    var onMessagesTap: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            // Logo on the left
            appLogo
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

            Spacer()

            // Action Buttons (right)
            actionButtons
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 20)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }

    // MARK: - App Logo

    private var appLogo: some View {
        Image(colorScheme == .dark ? "lapses_light_icon" : "lapses_dark_icon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 60)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Notifications
            HeaderActionButton(
                icon: "bell",
                badgeCount: notificationCount,
                action: onNotificationsTap
            )

            // Messages
            HeaderActionButton(
                icon: "bubble.right",
                badgeCount: 0,
                action: onMessagesTap
            )
        }
    }
}

// MARK: - Header Action Button

private struct HeaderActionButton: View {
    let icon: String
    let badgeCount: Int
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 28, height: 28)

                if badgeCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.error)
                            .frame(width: 16, height: 16)

                        Text(badgeCount > 9 ? "9+" : "\(badgeCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .offset(x: 6, y: -4)
                }
            }
        }
        .buttonStyle(HeaderButtonStyle())
    }
}

// MARK: - Profile Sidebar View

struct ProfileSidebarView: View {
    let user: User?
    @Binding var isPresented: Bool
    var lapsesCount: Int = 0
    var epochsCount: Int = 0
    var journeysCount: Int = 0

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile header with gradient
                    profileHeaderCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Activity Stats Cards
                    activityStatsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)

                    // Menu sections
                    VStack(spacing: 8) {
                        // Activity section
                        menuCard {
                            ProfileMenuItem(icon: "clock.arrow.circlepath", title: "Your Lapses", badge: lapsesCount > 0 ? "\(lapsesCount)" : nil, color: Theme.Colors.primaryFallback) {}
                            ProfileMenuItem(icon: "circle.hexagongrid", title: "Your Epochs", badge: epochsCount > 0 ? "\(epochsCount)" : nil, color: Theme.Colors.epochActive) {}
                            ProfileMenuItem(icon: "point.3.connected.trianglepath.dotted", title: "Your Journeys", badge: journeysCount > 0 ? "\(journeysCount)" : nil, color: Theme.Colors.epochScheduled) {}
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 40)

                        // Wallet section
                        menuCard {
                            ProfileMenuItem(
                                icon: "wallet.pass.fill",
                                title: "Connected Wallet",
                                subtitle: user?.protocolAddress.map { String($0.hex.prefix(10)) + "..." },
                                color: Theme.Colors.primaryFallback
                            ) {}
                            ProfileMenuItem(icon: "arrow.left.arrow.right", title: "Transactions", color: Theme.Colors.textSecondary) {}
                            ProfileMenuItem(icon: "creditcard", title: "Rewards", subtitle: "0 LAPSE", color: Theme.Colors.warning) {}
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 50)

                        // Settings section
                        menuCard {
                            ProfileMenuItem(icon: "bell.badge.fill", title: "Notifications", color: Theme.Colors.info) {}
                            ProfileMenuItem(icon: "hand.raised.fill", title: "Privacy & Security", color: Theme.Colors.error) {}
                            ProfileMenuItem(icon: "moon.fill", title: "Appearance", subtitle: colorScheme == .dark ? "Dark" : "Light", color: Theme.Colors.textSecondary) {}
                            ProfileMenuItem(icon: "questionmark.circle.fill", title: "Help Center", color: Theme.Colors.textTertiary) {}
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 60)

                        // Danger zone
                        menuCard {
                            ProfileMenuItem(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: Theme.Colors.error, isDestructive: true) {}
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 70)
                    }
                    .padding(.horizontal, 20)

                    // Version info
                    Text("Lapses v1.0.0")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.top, 32)
                        .padding(.bottom, 20)
                        .opacity(appeared ? 1 : 0)
                }
                .padding(.top, 16)
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 28, height: 28)
                            .background {
                                Circle()
                                    .fill(Theme.Colors.backgroundSecondary)
                            }
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Profile Header Card

    private var profileHeaderCard: some View {
        VStack(spacing: 16) {
            // Avatar with ring
            ZStack {
                // Animated ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback,
                                Theme.Colors.epochActive,
                                Theme.Colors.epochScheduled,
                                Theme.Colors.primaryFallback
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 96, height: 96)

                // Avatar background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback,
                                Theme.Colors.primaryFallback.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 86, height: 86)

                // Avatar image or placeholder
                if let avatarURL = user?.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 38, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 82, height: 82)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.white)
                }
            }

            // Name and handle
            VStack(spacing: 4) {
                Text(user?.displayName ?? "Guest")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let displayName = user?.displayName {
                    Text("@\(displayName.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            // Wallet badge
            if let address = user?.protocolAddress {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.epochActive)
                        .frame(width: 8, height: 8)

                    Text(String(address.hex.prefix(6)) + "..." + String(address.hex.suffix(4)))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Theme.Colors.backgroundSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "FAFAFA"),
                            colorScheme == .dark ? Color(hex: "2C2C2E") : .white
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 20, y: 10)
        }
    }

    // MARK: - Activity Stats Section

    private var activityStatsSection: some View {
        HStack(spacing: 12) {
            ActivityStatCard(
                icon: "clock.arrow.circlepath",
                value: lapsesCount,
                label: "Lapses",
                color: Theme.Colors.primaryFallback
            )

            ActivityStatCard(
                icon: "circle.hexagongrid",
                value: epochsCount,
                label: "Epochs",
                color: Theme.Colors.epochActive
            )

            ActivityStatCard(
                icon: "point.3.connected.trianglepath.dotted",
                value: journeysCount,
                label: "Journeys",
                color: Theme.Colors.epochScheduled
            )
        }
    }

    // MARK: - Menu Card

    @ViewBuilder
    private func menuCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : .white)
                .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        }
    }
}

// MARK: - Activity Stat Card

private struct ActivityStatCard: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            // Value
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())

            // Label
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1C1C1E") : .white)
                .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Profile Menu Item

private struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    let color: Color
    var isDestructive: Bool = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 14) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDestructive ? Theme.Colors.error.opacity(0.1) : color.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isDestructive ? Theme.Colors.error : color)
                }

                // Title and subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isDestructive ? Theme.Colors.error : Theme.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule()
                                .fill(color)
                        }
                }

                // Chevron
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiary.opacity(0.5))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Theme.Colors.backgroundSecondary : .clear)
            }
        }
        .buttonStyle(ProfileMenuButtonStyle())
    }
}

// MARK: - Profile Menu Button Style

private struct ProfileMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Logo Button Style

struct LogoButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Header Button Style

struct HeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Header") {
    VStack {
        HomeHeader(notificationCount: 5)

        Spacer()
    }
    .background(Theme.Colors.background)
}

#Preview("Profile Sidebar") {
    ProfileSidebarView(
        user: User.mockWallet,
        isPresented: .constant(true),
        lapsesCount: 12,
        epochsCount: 5,
        journeysCount: 3
    )
}

#Preview("Profile Sidebar Dark") {
    ProfileSidebarView(
        user: User.mockWallet,
        isPresented: .constant(true),
        lapsesCount: 8,
        epochsCount: 3,
        journeysCount: 2
    )
    .preferredColorScheme(.dark)
}

#Preview("Dark Mode") {
    VStack {
        HomeHeader(notificationCount: 3)

        Spacer()
    }
    .background(Theme.Colors.background)
    .preferredColorScheme(.dark)
}
