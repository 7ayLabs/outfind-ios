import SwiftUI
import Combine

// MARK: - Active Epoch View

struct ActiveEpochView: View {
    let epochId: UInt64

    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epoch: Epoch?
    @State private var presence: Presence?
    @State private var isLoading = true
    @State private var selectedTab: EpochTab = .info
    @State private var timeRemaining: TimeInterval = 0
    @State private var showLeaveConfirmation = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            if isLoading {
                loadingView
            } else if let epoch = epoch {
                epochContentView(epoch)
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton {
                    coordinator.pop()
                }
            }

            ToolbarItem(placement: .principal) {
                timerHeader
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Label("Leave Epoch", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    IconView(.more, size: .md, color: Theme.Colors.textPrimary)
                }
            }
        }
        .swipeBack {
            coordinator.pop()
        }
        .confirmationDialog(
            "Leave Epoch?",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) {
                coordinator.pop()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can rejoin this epoch while it's still active.")
        }
        .task {
            await loadEpochData()
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let epoch = epoch {
                EpochStateIcon(epoch.state, size: .sm)

                Text(formatTime(timeRemaining))
                    .font(Typography.timerSmall)
                    .foregroundStyle(timerColor)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xxs)
        .frostedGlass(style: .ultraThin, cornerRadius: Theme.CornerRadius.full)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading epoch...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        EmptyStateCard(
            icon: .warning,
            title: "Epoch Ended",
            message: "This epoch has closed and all ephemeral data has been purged",
            actionTitle: "Return to Explore"
        ) {
            coordinator.popToRoot()
        }
    }

    // MARK: - Epoch Content

    private func epochContentView(_ epoch: Epoch) -> some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar

            // Tab content
            TabView(selection: $selectedTab) {
                ForEach(EpochTab.allCases, id: \.self) { tab in
                    tabContent(for: tab, epoch: epoch)
                        .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isEnabled: isTabEnabled(tab)
                ) {
                    withAnimation(Theme.Animation.quick) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
        }
    }

    private var availableTabs: [EpochTab] {
        guard let epoch = epoch else { return [.info] }

        var tabs: [EpochTab] = [.info, .participants]

        if epoch.capability.supportsDiscovery {
            tabs.append(.discover)
        }

        // Chat and Media tabs available but may be locked
        tabs.append(.chat)

        if epoch.capability.supportsMedia {
            tabs.append(.media)
        }

        return tabs
    }

    private func isTabEnabled(_ tab: EpochTab) -> Bool {
        guard let epoch = epoch else { return false }

        switch tab {
        case .info, .participants:
            return true
        case .discover, .chat:
            return epoch.capability.supportsDiscovery
        case .media:
            return epoch.capability.supportsMedia
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for tab: EpochTab, epoch: Epoch) -> some View {
        switch tab {
        case .info:
            EpochInfoTab(epoch: epoch, presence: presence)
        case .participants:
            ParticipantsTab(epochId: epochId)
        case .discover:
            DiscoverTab(epoch: epoch, isEnabled: epoch.capability.supportsDiscovery)
        case .chat:
            ChatTab(epoch: epoch, isEnabled: epoch.capability.supportsMessaging)
        case .media:
            MediaTab(epoch: epoch, isEnabled: epoch.capability.supportsMedia)
        }
    }

    // MARK: - Helper Methods

    private func loadEpochData() async {
        isLoading = true
        do {
            let fetchedEpoch = try await dependencies.epochRepository.fetchEpoch(id: epochId)

            // Check if epoch is still active
            guard fetchedEpoch.state == .active else {
                await MainActor.run {
                    epoch = nil
                    isLoading = false
                }
                return
            }

            await MainActor.run {
                epoch = fetchedEpoch
                timeRemaining = fetchedEpoch.timeUntilNextPhase
                isLoading = false
            }

            // Load presence
            if let wallet = await dependencies.walletRepository.currentWallet {
                let existingPresence = try? await dependencies.presenceRepository.fetchPresence(
                    actor: wallet.address,
                    epochId: epochId
                )
                await MainActor.run {
                    presence = existingPresence
                }
            }

            // Activate epoch in lifecycle manager
            await dependencies.epochLifecycleManager.activateEpoch(fetchedEpoch)

        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func updateTimer() {
        guard let epoch = epoch else { return }
        timeRemaining = epoch.timeUntilNextPhase

        // Check if epoch ended
        if timeRemaining <= 0 {
            Task {
                await loadEpochData()
            }
        }
    }

    private var timerColor: Color {
        if timeRemaining < 60 {
            return Theme.Colors.error
        } else if timeRemaining < 300 {
            return Theme.Colors.warning
        }
        return Theme.Colors.textPrimary
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Epoch Tab

enum EpochTab: String, CaseIterable {
    case info
    case participants
    case discover
    case chat
    case media

    var title: String {
        switch self {
        case .info: return "Info"
        case .participants: return "People"
        case .discover: return "Discover"
        case .chat: return "Chat"
        case .media: return "Media"
        }
    }

    var icon: AppIcon {
        switch self {
        case .info: return .info
        case .participants: return .participants
        case .discover: return .radar
        case .chat: return .signals
        case .media: return .media
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: EpochTab
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xxs) {
                IconView(
                    tab.icon,
                    size: .md,
                    color: isSelected ? Theme.Colors.primaryFallback : (isEnabled ? Theme.Colors.textSecondary : Theme.Colors.textTertiary)
                )

                Text(tab.title)
                    .font(Typography.labelSmall)
                    .foregroundStyle(isSelected ? Theme.Colors.primaryFallback : (isEnabled ? Theme.Colors.textSecondary : Theme.Colors.textTertiary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.Colors.primaryFallback.opacity(0.15))
                }
            }
        }
        .disabled(!isEnabled)
        .overlay {
            if !isEnabled {
                IconView(.lock, size: .xs, color: Theme.Colors.textTertiary)
                    .offset(x: 20, y: -10)
            }
        }
    }
}

// MARK: - Tab Views

private struct EpochInfoTab: View {
    let epoch: Epoch
    let presence: Presence?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Presence status
                if let presence = presence {
                    PresenceStatusCard(presence: presence)
                }

                // Epoch info
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(epoch.title)
                        .font(Typography.headlineMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if let description = epoch.description {
                        Text(description)
                            .font(Typography.bodyLarge)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)

                // Stats
                HStack(spacing: Theme.Spacing.md) {
                    InfoCard(
                        title: "Participants",
                        value: "\(epoch.participantCount)",
                        icon: .participants
                    )

                    InfoCard(
                        title: "Capability",
                        value: epoch.capability.shortName,
                        icon: .sparkle,
                        color: Theme.Colors.epochActive
                    )
                }
            }
            .padding()
        }
    }
}

private struct PresenceStatusCard: View {
    let presence: Presence

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            PresenceStateIcon(presence.state, size: .xl)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Your Presence")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text(presence.state.displayName)
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                if presence.state == .declared {
                    Text("Awaiting validation (\(presence.validationCount)/3)")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.warning)
                }
            }

            Spacer()
        }
        .glassCard(style: .regular, cornerRadius: Theme.CornerRadius.lg)
    }
}

private struct ParticipantsTab: View {
    let epochId: UInt64

    var body: some View {
        VStack {
            EmptyStateCard(
                icon: .participants,
                title: "Participants",
                message: "View who else is in this epoch"
            )
        }
    }
}

private struct DiscoverTab: View {
    let epoch: Epoch
    let isEnabled: Bool

    var body: some View {
        if isEnabled {
            VStack {
                EmptyStateCard(
                    icon: .radar,
                    title: "Discovery",
                    message: "Find nearby participants in this epoch"
                )
            }
        } else {
            lockedView
        }
    }

    private var lockedView: some View {
        VStack {
            EmptyStateCard(
                icon: .lock,
                title: "Discovery Locked",
                message: "This epoch doesn't support discovery features"
            )
        }
    }
}

private struct ChatTab: View {
    let epoch: Epoch
    let isEnabled: Bool

    var body: some View {
        if isEnabled {
            VStack {
                EmptyStateCard(
                    icon: .signals,
                    title: "Chat",
                    message: "Send ephemeral messages to epoch participants"
                )
            }
        } else {
            lockedView
        }
    }

    private var lockedView: some View {
        VStack {
            EmptyStateCard(
                icon: .lock,
                title: "Chat Locked",
                message: "This epoch doesn't support messaging"
            )
        }
    }
}

private struct MediaTab: View {
    let epoch: Epoch
    let isEnabled: Bool

    var body: some View {
        if isEnabled {
            VStack {
                EmptyStateCard(
                    icon: .media,
                    title: "Ephemeral Media",
                    message: "Capture and share photos that disappear when the epoch ends"
                )
            }
        } else {
            lockedView
        }
    }

    private var lockedView: some View {
        VStack {
            EmptyStateCard(
                icon: .lock,
                title: "Media Locked",
                message: "This epoch doesn't support ephemeral media"
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActiveEpochView(epochId: 1)
    }
    .environment(\.dependencies, .shared)
    .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
