import SwiftUI

// MARK: - Explore Section

/// Metro-style Explore view with animated tiles, lapses, and epochs
struct ExploreSection: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies
    @Environment(\.colorScheme) private var colorScheme

    // Data state
    @State private var epochs: [Epoch] = []
    @State private var lapses: [EpochPost] = []
    @State private var isLoading = true

    // Filter state
    @State private var selectedCategory: ExploreCategory?
    @State private var addedEpochs: Set<UInt64> = []

    // UI state
    @State private var showMapView = false
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var tilesAppeared = false

    // Animation states
    @State private var categoryAnimationDelays: [ExploreCategory: Double] = [:]

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header that scrolls with content
                    exploreHeader
                        .padding(.top, Theme.Spacing.md)

                    // Search bar
                    searchBar
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.lg)

                    if isLoading {
                        loadingView
                            .frame(height: 400)
                    } else {
                        // Categories grid (Metro style)
                        categoriesTileGrid
                            .padding(.top, Theme.Spacing.lg)

                        // Lapses around you
                        if !filteredLapses.isEmpty {
                            lapsesSection
                                .padding(.top, Theme.Spacing.xl)
                        }

                        // Epochs around you
                        if !filteredEpochs.isEmpty {
                            epochsSection
                                .padding(.top, Theme.Spacing.xl)
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
            .background(Theme.Colors.background)
            .scrollIndicators(.hidden)
            .refreshable {
                await loadData()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: Theme.Spacing.sm) {
                        notificationButton
                        mapButton
                    }
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .fullScreenCover(isPresented: $showMapView) {
                ExploreMapViewWrapper(epochs: epochs)
            }
            .task {
                await loadData()
                initializeTileAnimations()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    tilesAppeared = true
                }
            }
        }
    }
}

// MARK: - Header Components

extension ExploreSection {
    fileprivate var exploreHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Explore")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Discover moments nearby")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
    }

    fileprivate var notificationButton: some View {
        Button {
            // Show notifications
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)

                // Badge
                Circle()
                    .fill(Theme.Colors.epochActive)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
        }
    }

    fileprivate var mapButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showMapView = true
            }
        } label: {
            Image(systemName: "map.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.Colors.primaryFallback)
        }
    }
}

// MARK: - Search & Loading

extension ExploreSection {
    fileprivate var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("Search epochs, lapses...", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.backgroundSecondary)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 8, y: 4)
        }
    }

    fileprivate var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Animated loading tiles
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.backgroundTertiary)
                        .frame(height: 100)
                        .shimmer(isActive: true)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(Double(index) * 0.15), value: isLoading)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            Text("Discovering nearby...")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Categories Tile Grid (Metro Style)

extension ExploreSection {
    fileprivate var categoriesTileGrid: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Categories", showSeeAll: false)
                .padding(.horizontal, Theme.Spacing.md)

            // Metro-style tile grid - 8 tiles total
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.sm),
                    GridItem(.flexible(), spacing: Theme.Spacing.sm)
                ],
                spacing: Theme.Spacing.sm
            ) {
                // Row 1: Large "All" tile + stacked Live/Upcoming
                categoryTile(.all, size: .large)
                    .opacity(tilesAppeared ? 1 : 0)
                    .offset(y: tilesAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: tilesAppeared)

                VStack(spacing: Theme.Spacing.sm) {
                    categoryTile(.live, size: .small)
                        .opacity(tilesAppeared ? 1 : 0)
                        .offset(y: tilesAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.15), value: tilesAppeared)

                    categoryTile(.upcoming, size: .small)
                        .opacity(tilesAppeared ? 1 : 0)
                        .offset(y: tilesAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: tilesAppeared)
                }

                // Row 2: Trending + Starting Soon
                categoryTile(.trending, size: .medium)
                    .opacity(tilesAppeared ? 1 : 0)
                    .offset(y: tilesAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: tilesAppeared)

                categoryTile(.startingSoon, size: .medium)
                    .opacity(tilesAppeared ? 1 : 0)
                    .offset(y: tilesAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: tilesAppeared)

                // Row 3: Journeys + Social
                categoryTile(.journeys, size: .medium)
                    .opacity(tilesAppeared ? 1 : 0)
                    .offset(y: tilesAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: tilesAppeared)

                categoryTile(.social, size: .medium)
                    .opacity(tilesAppeared ? 1 : 0)
                    .offset(y: tilesAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: tilesAppeared)

                // Row 4: Media (full width span - using two medium tiles)
                categoryTile(.media, size: .medium)
                    .opacity(tilesAppeared ? 1 : 0)
                    .offset(y: tilesAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45), value: tilesAppeared)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    fileprivate func categoryTile(_ category: ExploreCategory, size: TileSize) -> some View {
        let isSelected = selectedCategory == category
        let count = countForCategory(category)

        return Button {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                if selectedCategory == category {
                    selectedCategory = nil
                } else {
                    selectedCategory = category
                }
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Background gradient
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                category.color,
                                category.color.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Pattern overlay
                GeometryReader { geo in
                    category.patternView
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()

                    // Count badge
                    if count > 0 {
                        Text("+\(count)")
                            .font(.system(size: size == .large ? 28 : 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    // Icon and label
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.system(size: size == .large ? 18 : 14, weight: .semibold))

                        Text(category.label)
                            .font(.system(size: size == .large ? 16 : 13, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.95))
                }
                .padding(Theme.Spacing.md)

                // Selection indicator
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .stroke(.white, lineWidth: 3)
                }
            }
            .frame(height: size.height)
            .shadow(color: category.color.opacity(0.4), radius: isSelected ? 12 : 6, y: isSelected ? 6 : 3)
        }
        .buttonStyle(ExploreTileButtonStyle())
    }

    fileprivate func countForCategory(_ category: ExploreCategory) -> Int {
        switch category {
        case .all: return epochs.count
        case .live: return epochs.filter { $0.state == .active }.count
        case .upcoming: return epochs.filter { $0.state == .scheduled }.count
        case .trending: return epochs.filter { $0.participantCount > 20 }.count
        case .startingSoon:
            let thirtyMinutesFromNow = Date().addingTimeInterval(30 * 60)
            return epochs.filter { $0.state == .scheduled && $0.startTime < thirtyMinutesFromNow }.count
        case .journeys: return epochs.filter { $0.journeyId != nil }.count
        case .social: return epochs.filter { $0.capability != .presenceOnly }.count
        case .media: return epochs.filter { $0.capability == .presenceWithEphemeralData }.count
        }
    }
}

// MARK: - Lapses Section

extension ExploreSection {
    // Lapse accent color - warm orange/coral
    private var lapseColor: Color {
        Color(red: 1.0, green: 0.45, blue: 0.35)
    }

    fileprivate var lapsesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Lapses", showSeeAll: true)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(Array(filteredLapses.prefix(8).enumerated()), id: \.element.id) { index, lapse in
                        lapseCard(lapse)
                            .opacity(tilesAppeared ? 1 : 0)
                            .offset(x: tilesAppeared ? 0 : 30)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.08), value: tilesAppeared)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    fileprivate func lapseCard(_ lapse: EpochPost) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Type indicator + time
                HStack {
                    // LAPSE badge
                    Text("LAPSE")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(lapseColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(lapseColor.opacity(0.12))
                        }

                    Spacer()

                    Text(timeAgo(lapse.createdAt))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Content - the main focus
                Text(lapse.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Author row - minimal
                HStack(spacing: Theme.Spacing.xs) {
                    // Small avatar
                    if let avatarURL = lapse.author.avatarURL {
                        AsyncImage(url: avatarURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(lapseColor.opacity(0.2))
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(lapseColor.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay {
                                Text(String(lapse.author.name.prefix(1)).uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(lapseColor)
                            }
                    }

                    Text(lapse.author.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(Theme.Spacing.sm)
            .frame(width: 160, height: 120)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(lapseColor.opacity(0.15), lineWidth: 1)
            }
        }
        .buttonStyle(ExploreCardButtonStyle())
    }
}

// MARK: - Epochs Section

extension ExploreSection {
    // Epoch accent color - teal/cyan
    private var epochColor: Color {
        Theme.Colors.primaryFallback
    }

    fileprivate var epochsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Epochs", showSeeAll: true)
                .padding(.horizontal, Theme.Spacing.md)

            LazyVStack(spacing: Theme.Spacing.xs) {
                ForEach(Array(filteredEpochs.prefix(6).enumerated()), id: \.element.id) { index, epoch in
                    epochCard(epoch)
                        .opacity(tilesAppeared ? 1 : 0)
                        .offset(y: tilesAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3 + Double(index) * 0.08), value: tilesAppeared)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    fileprivate func epochCard(_ epoch: Epoch) -> some View {
        let isAdded = addedEpochs.contains(epoch.id)

        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            coordinator.showEpochDetail(epochId: epoch.id)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(epoch.state == .active ? Theme.Colors.epochActive : epochColor.opacity(0.4))
                    .frame(width: 3)

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Top row: Type badge + Status
                    HStack(spacing: Theme.Spacing.xs) {
                        // EPOCH badge
                        Text("EPOCH")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(epochColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background {
                                Capsule()
                                    .fill(epochColor.opacity(0.12))
                            }

                        // Live indicator
                        if epoch.state == .active {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Theme.Colors.epochActive)
                                    .frame(width: 6, height: 6)

                                Text("LIVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Theme.Colors.epochActive)
                            }
                        } else if epoch.state == .scheduled {
                            Text(formatTimeUntil(epoch.startTime))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }

                        Spacer()

                        // Participant count - minimal
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                            Text("\(epoch.participantCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    // Title
                    Text(epoch.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    // Location - if available
                    if let locationName = epoch.location?.name {
                        Text(locationName)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }

                // Join button - minimal
                joinButton(isAdded: isAdded, epochId: epoch.id)
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: 72)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ExploreCardButtonStyle())
    }

    fileprivate func joinButton(isAdded: Bool, epochId: UInt64) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            toggleAdded(epochId)
        } label: {
            Image(systemName: isAdded ? "checkmark" : "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isAdded ? epochColor : Theme.Colors.textSecondary)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(isAdded ? epochColor.opacity(0.15) : Theme.Colors.backgroundTertiary)
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func formatTimeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        if interval < 0 { return "Started" }
        if interval < 3600 {
            return "in \(Int(interval / 60))m"
        } else if interval < 86400 {
            return "in \(Int(interval / 3600))h"
        } else {
            return "in \(Int(interval / 86400))d"
        }
    }
}

// MARK: - Helper Components

extension ExploreSection {
    fileprivate func sectionHeader(title: String, showSeeAll: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            if showSeeAll {
                Button {
                    // See all
                } label: {
                    HStack(spacing: 4) {
                        Text("See all")
                            .font(.system(size: 14, weight: .semibold))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
        }
    }
}

// MARK: - Filtered Data

extension ExploreSection {
    fileprivate var filteredEpochs: [Epoch] {
        var result = epochs

        // Apply category filter
        if let category = selectedCategory {
            switch category {
            case .all:
                break
            case .live:
                result = result.filter { $0.state == .active }
            case .upcoming:
                result = result.filter { $0.state == .scheduled }
            case .trending:
                result = result.filter { $0.participantCount > 20 }
            case .startingSoon:
                let thirtyMinutesFromNow = Date().addingTimeInterval(30 * 60)
                result = result.filter { $0.state == .scheduled && $0.startTime < thirtyMinutesFromNow }
            case .journeys:
                result = result.filter { $0.journeyId != nil }
            case .social:
                result = result.filter { $0.capability == .presenceWithSignals || $0.capability == .presenceWithEphemeralData }
            case .media:
                result = result.filter { $0.capability == .presenceWithEphemeralData }
            }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.location?.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result
    }

    fileprivate var filteredLapses: [EpochPost] {
        if searchText.isEmpty {
            return lapses
        }
        return lapses.filter {
            $0.author.name.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Actions

extension ExploreSection {
    fileprivate func loadData() async {
        isLoading = true
        do {
            let fetchedEpochs = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            let fetchedPosts = EpochPost.mockPosts()

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    if fetchedEpochs.isEmpty {
                        epochs = Epoch.mockWithLocations()
                    } else {
                        epochs = fetchedEpochs
                    }
                    lapses = fetchedPosts
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    epochs = Epoch.mockWithLocations()
                    lapses = EpochPost.mockPosts()
                    isLoading = false
                }
            }
        }
    }

    fileprivate func initializeTileAnimations() {
        for (index, category) in ExploreCategory.allCases.enumerated() {
            categoryAnimationDelays[category] = Double(index) * 0.1
        }
    }

    fileprivate func toggleAdded(_ epochId: UInt64) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if addedEpochs.contains(epochId) {
                addedEpochs.remove(epochId)
            } else {
                addedEpochs.insert(epochId)
            }
        }
    }

    fileprivate func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }

    @ViewBuilder
    fileprivate func destinationView(for destination: AppDestination) -> some View {
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

// MARK: - Explore Category

enum ExploreCategory: String, CaseIterable {
    case all
    case live
    case upcoming
    case trending
    case startingSoon
    case journeys
    case social
    case media

    var label: String {
        switch self {
        case .all: return "All"
        case .live: return "Live Now"
        case .upcoming: return "Upcoming"
        case .trending: return "Trending"
        case .startingSoon: return "Soon"
        case .journeys: return "Journeys"
        case .social: return "Social"
        case .media: return "Media"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .live: return "dot.radiowaves.left.and.right"
        case .upcoming: return "clock.fill"
        case .trending: return "flame.fill"
        case .startingSoon: return "timer"
        case .journeys: return "point.3.connected.trianglepath.dotted"
        case .social: return "person.2.fill"
        case .media: return "photo.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return Theme.Colors.primaryFallback
        case .live: return Theme.Colors.epochActive
        case .upcoming: return Theme.Colors.epochScheduled
        case .trending: return Color(red: 1.0, green: 0.4, blue: 0.2)  // Orange-red flame
        case .startingSoon: return Color(red: 0.95, green: 0.6, blue: 0.1)  // Gold/amber
        case .journeys: return Color(red: 0.5, green: 0.3, blue: 0.9)  // Purple
        case .social: return Theme.Colors.info
        case .media: return Color(red: 0.9, green: 0.3, blue: 0.5)
        }
    }

    @ViewBuilder
    var patternView: some View {
        switch self {
        case .all:
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: 40, y: -20)
        case .live:
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.15))
                .offset(x: 30, y: -10)
        case .upcoming:
            Image(systemName: "clock.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 25, y: -5)
        case .trending:
            Image(systemName: "flame.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.15))
                .offset(x: 25, y: -5)
        case .startingSoon:
            Image(systemName: "timer")
                .font(.system(size: 45))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 20, y: 0)
        case .journeys:
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 45))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 20, y: 0)
        case .social:
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 20, y: 0)
        case .media:
            Image(systemName: "camera.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 20, y: 0)
        }
    }
}

// MARK: - Tile Size

enum TileSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 120
        case .large: return 168 // small * 2 + spacing
        }
    }
}

// MARK: - Epoch State Color Extension

private extension EpochState {
    var color: Color {
        switch self {
        case .none: return Theme.Colors.textTertiary
        case .scheduled: return Theme.Colors.epochScheduled
        case .active: return Theme.Colors.epochActive
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        }
    }
}

// MARK: - Custom Button Styles

private struct ExploreTileButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

private struct ExploreCardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    LinearGradient(
                        colors: [
                            .clear,
                            Theme.Colors.textTertiary.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 200
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

extension View {
    func shimmer(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Explore Map View Wrapper

private struct ExploreMapViewWrapper: View {
    @Environment(\.dismiss) private var dismiss
    let epochs: [Epoch]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ExploreMapView(epochs: epochs)

            // Close button with blur background
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
            }
            .padding(.top, 60)
            .padding(.leading, Theme.Spacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}

#Preview("Dark Mode") {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
        .preferredColorScheme(.dark)
}
