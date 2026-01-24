import SwiftUI

// MARK: - Main Tab View

/// Root tab view with minimalist bottom navigation bar
/// Camera button opens camera directly - no gestures
struct MainTabView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var selectedTab: AppTab = .home
    @State private var previousTab: AppTab = .home

    // Composer state
    @State private var showComposer = false

    // Profile sheet state
    @State private var showProfileSheet = false
    @State private var currentUser: User?

    // Capture state
    @State private var showCameraCapture = false
    @State private var showAudioRecord = false
    @State private var pendingCaptureType: CaptureType?
    @State private var capturedMedia: CapturedMedia?

    // Post-capture state
    @State private var showPostCaptureSheet = false
    @State private var showEpochPicker = false
    @State private var epochPickerMode: EpochPickerView.PickerMode = .enterEpoch

    // Settings
    @State private var maxAudioDuration: TimeInterval = 30

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            tabContent
                .ignoresSafeArea()

            // Minimalist tab bar
            AppTabBar(
                selectedTab: $selectedTab,
                onCreateTap: {
                    // Open composer to create Epoch or Lapse
                    showComposer = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showComposer) {
            UnifiedComposerView()
        }
        .fullScreenCover(isPresented: $showCameraCapture) {
            CameraCaptureView(
                captureType: pendingCaptureType ?? .photo,
                onCapture: { media in
                    handleMediaCaptured(media)
                },
                onCancel: {
                    showCameraCapture = false
                    pendingCaptureType = nil
                }
            )
        }
        .sheet(isPresented: $showAudioRecord) {
            AudioRecordView(
                maxDuration: maxAudioDuration,
                onCapture: { media in
                    handleMediaCaptured(media)
                },
                onCancel: {
                    showAudioRecord = false
                    pendingCaptureType = nil
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPostCaptureSheet) {
            if let media = capturedMedia {
                PostCaptureSheet(
                    media: media,
                    onEnterEpoch: {
                        showPostCaptureSheet = false
                        epochPickerMode = .enterEpoch
                        showEpochPicker = true
                    },
                    onSendEphemeral: {
                        showPostCaptureSheet = false
                        epochPickerMode = .sendEphemeral
                        showEpochPicker = true
                    },
                    onCancel: {
                        showPostCaptureSheet = false
                        capturedMedia = nil
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showEpochPicker) {
            EpochPickerView(
                mode: epochPickerMode,
                onSelect: { epochId in
                    handleEpochSelected(epochId)
                },
                onCreateNew: {
                    showEpochPicker = false
                    showComposer = true
                },
                onCancel: {
                    showEpochPicker = false
                }
            )
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .create {
                selectedTab = previousTab
                showComposer = true
            } else if newValue == .profile {
                selectedTab = previousTab
                showProfileSheet = true
            } else {
                previousTab = newValue
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheetView(
                user: currentUser,
                isPresented: $showProfileSheet
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            currentUser = await dependencies.authenticationRepository.currentUser
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .explore:
            ExploreSection()
        case .create:
            // Create opens a sheet, show home as fallback
            HomeView()
        case .journeys:
            JourneysView()
        case .profile:
            // Profile opens a sheet, show home as fallback
            HomeView()
        }
    }

    // MARK: - Handlers

    private func handleMediaCaptured(_ media: CapturedMedia) {
        // Close capture views
        showCameraCapture = false
        showAudioRecord = false
        pendingCaptureType = nil

        // Store media and show post-capture options
        capturedMedia = media

        // Small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showPostCaptureSheet = true
        }
    }

    private func handleEpochSelected(_ epochId: UInt64) {
        showEpochPicker = false

        // Handle based on mode
        switch epochPickerMode {
        case .enterEpoch:
            // Enter the epoch with media
            if capturedMedia != nil {
                coordinator.enterActiveEpoch(epochId: epochId)
                // TODO: Attach media to presence
            }
        case .sendEphemeral:
            // Send ephemeral message
            if capturedMedia != nil {
                // TODO: Send media as ephemeral message
            }
        }

        capturedMedia = nil
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

                Spacer(minLength: 100)
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
