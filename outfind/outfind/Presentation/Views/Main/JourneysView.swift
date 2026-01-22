import SwiftUI

// MARK: - Journeys View

/// User's journeys tab showing active and completed journeys
struct JourneysView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var journeys: [LapseJourney] = []
    @State private var progressMap: [String: JourneyProgress] = [:]
    @State private var isLoading = true
    @State private var selectedFilter: JourneyFilter = .active

    enum JourneyFilter: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case all = "All"
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.horizontal, Theme.Spacing.lg)

                // Filter tabs
                filterTabs
                    .padding(.top, Theme.Spacing.md)
                    .padding(.horizontal, Theme.Spacing.lg)

                if isLoading {
                    loadingView
                } else if filteredJourneys.isEmpty {
                    emptyState
                } else {
                    journeyList
                }
            }
        }
        .task {
            await loadJourneys()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Journeys")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("\(journeys.count) total")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(JourneyFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(Typography.labelMedium)
                        .foregroundStyle(selectedFilter == filter ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background {
                            if selectedFilter == filter {
                                Capsule()
                                    .fill(Theme.Colors.textPrimary.opacity(0.1))
                            }
                        }
                }
            }

            Spacer()
        }
    }

    // MARK: - Filtered Journeys

    private var filteredJourneys: [LapseJourney] {
        switch selectedFilter {
        case .active:
            return journeys.filter { journey in
                guard let progress = progressMap[journey.id] else { return true }
                return !progress.isJourneyCompleted
            }
        case .completed:
            return journeys.filter { journey in
                guard let progress = progressMap[journey.id] else { return false }
                return progress.isJourneyCompleted
            }
        case .all:
            return journeys
        }
    }

    // MARK: - Journey List

    private var journeyList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(filteredJourneys) { journey in
                    JourneyCard(
                        journey: journey,
                        progress: progressMap[journey.id]
                    )
                    .onTapGesture {
                        // Navigate to journey detail
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Theme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)

            VStack(spacing: Theme.Spacing.xs) {
                Text(emptyStateTitle)
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(emptyStateMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .active: return "No Active Journeys"
        case .completed: return "No Completed Journeys"
        case .all: return "No Journeys Yet"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .active: return "Start a journey from any epoch to track your progress"
        case .completed: return "Complete all epochs in a journey to see it here"
        case .all: return "Explore epochs and start your first journey"
        }
    }

    // MARK: - Data Loading

    private func loadJourneys() async {
        isLoading = true

        // Load mock data
        let mockJourneys = LapseJourney.mockJourneys()
        var mockProgress: [String: JourneyProgress] = [:]

        for journey in mockJourneys {
            mockProgress[journey.id] = JourneyProgress.mock(
                journeyId: journey.id,
                completedCount: Int.random(in: 0...journey.epochCount)
            )
        }

        await MainActor.run {
            journeys = mockJourneys
            progressMap = mockProgress
            isLoading = false
        }
    }
}

// MARK: - Journey Card

private struct JourneyCard: View {
    let journey: LapseJourney
    let progress: JourneyProgress?

    @Environment(\.colorScheme) private var colorScheme

    private var progressValue: Double {
        guard let progress else { return 0 }
        return progress.progress(totalEpochs: journey.epochCount)
    }

    private var completedCount: Int {
        progress?.completedEpochIds.count ?? 0
    }

    private var isCompleted: Bool {
        progress?.isJourneyCompleted ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(journey.title)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(journey.description)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // Completion badge
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.Colors.success)
                } else if journey.completionNFTMetadata != nil {
                    // Has NFT reward
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }

            // Progress section
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.textTertiary.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(isCompleted ? Theme.Colors.success : Theme.Colors.primaryFallback)
                            .frame(width: geometry.size.width * progressValue, height: 6)
                    }
                }
                .frame(height: 6)

                // Progress text
                HStack {
                    Text("\(completedCount)/\(journey.epochCount) epochs")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    Text("\(Int(progressValue * 100))%")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
        }
    }
}

// MARK: - Preview

#Preview("Light") {
    JourneysView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    JourneysView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
        .preferredColorScheme(.dark)
}
