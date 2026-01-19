import SwiftUI

// MARK: - Explore Section

/// Optimized Explore view with Featured, Active Now, Coming Soon sections
/// Performance improvements: visibility-tracked animations, cached filters
struct ExploreSection: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedFilter: ExploreFilter = .all
    @State private var hasAppeared = false
    @State private var cachedFilteredEpochs: [Epoch] = []

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Header
                        headerView
                            .padding(.horizontal, Theme.Spacing.md)

                        // Category Carousel
                        ExploreCategoryCarousel(
                            selectedFilter: $selectedFilter,
                            hasAppeared: hasAppeared
                        )

                        // Content
                        if isLoading {
                            loadingView
                                .frame(minHeight: 400)
                        } else {
                            // Featured Section
                            if let featured = featuredEpoch {
                                AnimatedFeaturedCard(epoch: featured, hasAppeared: hasAppeared) {
                                    coordinator.showEpochDetail(epochId: featured.id)
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.top, Theme.Spacing.md)
                            }

                            // Active Now Section
                            if !activeEpochs.isEmpty {
                                ActiveNowSection(
                                    epochs: activeEpochs,
                                    hasAppeared: hasAppeared,
                                    onEpochTap: { epoch in
                                        coordinator.showEpochDetail(epochId: epoch.id)
                                    }
                                )
                                .padding(.top, Theme.Spacing.lg)
                            }

                            // Coming Soon Section
                            if !upcomingEpochs.isEmpty {
                                ComingSoonSection(
                                    epochs: upcomingEpochs,
                                    hasAppeared: hasAppeared,
                                    onEpochTap: { epoch in
                                        coordinator.showEpochDetail(epochId: epoch.id)
                                    }
                                )
                                .padding(.top, Theme.Spacing.lg)
                            }

                            // Epoch Feed
                            if cachedFilteredEpochs.isEmpty {
                                emptyStateView
                            } else {
                                epochFeedContent
                            }
                        }
                    }
                }
                .refreshable {
                    await loadEpochs()
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .task {
                await loadEpochs()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    hasAppeared = true
                }
            }
            .onChange(of: selectedFilter) { _, _ in updateFilteredEpochs() }
            .onChange(of: searchText) { _, _ in updateFilteredEpochs() }
            .onChange(of: epochs) { _, _ in updateFilteredEpochs() }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Explore")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Discover epochs around you")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Settings button with animation
            AnimatedIconButton(icon: .settings) {
                // TODO: Show filter sheet
            }
        }
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
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

    // MARK: - Epoch Feed Content

    private var epochFeedContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack {
                Text("All Epochs")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Text("\(cachedFilteredEpochs.count) found")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.lg)

            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(cachedFilteredEpochs.indices, id: \.self) { index in
                    let epoch = cachedFilteredEpochs[index]
                    ExplorePostCard(epoch: epoch, animationDelay: min(Double(index) * 0.05, 0.5)) {
                        coordinator.showEpochDetail(epochId: epoch.id)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Computed Properties

    private var featuredEpoch: Epoch? {
        epochs.first { $0.state == .active && $0.capability == .presenceWithEphemeralData }
    }

    private var activeEpochs: [Epoch] {
        epochs.filter { $0.state == .active }
    }

    private var upcomingEpochs: [Epoch] {
        epochs.filter { $0.state == .scheduled }
    }

    // MARK: - Filter Cache

    private func updateFilteredEpochs() {
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
        case .trending:
            result = result.sorted { $0.participantCount > $1.participantCount }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        cachedFilteredEpochs = result
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

// MARK: - Animated Icon Button

struct AnimatedIconButton: View {
    let icon: AppIcon
    let action: () -> Void

    @State private var isPressed = false
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        Button {
            triggerAnimation()
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)

                IconView(icon, size: .sm, color: Theme.Colors.textSecondary)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
            }
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private func triggerAnimation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            iconScale = 1.3
            iconRotation = 15
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconRotation = 0
        }
    }
}

// MARK: - Animated Button Style

struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Explore Filter

enum ExploreFilter: CaseIterable {
    case all
    case active
    case scheduled
    case nearby
    case media
    case trending

    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Live"
        case .scheduled: return "Upcoming"
        case .nearby: return "Nearby"
        case .media: return "Media"
        case .trending: return "Trending"
        }
    }

    var icon: AppIcon {
        switch self {
        case .all: return .epoch
        case .active: return .epochActive
        case .scheduled: return .epochScheduled
        case .nearby: return .locationFill
        case .media: return .media
        case .trending: return .bolt
        }
    }

    var color: Color {
        switch self {
        case .all: return Theme.Colors.primaryFallback
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        case .nearby: return Color(hex: "95E1D3")
        case .media: return Theme.Colors.warning
        case .trending: return Color(hex: "FF6B6B")
        }
    }
}

// MARK: - Explore Category Carousel

struct ExploreCategoryCarousel: View {
    @Binding var selectedFilter: ExploreFilter
    var hasAppeared: Bool

    private static let allFilters = ExploreFilter.allCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(Self.allFilters.indices, id: \.self) { index in
                    let filter = Self.allFilters[index]
                    ExploreCategoryChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        animationDelay: Double(index) * 0.08,
                        hasAppeared: hasAppeared
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 0, for: .scrollContent)
    }
}

// MARK: - Explore Category Chip

private struct ExploreCategoryChip: View {
    let filter: ExploreFilter
    let isSelected: Bool
    let animationDelay: Double
    let hasAppeared: Bool
    let action: () -> Void

    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -30

    var body: some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            HStack(spacing: 6) {
                IconView(filter.icon, size: .sm, color: isSelected ? .white : filter.color)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))

                Text(filter.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                Capsule()
                    .fill(isSelected ? filter.color : filter.color.opacity(0.12))
            }
            .overlay {
                if !isSelected {
                    Capsule()
                        .strokeBorder(filter.color.opacity(0.3), lineWidth: 1)
                }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(AnimatedButtonStyle())
        .onChange(of: hasAppeared) { _, appeared in
            if appeared {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(animationDelay)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
            }
        }
        .onChange(of: isSelected) { _, selected in
            if selected {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    iconScale = 1.3
                    iconRotation = 360
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
                    iconScale = 1.0
                    iconRotation = 0
                }
            }
        }
        .onAppear {
            if hasAppeared {
                iconScale = 1.0
                iconRotation = 0
            }
        }
    }

    private func triggerHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Animated Featured Card (Web3 Style - Optimized)

struct AnimatedFeaturedCard: View {
    let epoch: Epoch
    let hasAppeared: Bool
    let onTap: () -> Void

    @State private var cardScale: CGFloat = 0.95
    @State private var cardOpacity: Double = 0

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Featured badge (static - no pulse animation)
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.Colors.primaryFallback)
                            .frame(width: 8, height: 8)

                        Text("FEATURED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }

                    Spacer()

                    // Countdown
                    VStack(spacing: 2) {
                        Text(formattedTimeRemaining.0)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text(formattedTimeRemaining.1)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(Theme.Spacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm, style: .continuous)
                            .fill(Theme.Colors.epochActive.opacity(0.15))
                    }
                }

                // Title and description
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(epoch.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(2)

                    if let description = epoch.description {
                        Text(description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }

                // Footer
                HStack(spacing: Theme.Spacing.md) {
                    AvatarStack(count: Int(epoch.participantCount))

                    Text("\(epoch.participantCount) participants")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Join Now")
                            .font(.system(size: 14, weight: .semibold))
                        IconView(.forward, size: .xs, color: Theme.Colors.primaryFallback)
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                    .fill(Theme.Colors.surface)
            }
            .overlay {
                // Static gradient border (no rotation animation)
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback,
                                Theme.Colors.epochActive
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .opacity(0.8)
            }
            .shadow(color: Theme.Colors.primaryFallback.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(AnimatedButtonStyle())
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }

    private var formattedTimeRemaining: (String, String) {
        let time = epoch.timeUntilNextPhase
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60

        if hours > 0 {
            return ("\(hours)h \(minutes)m", "remaining")
        } else {
            return ("\(minutes)m", "remaining")
        }
    }
}

// MARK: - Active Now Section (Optimized - Static indicator)

struct ActiveNowSection: View {
    let epochs: [Epoch]
    let hasAppeared: Bool
    let onEpochTap: (Epoch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    // Static live indicator (no animation for performance)
                    Circle()
                        .fill(Theme.Colors.epochActive)
                        .frame(width: 10, height: 10)

                    Text("Active Now")
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                Text("\(epochs.count) live")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.epochActive)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(epochs.indices, id: \.self) { index in
                        let epoch = epochs[index]
                        AnimatedCompactCard(
                            epoch: epoch,
                            style: .active,
                            animationDelay: Double(index) * 0.1,
                            hasAppeared: hasAppeared
                        ) {
                            onEpochTap(epoch)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
}

// MARK: - Coming Soon Section

struct ComingSoonSection: View {
    let epochs: [Epoch]
    let hasAppeared: Bool
    let onEpochTap: (Epoch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    IconView(.epochScheduled, size: .sm, color: Theme.Colors.epochScheduled)

                    Text("Coming Soon")
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                Text("\(epochs.count) upcoming")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.epochScheduled)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(epochs.indices, id: \.self) { index in
                        let epoch = epochs[index]
                        AnimatedCompactCard(
                            epoch: epoch,
                            style: .upcoming,
                            animationDelay: Double(index) * 0.1,
                            hasAppeared: hasAppeared
                        ) {
                            onEpochTap(epoch)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
}

// MARK: - Animated Compact Card

struct AnimatedCompactCard: View {
    enum Style {
        case active
        case upcoming

        var color: Color {
            switch self {
            case .active: return Theme.Colors.epochActive
            case .upcoming: return Theme.Colors.epochScheduled
            }
        }

        var badgeText: String {
            switch self {
            case .active: return "LIVE"
            case .upcoming: return "SOON"
            }
        }
    }

    let epoch: Epoch
    let style: Style
    let animationDelay: Double
    let hasAppeared: Bool
    let onTap: () -> Void

    @State private var cardOffset: CGFloat = 30
    @State private var cardOpacity: Double = 0
    @State private var iconRotation: Double = -15
    @State private var iconScale: CGFloat = 0.8

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    style.color.opacity(0.35),
                                    style.color.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 100)

                    // Animated icon
                    EpochStateIcon(epoch.state, size: .lg)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))

                    // Badge
                    VStack {
                        HStack {
                            Spacer()
                            Text(style.badgeText)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(style.color)
                                }
                        }
                        Spacer()
                    }
                    .padding(8)
                }

                // Title
                Text(epoch.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .leading)

                // Stats
                HStack(spacing: Theme.Spacing.xs) {
                    HStack(spacing: 4) {
                        IconView(.participants, size: .xs, color: Theme.Colors.textTertiary)
                        Text("\(epoch.participantCount)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    TimerBadge(timeRemaining: epoch.timeUntilNextPhase)
                }
                .frame(width: 160)
            }
        }
        .buttonStyle(AnimatedButtonStyle())
        .offset(x: cardOffset)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay)) {
                cardOffset = 0
                cardOpacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(animationDelay + 0.1)) {
                iconScale = 1.0
                iconRotation = 0
            }
        }
    }
}

// MARK: - Minimal Epoch Card (BeReal-inspired, Performance Optimized)

struct ExplorePostCard: View {
    let epoch: Epoch
    var animationDelay: Double = 0
    let onTap: () -> Void

    @State private var reactions: [EpochReaction] = EpochReaction.randomReactions
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Main card - BeReal style with full-bleed media
            Button(action: onTap) {
                ZStack(alignment: .topLeading) {
                    // Full-bleed gradient/media background
                    mediaBackground

                    // Top-left: Creator badge (BeReal-style small overlay)
                    creatorBadge
                        .padding(Theme.Spacing.sm)

                    // Bottom overlay with info
                    VStack {
                        Spacer()
                        bottomInfoBar
                    }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(MinimalCardButtonStyle())

            // Compact reaction row below card
            compactReactionRow
                .padding(.horizontal, Theme.Spacing.xxs)
        }
        .opacity(cardOpacity)
        .offset(y: cardOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(animationDelay)) {
                cardOpacity = 1
                cardOffset = 0
            }
        }
    }

    // MARK: - Media Background

    private var mediaBackground: some View {
        ZStack {
            // Gradient based on capability
            LinearGradient(
                colors: [
                    capabilityColor.opacity(0.4),
                    stateColor.opacity(0.2),
                    Theme.Colors.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle media icon
            IconView(capabilityIcon, size: .xxl, color: .white.opacity(0.15))
        }
    }

    // MARK: - Creator Badge (BeReal-style)

    private var creatorBadge: some View {
        HStack(spacing: 6) {
            // Small capability icon
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(capabilityColor.opacity(0.9))
                .frame(width: 32, height: 32)
                .overlay {
                    IconView(capabilityIcon, size: .sm, color: .white)
                }

            // Capability text
            if epoch.capability == .presenceWithEphemeralData {
                Text("Media")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(.black.opacity(0.4))
                    }
            }
        }
    }

    // MARK: - Bottom Info Bar

    private var bottomInfoBar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                // Status + Title row
                HStack(spacing: 6) {
                    // Static live dot (no animation)
                    if epoch.state == .active {
                        Circle()
                            .fill(Theme.Colors.epochActive)
                            .frame(width: 8, height: 8)

                        Text("LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.Colors.epochActive)
                    } else if epoch.state == .scheduled {
                        IconView(.epochScheduled, size: .xs, color: Theme.Colors.epochScheduled)
                    }

                    Text(epoch.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                // Meta row
                HStack(spacing: 8) {
                    // Participants
                    HStack(spacing: 3) {
                        IconView(.participants, size: .xs, color: .white.opacity(0.8))
                        Text("\(epoch.participantCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))

                    // Time remaining
                    HStack(spacing: 3) {
                        IconView(.timer, size: .xs, color: .white.opacity(0.8))
                        Text(formattedTime)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }

            Spacer()

            // More menu
            Menu {
                Button("Share", systemImage: "square.and.arrow.up") {}
                Button("Report", systemImage: "flag") {}
            } label: {
                IconView(.more, size: .sm, color: .white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.15))
                    }
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Compact Reaction Row

    private var compactReactionRow: some View {
        HStack(spacing: 6) {
            ForEach($reactions) { $reaction in
                CompactReactionChip(reaction: $reaction)
            }

            // Add reaction button
            Button {
                // TODO: Show reaction picker
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Image(systemName: "face.smiling")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Theme.Colors.textTertiary)
                .frame(height: 28)
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.Colors.backgroundTertiary.opacity(0.5))
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Participant avatars
            MiniAvatarStack(count: Int(epoch.participantCount))
        }
    }

    // MARK: - Helper Properties

    private var formattedTime: String {
        let time = epoch.timeUntilNextPhase
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Soon"
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

// MARK: - Minimal Card Button Style

private struct MinimalCardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Reaction Chip (No heavy animations)

struct CompactReactionChip: View {
    @Binding var reaction: EpochReaction

    var body: some View {
        Button {
            toggleReaction()
        } label: {
            HStack(spacing: 3) {
                Text(reaction.emoji)
                    .font(.system(size: 14))

                if reaction.count > 0 {
                    Text("\(reaction.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(reaction.isSelected ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                }
            }
            .frame(height: 28)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(reaction.isSelected ? Theme.Colors.primaryFallback.opacity(0.15) : Theme.Colors.backgroundTertiary.opacity(0.5))
            }
            .overlay {
                if reaction.isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Theme.Colors.primaryFallback.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleReaction() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.easeOut(duration: 0.15)) {
            if reaction.isSelected {
                reaction.count -= 1
                reaction.isSelected = false
            } else {
                reaction.count += 1
                reaction.isSelected = true
            }
        }
    }
}

// MARK: - Mini Avatar Stack (Compact version)

struct MiniAvatarStack: View {
    let count: Int
    private let maxVisible = 3

    private let colors: [Color] = [
        Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"),
        Color(hex: "FFE66D")
    ]

    var body: some View {
        HStack(spacing: -6) {
            ForEach(0..<min(maxVisible, max(1, count)), id: \.self) { index in
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: 20, height: 20)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.Colors.background, lineWidth: 1.5)
                    }
            }

            if count > maxVisible {
                Text("+\(count - maxVisible)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.leading, 4)
            }
        }
    }
}

// MARK: - Optimized Pulse Animation (visibility-aware)

struct OptimizedPulseAnimation: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                isActive ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onChange(of: isActive) { _, active in
                isPulsing = active
            }
            .onAppear {
                if isActive { isPulsing = true }
            }
    }
}

// MARK: - Explore Post Button Style

private struct ExplorePostButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Avatar Stack

struct AvatarStack: View {
    let count: Int
    var maxVisible: Int = 3

    private let colors: [Color] = [
        Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"),
        Color(hex: "FFE66D"),
        Color(hex: "95E1D3"),
        Color(hex: "DDA0DD")
    ]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(0..<min(maxVisible, max(1, count)), id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [colors[index % colors.count], colors[index % colors.count].opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.Colors.surface, lineWidth: 2)
                    }
                    .overlay {
                        Text(avatarEmoji(for: index))
                            .font(.system(size: 12))
                    }
            }

            if count > maxVisible {
                Circle()
                    .fill(Theme.Colors.backgroundTertiary)
                    .frame(width: 26, height: 26)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.Colors.surface, lineWidth: 2)
                    }
                    .overlay {
                        Text("+\(count - maxVisible)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
            }
        }
    }

    private func avatarEmoji(for index: Int) -> String {
        let emojis = ["😎", "🔥", "⚡️", "🎯", "✨"]
        return emojis[index % emojis.count]
    }
}

// MARK: - Epoch Reaction Model

struct EpochReaction: Identifiable, Equatable {
    let id: String  // Use emoji as stable ID to support Equatable properly
    let emoji: String
    var count: Int
    var isSelected: Bool
    var isGif: Bool

    init(emoji: String, count: Int, isSelected: Bool, isGif: Bool = false) {
        self.id = emoji  // Stable ID based on emoji for proper diffing
        self.emoji = emoji
        self.count = count
        self.isSelected = isSelected
        self.isGif = isGif
    }

    static func == (lhs: EpochReaction, rhs: EpochReaction) -> Bool {
        lhs.id == rhs.id && lhs.count == rhs.count && lhs.isSelected == rhs.isSelected
    }

    static var randomReactions: [EpochReaction] {
        let emojis = ["👋", "🔥", "😂", "❤️", "🚀", "💯", "😍", "🎉"]
        let shuffled = emojis.shuffled().prefix(Int.random(in: 2...4))
        return shuffled.map { emoji in
            EpochReaction(emoji: emoji, count: Int.random(in: 1...20), isSelected: Bool.random())
        }
    }
}

// MARK: - Animated Reaction Bar

struct AnimatedReactionBar: View {
    @Binding var reactions: [EpochReaction]
    @State private var showReactionPicker = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach($reactions) { $reaction in
                AnimatedReactionChip(reaction: $reaction)
            }

            // Add reaction button
            Button {
                triggerHaptic()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showReactionPicker = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .frame(height: 34)
                .padding(.horizontal, 12)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.Colors.backgroundTertiary)
                }
            }
            .buttonStyle(AnimatedButtonStyle())

            Spacer()
        }
        .sheet(isPresented: $showReactionPicker) {
            ReactionGifPickerSheet(reactions: $reactions, isPresented: $showReactionPicker)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func triggerHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Animated Reaction Chip

struct AnimatedReactionChip: View {
    @Binding var reaction: EpochReaction
    @State private var bounceScale: CGFloat = 1.0
    @State private var emojiRotation: Double = 0

    var body: some View {
        Button {
            triggerReaction()
        } label: {
            Text(reaction.emoji)
                .font(.system(size: 22))
                .scaleEffect(bounceScale)
                .rotationEffect(.degrees(emojiRotation))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    if reaction.isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Theme.Colors.primaryFallback.opacity(0.5), lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private func triggerReaction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            if reaction.isSelected {
                reaction.count -= 1
                reaction.isSelected = false
                bounceScale = 0.8
            } else {
                reaction.count += 1
                reaction.isSelected = true
                bounceScale = 1.4
                emojiRotation = 15
            }
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
            bounceScale = 1.0
            emojiRotation = 0
        }
    }
}

// MARK: - GIF Emoji Mapping

private enum GifEmojiMapping {
    static let mapping: [String: String] = [
        "excited": "🤩",
        "happy": "😊",
        "wow": "😮",
        "clap": "👏",
        "dance": "💃",
        "thumbsup": "👍",
        "love": "❤️",
        "laugh": "😂",
        "cry": "😢",
        "angry": "😡",
        "shocked": "😱",
        "cool": "😎",
        "wave": "👋",
        "highfive": "🙌",
        "fistbump": "🤜",
        "hug": "🤗",
        "celebrate": "🎉",
        "party": "🥳"
    ]

    static func emoji(for gif: String) -> String {
        mapping[gif] ?? "🎬"
    }
}

// MARK: - Reaction & GIF Picker Sheet

struct ReactionGifPickerSheet: View {
    @Binding var reactions: [EpochReaction]
    @Binding var isPresented: Bool
    @State private var selectedTab: PickerTab = .emoji
    @State private var searchText = ""

    enum PickerTab {
        case emoji
        case gif
    }

    private let reactionsGifs = ["excited", "happy", "wow", "clap", "dance", "thumbsup"]
    private let emotionsGifs = ["love", "laugh", "cry", "angry", "shocked", "cool"]
    private let actionsGifs = ["wave", "highfive", "fistbump", "hug", "celebrate", "party"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Reaction")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                AnimatedIconButton(icon: .close) {
                    isPresented = false
                }
            }
            .padding()

            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Emoji", icon: "face.smiling", isSelected: selectedTab == .emoji) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = .emoji
                    }
                }

                TabButton(title: "GIFs", icon: "photo.stack", isSelected: selectedTab == .gif) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = .gif
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, Theme.Spacing.sm)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.textTertiary)

                TextField(selectedTab == .emoji ? "Search emoji" : "Search GIFs", text: $searchText)
                    .font(.system(size: 15))
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.Colors.backgroundTertiary)
            }
            .padding(.horizontal)
            .padding(.bottom, Theme.Spacing.sm)

            // Content
            if selectedTab == .emoji {
                emojiGrid
            } else {
                gifGrid
            }

            Spacer()
        }
        .background(Theme.Colors.background)
    }

    private var emojiGrid: some View {
        let emojiCategories: [(String, [String])] = [
            ("Popular", ["👋", "🔥", "❤️", "😂", "😍", "🎉", "👍", "👏"]),
            ("Smileys", ["😀", "😃", "😄", "😁", "😅", "🤣", "😊", "😇"]),
            ("Gestures", ["👋", "🤚", "✋", "🖐️", "👌", "🤌", "✌️", "🤞"]),
            ("Hearts", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "💕"]),
            ("Activities", ["🎯", "🚀", "⚡️", "✨", "💫", "🌟", "💥", "🔥"])
        ]

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                ForEach(emojiCategories, id: \.0) { category, emojis in
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(category)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                            ForEach(filteredEmojis(emojis), id: \.self) { emoji in
                                EmojiButton(emoji: emoji) {
                                    addReaction(emoji)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var gifGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                gifCategorySection(title: "Reactions", gifs: reactionsGifs)
                gifCategorySection(title: "Emotions", gifs: emotionsGifs)
                gifCategorySection(title: "Actions", gifs: actionsGifs)
            }
            .padding()
        }
    }

    private func gifCategorySection(title: String, gifs: [String]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(gifs, id: \.self) { gif in
                    GifPlaceholder(name: gif) {
                        addGifReaction(gif)
                    }
                }
            }
        }
    }

    private func filteredEmojis(_ emojis: [String]) -> [String] {
        if searchText.isEmpty { return emojis }
        return emojis
    }

    private func addReaction(_ emoji: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = reactions.firstIndex(where: { $0.emoji == emoji }) {
                reactions[index].count += 1
                reactions[index].isSelected = true
            } else {
                reactions.append(EpochReaction(emoji: emoji, count: 1, isSelected: true))
            }
            isPresented = false
        }
    }

    private func addGifReaction(_ gif: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        let emoji = GifEmojiMapping.emoji(for: gif)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            reactions.append(EpochReaction(emoji: emoji, count: 1, isSelected: true, isGif: true))
            isPresented = false
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isSelected ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.Colors.primaryFallback.opacity(0.12))
                }
            }
        }
        .buttonStyle(AnimatedButtonStyle())
    }
}

// MARK: - Emoji Button

private struct EmojiButton: View {
    let emoji: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 42, height: 42)
                .scaleEffect(isPressed ? 1.3 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - GIF Placeholder (Static - No animation for performance)

private struct GifPlaceholder: View {
    let name: String
    let action: () -> Void

    private static let gifColors = ["FF6B6B", "4ECDC4", "FFE66D", "95E1D3", "DDA0DD", "87CEEB"]

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: gifColor).opacity(0.3),
                                Color(hex: gifColor).opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)

                VStack(spacing: 4) {
                    Text(GifEmojiMapping.emoji(for: name))
                        .font(.system(size: 28))

                    Text(name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private var gifColor: String {
        Self.gifColors[abs(name.hashValue) % Self.gifColors.count]
    }
}

// MARK: - Preview

#Preview {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
