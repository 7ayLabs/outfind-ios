import SwiftUI

// MARK: - Journey Detail View

/// Shows journey details with a vertical timeline of epochs
struct JourneyDetailView: View {
    let journeyId: String

    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var journey: LapseJourney?
    @State private var progress: JourneyProgress?
    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background
                .ignoresSafeArea()

            Group {
                if isLoading {
                    loadingView
                } else if let journey = journey {
                    journeyContent(journey)
                } else {
                    errorView
                }
            }
            .padding(.top, 56)

            customNavigationHeader
        }
        .navigationBarHidden(true)
        .task {
            await loadJourney()
        }
    }

    // MARK: - Navigation Header

    private var customNavigationHeader: some View {
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

            if let journey = journey, journey.completionNFTMetadata != nil {
                Image(systemName: "gift.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.warning)
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
            Text("Loading journey...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        EmptyStateCard(
            icon: .warning,
            title: "Journey Not Found",
            message: error ?? "This journey doesn't exist",
            actionTitle: "Go Back"
        ) {
            coordinator.pop()
        }
    }

    // MARK: - Journey Content

    private func journeyContent(_ journey: LapseJourney) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                headerSection(journey)

                // Progress indicator
                if let progress = progress {
                    progressSection(journey: journey, progress: progress)
                }

                // Timeline
                timelineSection(journey)

                // Completion reward
                if journey.completionNFTMetadata != nil {
                    rewardSection(journey)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Header Section

    private func headerSection(_ journey: LapseJourney) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Journey icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradient)
                    .frame(width: 72, height: 72)

                Image(systemName: "point.topleft.down.curvedto.point.filled.bottomright.up")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text(journey.title)
                .font(Typography.headlineLarge)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(journey.description)
                .font(Typography.bodyLarge)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: Theme.Spacing.md) {
                Label("\(journey.epochCount) stops", systemImage: "mappin.circle.fill")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textTertiary)

                if progress != nil {
                    Label("In Progress", systemImage: "figure.walk")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.epochActive)
                }
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }

    // MARK: - Progress Section

    private func progressSection(journey: LapseJourney, progress: JourneyProgress) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Text("Your Progress")
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text("\(progress.completedEpochIds.count)/\(journey.epochCount)")
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.backgroundTertiary)
                        .frame(height: 10)

                    Capsule()
                        .fill(Theme.Colors.primaryGradient)
                        .frame(
                            width: geometry.size.width * progress.progress(totalEpochs: journey.epochCount),
                            height: 10
                        )
                        .animation(Theme.Animation.smooth, value: progress.completedEpochIds.count)
                }
            }
            .frame(height: 10)

            if progress.isJourneyCompleted {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.success)
                    Text("Journey Completed!")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.success)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Timeline Section

    private func timelineSection(_ journey: LapseJourney) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Journey Timeline")
                .font(Typography.titleSmall)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.bottom, Theme.Spacing.md)

            ForEach(Array(journey.epochIds.enumerated()), id: \.element) { index, epochId in
                let isCompleted = progress?.isCompleted(epochId: epochId) ?? false
                let isLast = index == journey.epochIds.count - 1
                let epoch = epochs.first { $0.id == epochId }

                TimelineNode(
                    order: index + 1,
                    title: epoch?.title ?? "Epoch #\(epochId)",
                    subtitle: epoch?.state.displayName ?? "Unknown",
                    isCompleted: isCompleted,
                    isLast: isLast,
                    epochState: epoch?.state ?? .scheduled
                ) {
                    coordinator.showEpochDetail(epochId: epochId)
                }
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Reward Section

    private func rewardSection(_ journey: LapseJourney) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.warning.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "gift.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.warning)
            }

            Text("Completion Reward")
                .font(Typography.titleSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Complete all stops to unlock an exclusive NFT commemorating your journey")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            if progress?.isJourneyCompleted == true {
                PrimaryButton("Claim NFT", icon: .forward) {
                    // Would trigger NFT claim
                }
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Load Data

    private func loadJourney() async {
        isLoading = true
        do {
            journey = try await dependencies.journeyRepository.fetchJourney(id: journeyId)
            progress = try await dependencies.journeyRepository.fetchProgress(for: journeyId)

            // Load epoch details
            if let journey = journey {
                var loadedEpochs: [Epoch] = []
                for epochId in journey.epochIds {
                    if let epoch = try? await dependencies.epochRepository.fetchEpoch(id: epochId) {
                        loadedEpochs.append(epoch)
                    }
                }
                epochs = loadedEpochs
            }

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Timeline Node

private struct TimelineNode: View {
    let order: Int
    let title: String
    let subtitle: String
    let isCompleted: Bool
    let isLast: Bool
    let epochState: EpochState
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Timeline indicator
            VStack(spacing: 0) {
                // Node circle
                ZStack {
                    Circle()
                        .fill(isCompleted ? Theme.Colors.success : nodeColor)
                        .frame(width: 36, height: 36)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(order)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Theme.Colors.success.opacity(0.5) : Theme.Colors.backgroundTertiary)
                        .frame(width: 3, height: 50)
                }
            }

            // Content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(stateColor)
                            .frame(width: 6, height: 6)

                        Text(subtitle)
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(Theme.Colors.backgroundSecondary)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, isLast ? 0 : Theme.Spacing.sm)
        }
    }

    private var nodeColor: Color {
        switch epochState {
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        case .closed, .finalized: return Theme.Colors.epochClosed
        case .none: return Theme.Colors.textTertiary
        }
    }

    private var stateColor: Color {
        switch epochState {
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        case .none: return Theme.Colors.textTertiary
        }
    }
}

// MARK: - Preview

#Preview {
    JourneyDetailView(journeyId: "journey-1")
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
