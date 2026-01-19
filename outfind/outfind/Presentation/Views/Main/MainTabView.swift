

import SwiftUI

// MARK: - Main Tab View

/// Root tab view with bottom navigation bar
/// Structure inspired by modern social apps (image #8)
struct MainTabView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var selectedTab: Tab = .home
    @State private var showCreateEpoch = false
    @State private var showRadialMenu = false
    @State private var previousTab: Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content - hide default tab bar completely
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                ExploreSection()
                    .tag(Tab.explore)

                // Placeholder for create (handled by radial menu)
                Color.clear
                    .tag(Tab.create)

                MessagesListView()
                    .tag(Tab.messages)

                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Custom tab bar (hidden when radial menu is shown)
            if !showRadialMenu {
                CustomTabBar(
                    selectedTab: $selectedTab,
                    onCreateTap: {
                        showRadialMenu = true
                    },
                    onCreateLongPress: {
                        showRadialMenu = true
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Radial menu overlay
            if showRadialMenu {
                RadialMenuView(
                    onComplete: { epochData in
                        handleEpochCreation(epochData)
                    },
                    onDismiss: {
                        showRadialMenu = false
                    }
                )
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showCreateEpoch) {
            CreateEpochView()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .create {
                // Reset to previous tab and show radial menu
                selectedTab = oldValue
                previousTab = oldValue
                showRadialMenu = true
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showRadialMenu)
    }

    // MARK: - Epoch Creation Handler

    private func handleEpochCreation(_ data: EpochCreationData) {
        // For now, show the full CreateEpochView with pre-filled data
        // In a full implementation, this could create the epoch directly
        showCreateEpoch = true
    }
}

// MARK: - Tab Enum

extension MainTabView {
    enum Tab: Int, CaseIterable {
        case home
        case explore
        case create
        case messages
        case profile

        var icon: AppIcon {
            switch self {
            case .home: return .epoch
            case .explore: return .search
            case .create: return .addCircle
            case .messages: return .signals
            case .profile: return .presence
            }
        }

        var selectedIcon: AppIcon {
            switch self {
            case .home: return .epochActive
            case .explore: return .search
            case .create: return .addCircle
            case .messages: return .signals
            case .profile: return .presenceValidated
            }
        }

        /// SF Symbol icon name - unique Outfind style
        var systemIcon: String {
            switch self {
            case .home: return "circle.hexagongrid.fill"
            case .explore: return "sparkle.magnifyingglass"
            case .create: return "plus.viewfinder"
            case .messages: return "bubble.left.and.bubble.right.fill"
            case .profile: return "person.crop.circle.badge.checkmark"
            }
        }

        var title: String {
            switch self {
            case .home: return "Epochs"
            case .explore: return "Discover"
            case .create: return ""
            case .messages: return "Signals"
            case .profile: return "Presence"
            }
        }
    }
}

// MARK: - Custom Tab Bar (Minimal Design)

private struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let onCreateTap: () -> Void
    var onCreateLongPress: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.rawValue) { tab in
                if tab == .create {
                    createButton
                } else {
                    tabButton(for: tab)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }

    private func tabButton(for tab: MainTabView.Tab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: tab.systemIcon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))

            Text(tab.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = tab
        }
    }

    private var createButton: some View {
        ZStack {
            // Green gradient circle button
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.liveGreen, Theme.Colors.primaryFallback],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)

            // Plus viewfinder icon
            Image(systemName: "plus.viewfinder")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: Theme.Colors.liveGreen.opacity(0.4), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Circle())
        .onTapGesture {
            onCreateTap()
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            if let longPress = onCreateLongPress {
                longPress()
            } else {
                onCreateTap()
            }
        }
    }
}

// MARK: - Tab Button Style

private struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Create Button Style

private struct CreateButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.coordinator) private var coordinator

    @State private var currentUser: User?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let user = currentUser {
                profileContent(user)
            } else {
                notConnectedView
            }
        }
        .task {
            isLoading = true
            currentUser = await dependencies.authenticationRepository.currentUser
            isLoading = false
        }
    }

    private func profileContent(_ user: User) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Profile header
                VStack(spacing: Theme.Spacing.md) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primaryFallback.opacity(0.15))
                            .frame(width: 100, height: 100)

                        if let avatarURL = user.avatarURL {
                            AsyncImage(url: avatarURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                IconView(user.authMethod.isWallet ? .wallet : .google, size: .xxl, color: Theme.Colors.primaryFallback)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            IconView(user.authMethod.isWallet ? .wallet : .google, size: .xxl, color: Theme.Colors.primaryFallback)
                        }
                    }

                    // Name
                    VStack(spacing: Theme.Spacing.xxs) {
                        if let displayName = user.displayName {
                            Text(displayName)
                                .font(Typography.headlineMedium)
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }

                        Text(user.displayIdentifier)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // Auth badge
                    HStack(spacing: Theme.Spacing.xxs) {
                        IconView(user.authMethod.isWallet ? .wallet : .google, size: .xs, color: Theme.Colors.primaryFallback)
                        Text(user.authMethod.isWallet ? "Wallet" : "Google")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    }
                }
                .padding(.top, Theme.Spacing.xxl)

                // Stats
                HStack(spacing: Theme.Spacing.lg) {
                    statItem(value: "0", label: "Epochs")
                    statItem(value: "0", label: "Validated")
                    statItem(value: "0", label: "Points")
                }
                .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)

                // Settings section
                VStack(spacing: Theme.Spacing.sm) {
                    settingsRow(icon: .settings, title: "Settings")
                    settingsRow(icon: .shield, title: "Privacy")
                    settingsRow(icon: .info, title: "About")
                }
                .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg, padding: Theme.Spacing.sm)

                // Disconnect button
                Button {
                    disconnect()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
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
                .padding(.top, Theme.Spacing.lg)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text(value)
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func settingsRow(icon: AppIcon, title: String) -> some View {
        Button {
            // TODO: Navigate to settings
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                IconView(icon, size: .md, color: Theme.Colors.textSecondary)

                Text(title)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.sm)
        }
    }

    private var notConnectedView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            LiquidGlassOrb(size: 80, color: Theme.Colors.textTertiary)
                .overlay {
                    IconView(.presence, size: .xl, color: Theme.Colors.textTertiary)
                }

            Text("Not Connected")
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Connect your wallet to view your profile")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func disconnect() {
        Task {
            try? await dependencies.authenticationRepository.disconnect()
            await MainActor.run {
                coordinator.handleWalletDisconnected()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
