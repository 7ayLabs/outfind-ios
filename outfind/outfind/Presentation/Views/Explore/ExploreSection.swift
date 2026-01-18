import SwiftUI

// MARK: - Explore Section

/// Refactored Explore view - now a section instead of main view
/// Features liquid glass blur posts and view counters (image #7 style)
struct ExploreSection: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedFilter: ExploreFilter = .all

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal, Theme.Spacing.md)

                    // Search & Filter
                    searchFilterView
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.bottom, Theme.Spacing.md)

                    // Content
                    if isLoading {
                        loadingView
                    } else if filteredEpochs.isEmpty {
                        emptyStateView
                    } else {
                        epochGridView
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .task {
                await loadEpochs()
            }
            .refreshable {
                await loadEpochs()
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Explore")
                .font(Typography.headlineLarge)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Discover epochs around you")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Search & Filter

    private var searchFilterView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SearchBar(text: $searchText, placeholder: "Search epochs")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(ExploreFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(Theme.Animation.quick) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading epochs...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack {
            Spacer()
            EmptyStateCard(
                icon: .mapPinCircle,
                title: "No Epochs Found",
                message: searchText.isEmpty
                    ? "No epochs match your current filters"
                    : "No epochs match \"\(searchText)\"",
                actionTitle: "Refresh"
            ) {
                Task { await loadEpochs() }
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Epoch Grid View (Liquid Glass Style)

    private var epochGridView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
                ForEach(filteredEpochs) { epoch in
                    ExploreEpochCard(epoch: epoch) {
                        coordinator.showEpochDetail(epochId: epoch.id)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Filtered Epochs

    private var filteredEpochs: [Epoch] {
        var result = epochs

        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.state == .active }
        case .scheduled:
            result = result.filter { $0.state == .scheduled }
        case .nearby:
            break // TODO: Location filtering
        case .media:
            result = result.filter { $0.capability == .presenceWithEphemeralData }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    // MARK: - Load Epochs

    private func loadEpochs() async {
        isLoading = true
        do {
            let fetchedEpochs = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            await MainActor.run {
                epochs = fetchedEpochs
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    // MARK: - Destination View

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        default:
            EmptyView()
        }
    }
}

// MARK: - Explore Filter

enum ExploreFilter: CaseIterable {
    case all
    case active
    case scheduled
    case nearby
    case media

    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .scheduled: return "Upcoming"
        case .nearby: return "Nearby"
        case .media: return "Media"
        }
    }

    var icon: AppIcon? {
        switch self {
        case .all: return nil
        case .active: return .epochActive
        case .scheduled: return .epochScheduled
        case .nearby: return .locationFill
        case .media: return .media
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let icon: AppIcon?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                if let icon = icon {
                    IconView(icon, size: .sm, color: isSelected ? .white : Theme.Colors.textSecondary)
                }

                Text(title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                Capsule()
                    .fill(isSelected ? Theme.Colors.primaryFallback : .clear)
            }
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                }
            }
        }
    }
}

// MARK: - Explore Epoch Card (Liquid Glass with View Counter)

struct ExploreEpochCard: View {
    let epoch: Epoch
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Image collage with liquid glass blur (image #7 style)
                ZStack {
                    // Background blur layer
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous)
                        .fill(.ultraThinMaterial)

                    // Image collage
                    HStack(spacing: Theme.Spacing.xs) {
                        // Left image
                        imagePanel(
                            gradient: [stateColor.opacity(0.6), stateColor.opacity(0.3)],
                            icon: epoch.state == .active ? .epochActive : .epochScheduled
                        )

                        // Right image
                        imagePanel(
                            gradient: [capabilityColor.opacity(0.5), capabilityColor.opacity(0.2)],
                            icon: capabilityIcon
                        )
                    }
                    .padding(Theme.Spacing.xs)

                    // State badge overlay
                    VStack {
                        HStack {
                            // Live indicator for active epochs
                            if epoch.state == .active {
                                HStack(spacing: Theme.Spacing.xxs) {
                                    Circle()
                                        .fill(Theme.Colors.error)
                                        .frame(width: 6, height: 6)

                                    Text("LIVE")
                                        .font(Typography.labelSmall)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, Theme.Spacing.xxs)
                                .background {
                                    Capsule()
                                        .fill(Theme.Colors.error.opacity(0.9))
                                }
                            }

                            Spacer()

                            // Timer badge
                            TimerBadge(timeRemaining: epoch.timeUntilNextPhase)
                        }
                        Spacer()
                    }
                    .padding(Theme.Spacing.sm)
                }
                .frame(height: 160)

                // View counter with stacked avatars (image #7 style)
                ViewCountBadge(viewCount: Int(epoch.participantCount), avatars: [])

                // Content card with liquid glass
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(capabilityColor.opacity(0.2))
                                .frame(width: 28, height: 28)

                            IconView(capabilityIcon, size: .sm, color: capabilityColor)
                        }

                        Text(epoch.title)
                            .font(Typography.titleMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
                    }

                    if let description = epoch.description {
                        Text(description)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    // Tags/Capability row
                    HStack(spacing: Theme.Spacing.sm) {
                        CapabilityBadge(capability: epoch.capability)

                        Spacer()

                        // Participants icon row
                        HStack(spacing: Theme.Spacing.xxs) {
                            IconView(.participants, size: .xs, color: Theme.Colors.textTertiary)
                            Text("\(epoch.participantCount)")
                                .font(Typography.labelSmall)
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                                .strokeBorder(Theme.Colors.glassBorder, lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private func imagePanel(gradient: [Color], icon: AppIcon) -> some View {
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
            .fill(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                IconView(icon, size: .xl, color: .white.opacity(0.8))
            }
    }

    private var stateColor: Color {
        switch epoch.state {
        case .none: return Theme.Colors.textTertiary
        case .scheduled: return Theme.Colors.epochScheduled
        case .active: return Theme.Colors.epochActive
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        }
    }

    private var capabilityColor: Color {
        switch epoch.capability {
        case .presenceOnly: return Theme.Colors.info
        case .presenceWithSignals: return Theme.Colors.success
        case .presenceWithEphemeralData: return Theme.Colors.warning
        }
    }

    private var capabilityIcon: AppIcon {
        switch epoch.capability {
        case .presenceOnly: return .presence
        case .presenceWithSignals: return .signals
        case .presenceWithEphemeralData: return .media
        }
    }
}

// MARK: - Preview

#Preview {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
