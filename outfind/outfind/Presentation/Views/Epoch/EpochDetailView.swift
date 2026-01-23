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
    @State private var showMintNFTSheet = false
    @State private var showOptionsMenu = false
    @State private var mediaPosts: [MediaPost] = MediaPost.mockPosts
    @State private var showTimeCapsuleCompose = false
    @State private var showTimeCapsuleReveal = false
    @State private var pendingCapsule: TimeCapsule?
    @State private var hasProphecy = false
    @State private var myProphecy: Prophecy?
    @State private var epochProphecies: [Prophecy] = []
    @State private var isCommittingProphecy = false
    @State private var showProphecySheet = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background
                .ignoresSafeArea()

            Group {
                if isLoading {
                    loadingView
                } else if let epoch = epoch {
                    epochContentView(epoch)
                } else {
                    errorView
                }
            }
            .padding(.top, 56)

            customNavigationHeader
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
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
        .sheet(isPresented: $showMintNFTSheet) {
            if let epoch = epoch {
                MintNFTSheet(epoch: epoch)
            }
        }
        .sheet(isPresented: $showTimeCapsuleCompose) {
            if let epoch = epoch {
                TimeCapsuleComposeView(
                    epochId: epoch.id,
                    epochTitle: epoch.title,
                    onSave: { _ in showTimeCapsuleCompose = false },
                    onDismiss: { showTimeCapsuleCompose = false }
                )
            }
        }
        .fullScreenCover(isPresented: $showTimeCapsuleReveal) {
            if let capsule = pendingCapsule {
                TimeCapsuleRevealView(capsule: capsule) {
                    showTimeCapsuleReveal = false
                    pendingCapsule = nil
                }
            }
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

    fileprivate var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading epoch...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    fileprivate var errorView: some View {
        EmptyStateCard(
            icon: .warning,
            title: "Epoch Not Found",
            message: "This epoch may have been finalized or doesn't exist",
            actionTitle: "Go Back"
        ) {
            coordinator.pop()
        }
    }
}

// MARK: - EpochDetailView Navigation

extension EpochDetailView {
    fileprivate var customNavigationHeader: some View {
        HStack {
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

            if let epoch = epoch {
                Menu {
                    Button {
                    } label: {
                        Label("Share Epoch", systemImage: "square.and.arrow.up")
                    }

                    if epoch.state == .finalized || epoch.state == .closed {
                        Button {
                            showMintNFTSheet = true
                        } label: {
                            Label("Convert to NFT", systemImage: "seal.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .regular))
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
}

// MARK: - EpochDetailView Content Sections

extension EpochDetailView {
    fileprivate func epochContentView(_ epoch: Epoch) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                heroSection(epoch)

                if epoch.state == .active || epoch.state == .scheduled {
                    timerSection(epoch)
                }

                infoCardsSection(epoch)

                if epoch.capability == .presenceWithEphemeralData || !mediaPosts.isEmpty {
                    mediaSection
                }

                capabilitySection(epoch)
                actionSection(epoch)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    fileprivate var mediaSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Media")
                .font(Typography.titleSmall)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)

            MediaGalleryView(posts: $mediaPosts)
        }
        .padding(.horizontal, -Theme.Spacing.md)
    }

    fileprivate func heroSection(_ epoch: Epoch) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                EpochStateIcon(epoch.state, size: .lg)
                Text(epoch.state.displayName)
                    .font(Typography.titleMedium)
                    .foregroundStyle(stateColor(for: epoch.state))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.full)

            Text(epoch.title)
                .font(Typography.headlineLarge)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            if let description = epoch.description {
                Text(description)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    fileprivate func timerSection(_ epoch: Epoch) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(epoch.state == .active ? "Time Remaining" : "Starts In")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(formatTime(timeRemaining))
                .font(Typography.timer)
                .foregroundStyle(Theme.Colors.textPrimary)
                .monospacedDigit()

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

    fileprivate func infoCardsSection(_ epoch: Epoch) -> some View {
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

    fileprivate func capabilitySection(_ epoch: Epoch) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Features")
                .font(Typography.titleSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.xs) {
                FeatureRow(icon: .presence, title: "Presence Declaration", isEnabled: true)
                FeatureRow(icon: .signals, title: "Discovery & Messaging", isEnabled: epoch.capability.supportsDiscovery)
                FeatureRow(icon: .media, title: "Ephemeral Media", isEnabled: epoch.capability.supportsMedia)
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }
}

// MARK: - EpochDetailView Actions

extension EpochDetailView {
    fileprivate func actionSection(_ epoch: Epoch) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            if presence != nil {
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
                PrimaryButton("Join Epoch", icon: .presence, isLoading: isJoining) {
                    joinEpoch()
                }

                Text("Joining will declare your presence on-chain")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            } else {
                StatusCard(
                    title: "Epoch \(epoch.state.displayName)",
                    message: "This epoch is no longer accepting participants",
                    status: .info
                )
            }

            if epoch.state == .scheduled {
                prophecyButton(epoch)
            }

            if !epochProphecies.isEmpty {
                prophecyPreview
            }

            if epoch.state == .scheduled || epoch.state == .active {
                timeCapsuleButton(epoch)
            }
        }
    }

    fileprivate func prophecyButton(_ epoch: Epoch) -> some View {
        Button {
            if hasProphecy {
                showProphecySheet = true
            } else {
                commitProphecy()
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(hasProphecy ? Theme.Colors.success.opacity(0.15) : Theme.Colors.warning.opacity(0.15))
                        .frame(width: 40, height: 40)

                    if isCommittingProphecy {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: hasProphecy ? "checkmark.seal.fill" : "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(hasProphecy ? Theme.Colors.success : Theme.Colors.warning)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(hasProphecy ? "Prophecy Made" : "I'll Be There")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(hasProphecy ? "You've committed to attend" : "Stake your reputation")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                if !hasProphecy {
                    Text("+10 rep")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Colors.warning)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Theme.Colors.warning.opacity(0.15))
                        }
                }
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isCommittingProphecy)
    }

    fileprivate var prophecyPreview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Who's Coming")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                Text("\(epochProphecies.count) committed")
                    .font(Typography.labelSmall)
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }

            HStack(spacing: -8) {
                ForEach(epochProphecies.prefix(5)) { prophecy in
                    Circle()
                        .fill(Theme.Colors.backgroundTertiary)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(String(prophecy.userDisplayName?.first ?? "?"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Theme.Colors.background, lineWidth: 2)
                        }
                }

                if epochProphecies.count > 5 {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text("+\(epochProphecies.count - 5)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.Colors.primaryFallback)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Theme.Colors.background, lineWidth: 2)
                        }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    fileprivate func timeCapsuleButton(_ epoch: Epoch) -> some View {
        Button {
            showTimeCapsuleCompose = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.info.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "envelope.badge.clock")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.info)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Leave a note for future you")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Unlocks when you return")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - EpochDetailView Data Loading

extension EpochDetailView {
    fileprivate func loadEpoch() async {
        isLoading = true
        do {
            let fetchedEpoch = try await dependencies.epochRepository.fetchEpoch(id: epochId)
            await MainActor.run {
                epoch = fetchedEpoch
                timeRemaining = fetchedEpoch.timeUntilNextPhase
                isLoading = false
            }

            if let wallet = await dependencies.walletRepository.currentWallet {
                let existingPresence = try? await dependencies.presenceRepository.fetchPresence(
                    actor: wallet.address,
                    epochId: epochId
                )
                await MainActor.run {
                    presence = existingPresence
                }
            }

            let prophecies = try await dependencies.prophecyRepository.fetchProphecies(for: epochId)
            let userProphecy = try await dependencies.prophecyRepository.getProphecy(for: epochId)
            await MainActor.run {
                epochProphecies = prophecies
                myProphecy = userProphecy
                hasProphecy = userProphecy != nil
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error.localizedDescription
                showError = true
            }
        }
    }

    fileprivate func joinEpoch() {
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

    fileprivate func commitProphecy() {
        isCommittingProphecy = true
        Task {
            do {
                let prophecy = try await dependencies.prophecyRepository.createProphecy(
                    epochId: epochId,
                    stakeAmount: 10.0
                )
                await MainActor.run {
                    myProphecy = prophecy
                    hasProphecy = true
                    epochProphecies.insert(prophecy, at: 0)
                    isCommittingProphecy = false

                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isCommittingProphecy = false
                    self.error = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - EpochDetailView Helpers

extension EpochDetailView {
    fileprivate func stateColor(for state: EpochState) -> Color {
        switch state {
        case .none: return Theme.Colors.textTertiary
        case .scheduled: return Theme.Colors.epochScheduled
        case .active: return Theme.Colors.epochActive
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        }
    }

    fileprivate func progressValue(_ epoch: Epoch) -> CGFloat {
        let total = epoch.endTime.timeIntervalSince(epoch.startTime)
        let remaining = timeRemaining
        return max(0, min(1, CGFloat(1 - remaining / total)))
    }

    fileprivate func capabilityIcon(_ capability: EpochCapability) -> AppIcon {
        switch capability {
        case .presenceOnly: return .presence
        case .presenceWithSignals: return .signals
        case .presenceWithEphemeralData: return .media
        }
    }

    fileprivate func formatTime(_ interval: TimeInterval) -> String {
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

// MARK: - Preview

#Preview {
    NavigationStack {
        EpochDetailView(epochId: 1)
    }
    .environment(\.dependencies, .shared)
    .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
