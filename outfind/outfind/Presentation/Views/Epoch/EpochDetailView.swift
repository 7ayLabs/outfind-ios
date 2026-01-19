import SwiftUI
import Combine

// MARK: - Epoch Detail View

struct EpochDetailView: View {
    let epochId: UInt64

    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epoch: Epoch?
    @State private var presence: Presence?
    @State private var isLoading = true
    @State private var isJoining = false
    @State private var error: String?
    @State private var showError = false
    @State private var timeRemaining: TimeInterval = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()

            // Content
            Group {
                if isLoading {
                    loadingView
                } else if let epoch = epoch {
                    epochContentView(epoch)
                } else {
                    errorView
                }
            }
            .padding(.top, 56) // Space for custom header

            // Custom navigation header (always visible)
            customNavigationHeader
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe back gesture (left to right)
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        coordinator.pop()
                    }
                }
        )
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "Something went wrong")
        }
        .task {
            await loadEpoch()
        }
        .onReceive(timer) { _ in
            if let epoch = epoch {
                timeRemaining = epoch.timeUntilNextPhase
            }
        }
    }

    // MARK: - Custom Navigation Header

    private var customNavigationHeader: some View {
        HStack {
            // Back button
            Button {
                coordinator.pop()
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Back")
                        .font(Typography.bodyMedium)
                }
                .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer()

            // Share button
            if epoch != nil {
                Button {
                    // TODO: Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
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
            title: "Epoch Not Found",
            message: "This epoch may have been finalized or doesn't exist",
            actionTitle: "Go Back"
        ) {
            coordinator.pop()
        }
    }

    // MARK: - Epoch Content

    private func epochContentView(_ epoch: Epoch) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Hero section
                heroSection(epoch)

                // Timer section
                if epoch.state == .active || epoch.state == .scheduled {
                    timerSection(epoch)
                }

                // Info cards
                infoCardsSection(epoch)

                // Capability section
                capabilitySection(epoch)

                // Action button
                actionSection(epoch)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Hero Section

    private func heroSection(_ epoch: Epoch) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            // State badge
            HStack {
                EpochStateIcon(epoch.state, size: .lg)
                Text(epoch.state.displayName)
                    .font(Typography.titleMedium)
                    .foregroundStyle(stateColor(for: epoch.state))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.full)

            // Title
            Text(epoch.title)
                .font(Typography.headlineLarge)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            // Description
            if let description = epoch.description {
                Text(description)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Timer Section

    private func timerSection(_ epoch: Epoch) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(epoch.state == .active ? "Time Remaining" : "Starts In")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(formatTime(timeRemaining))
                .font(Typography.timer)
                .foregroundStyle(Theme.Colors.textPrimary)
                .monospacedDigit()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.backgroundTertiary)
                        .frame(height: 8)

                    Capsule()
                        .fill(stateColor(for: epoch.state))
                        .frame(width: geometry.size.width * progressValue(epoch), height: 8)
                        .animation(Theme.Animation.smooth, value: timeRemaining)
                }
            }
            .frame(height: 8)
        }
        .glassCard(style: .regular, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Info Cards

    private func infoCardsSection(_ epoch: Epoch) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            InfoCard(
                title: "Participants",
                value: "\(epoch.participantCount)",
                icon: .participants,
                color: Theme.Colors.primaryFallback
            )

            InfoCard(
                title: "Capability",
                value: epoch.capability.shortName,
                icon: capabilityIcon(epoch.capability),
                color: Theme.Colors.epochActive
            )
        }
    }

    // MARK: - Capability Section

    private func capabilitySection(_ epoch: Epoch) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Features")
                .font(Typography.titleSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.xs) {
                FeatureRow(
                    icon: .presence,
                    title: "Presence Declaration",
                    isEnabled: true
                )

                FeatureRow(
                    icon: .signals,
                    title: "Discovery & Messaging",
                    isEnabled: epoch.capability.supportsDiscovery
                )

                FeatureRow(
                    icon: .media,
                    title: "Ephemeral Media",
                    isEnabled: epoch.capability.supportsMedia
                )
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Action Section

    private func actionSection(_ epoch: Epoch) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            if presence != nil {
                // Already joined
                StatusCard(
                    title: "Presence Declared",
                    message: "You have already joined this epoch",
                    status: .success
                ) {
                    coordinator.enterActiveEpoch(epochId: epoch.id)
                }

                PrimaryButton("Enter Epoch", icon: .forward) {
                    coordinator.enterActiveEpoch(epochId: epoch.id)
                }
            } else if epoch.state.isJoinable {
                // Can join
                PrimaryButton(
                    "Join Epoch",
                    icon: .presence,
                    isLoading: isJoining
                ) {
                    joinEpoch()
                }

                Text("Joining will declare your presence on-chain")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            } else {
                // Cannot join
                StatusCard(
                    title: "Epoch \(epoch.state.displayName)",
                    message: "This epoch is no longer accepting participants",
                    status: .info
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func loadEpoch() async {
        isLoading = true
        do {
            let fetchedEpoch = try await dependencies.epochRepository.fetchEpoch(id: epochId)
            await MainActor.run {
                epoch = fetchedEpoch
                timeRemaining = fetchedEpoch.timeUntilNextPhase
                isLoading = false
            }

            // Check if user has presence
            if let wallet = await dependencies.walletRepository.currentWallet {
                let existingPresence = try? await dependencies.presenceRepository.fetchPresence(
                    actor: wallet.address,
                    epochId: epochId
                )
                await MainActor.run {
                    presence = existingPresence
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error.localizedDescription
                showError = true
            }
        }
    }

    private func joinEpoch() {
        isJoining = true
        Task {
            do {
                let newPresence = try await dependencies.presenceRepository.declarePresence(
                    epochId: epochId,
                    stake: nil
                )
                await MainActor.run {
                    presence = newPresence
                    isJoining = false
                    coordinator.enterActiveEpoch(epochId: epochId)
                }
            } catch {
                await MainActor.run {
                    isJoining = false
                    self.error = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func stateColor(for state: EpochState) -> Color {
        switch state {
        case .none: return Theme.Colors.textTertiary
        case .scheduled: return Theme.Colors.epochScheduled
        case .active: return Theme.Colors.epochActive
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        }
    }

    private func progressValue(_ epoch: Epoch) -> CGFloat {
        let total = epoch.endTime.timeIntervalSince(epoch.startTime)
        let remaining = timeRemaining
        return max(0, min(1, CGFloat(1 - remaining / total)))
    }

    private func capabilityIcon(_ capability: EpochCapability) -> AppIcon {
        switch capability {
        case .presenceOnly: return .presence
        case .presenceWithSignals: return .signals
        case .presenceWithEphemeralData: return .media
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: AppIcon
    let title: String
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            IconView(icon, size: .md, color: isEnabled ? Theme.Colors.success : Theme.Colors.textTertiary)

            Text(title)
                .font(Typography.bodyMedium)
                .foregroundStyle(isEnabled ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)

            Spacer()

            if isEnabled {
                IconView(.checkmark, size: .sm, color: Theme.Colors.success)
            } else {
                IconView(.lock, size: .sm, color: Theme.Colors.textTertiary)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Capability Extension

extension EpochCapability {
    var shortName: String {
        switch self {
        case .presenceOnly: return "Basic"
        case .presenceWithSignals: return "Social"
        case .presenceWithEphemeralData: return "Full"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EpochDetailView(epochId: 1)
    }
    .environment(\.dependencies, .shared)
    .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
