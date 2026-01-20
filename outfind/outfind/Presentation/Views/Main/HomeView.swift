import SwiftUI

// MARK: - Home View

/// Main home view with card-based layout
/// Features: Search bar, horizontal scroll sections, grid cards, hero banners
struct HomeView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var nearbyUsers: [MockUser] = MockUser.mockUsers
    @State private var nearbyEchoes: [Presence] = []
    @State private var journeys: [LapseJourney] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var showPresenceSheet = false
    @State private var showNotificationsSheet = false
    @State private var hasAppeared = false
    @State private var isNetworkActive = false
    @State private var notificationCount: Int = 4
    @State private var favoriteEpochs: Set<UInt64> = []

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        searchHeader
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.sm)

                        if isLoading {
                            loadingView
                        } else {
                            feedContent
                        }

                        Spacer(minLength: 120)
                    }
                }
                .refreshable {
                    await loadEpochs()
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $showPresenceSheet) {
                PresenceNetworkSheetView(isNetworkActive: $isNetworkActive)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsSheetView(notificationCount: $notificationCount)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await loadEpochs()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Search Header

    private var searchHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text("Lapses")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    showPresenceSheet = true
                } label: {
                    Image(systemName: isNetworkActive ? "wifi" : "wifi.slash")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isNetworkActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial)
                        }
                }

                Button {
                    showNotificationsSheet = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 40, height: 40)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }

                        if notificationCount > 0 {
                            Circle()
                                .fill(Theme.Colors.error)
                                .frame(width: 8, height: 8)
                                .offset(x: -6, y: 6)
                        }
                    }
                }
            }

            Button {
                // TODO: Open full search view
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    Text("Search epochs, places, people...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.Colors.backgroundSecondary)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
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
            Text("Loading your feed...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
        .frame(minHeight: 400)
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        LazyVStack(spacing: Theme.Spacing.lg) {
            exploreNearbyRow
                .padding(.top, Theme.Spacing.lg)

            if !liveEpochs.isEmpty {
                epochHorizontalSection(
                    title: "Happening Now",
                    subtitle: "Join live epochs nearby",
                    epochs: liveEpochs,
                    cardStyle: .live
                )
            }

            if let featuredEpoch = epochs.first(where: { $0.state == .scheduled }) {
                heroCard(epoch: featuredEpoch)
                    .padding(.horizontal, Theme.Spacing.md)
            }

            if !upcomingEpochs.isEmpty {
                epochGridSection(
                    title: "Upcoming Events",
                    epochs: upcomingEpochs
                )
            }

            if !nearbyUsers.isEmpty {
                peopleNearbySection
            }

            if !allEpochs.isEmpty {
                epochHorizontalSection(
                    title: "More to Explore",
                    subtitle: "Discover new epochs",
                    epochs: allEpochs,
                    cardStyle: .standard
                )
            }
        }
    }

    // MARK: - Filtered Content

    private var liveEpochs: [Epoch] {
        epochs.filter { $0.state == .active }
    }

    private var upcomingEpochs: [Epoch] {
        epochs.filter { $0.state == .scheduled }
    }

    private var allEpochs: [Epoch] {
        epochs.filter { $0.state != .finalized }
    }
}

// MARK: - HomeView Sections

extension HomeView {
    fileprivate var exploreNearbyRow: some View {
        Button {
            // Navigate to explore/map
        } label: {
            HStack {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Explore nearby")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Find epochs around you")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, Theme.Spacing.md)
    }

    fileprivate func epochHorizontalSection(
        title: String,
        subtitle: String,
        epochs: [Epoch],
        cardStyle: EpochCardStyle
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(epochs) { epoch in
                        EpochScrollCard(
                            epoch: epoch,
                            style: cardStyle,
                            isFavorite: favoriteEpochs.contains(epoch.id),
                            journey: journey(for: epoch.id),
                            onFavoriteTap: {
                                toggleFavorite(epoch.id)
                            },
                            onJourneyTap: {
                                if let journey = journey(for: epoch.id) {
                                    coordinator.showJourneyDetail(journeyId: journey.id)
                                }
                            },
                            onTap: {
                                coordinator.showEpochDetail(epochId: epoch.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    fileprivate func epochGridSection(title: String, epochs: [Epoch]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button("See all") {
                    // Navigate to all epochs
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.primaryFallback)
            }
            .padding(.horizontal, Theme.Spacing.md)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.sm),
                GridItem(.flexible(), spacing: Theme.Spacing.sm)
            ], spacing: Theme.Spacing.sm) {
                ForEach(epochs.prefix(4)) { epoch in
                    EpochGridCard(
                        epoch: epoch,
                        isFavorite: favoriteEpochs.contains(epoch.id),
                        journey: journey(for: epoch.id),
                        onFavoriteTap: {
                            toggleFavorite(epoch.id)
                        },
                        onJourneyTap: {
                            if let journey = journey(for: epoch.id) {
                                coordinator.showJourneyDetail(journeyId: journey.id)
                            }
                        },
                        onTap: {
                            coordinator.showEpochDetail(epochId: epoch.id)
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    fileprivate func heroCard(epoch: Epoch) -> some View {
        Button {
            coordinator.showEpochDetail(epochId: epoch.id)
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primaryFallback, Theme.Colors.primaryFallback.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("FEATURED")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                        }

                    Spacer()

                    Text(epoch.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    if let description = epoch.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }

                    HStack {
                        Text("Explore now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.primaryFallback)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background {
                        Capsule()
                            .fill(.white)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    fileprivate var peopleNearbySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("People Nearby")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(nearbyUsers) { user in
                        PersonCard(user: user)
                    }

                    if !nearbyEchoes.isEmpty && !nearbyUsers.isEmpty {
                        Rectangle()
                            .fill(Theme.Colors.textTertiary.opacity(0.2))
                            .frame(width: 1, height: 60)
                            .padding(.horizontal, Theme.Spacing.xs)
                    }

                    ForEach(nearbyEchoes) { echo in
                        EchoPersonCard(presence: echo)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
}

// MARK: - HomeView Actions

extension HomeView {
    fileprivate func toggleFavorite(_ epochId: UInt64) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        if favoriteEpochs.contains(epochId) {
            favoriteEpochs.remove(epochId)
        } else {
            favoriteEpochs.insert(epochId)
        }
    }

    fileprivate func loadEpochs() async {
        isLoading = true
        do {
            let fetchedEpochs = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            let fetchedJourneys = try await dependencies.journeyRepository.fetchJourneys()

            var allEchoes: [Presence] = []
            for epoch in fetchedEpochs.filter({ $0.state == .active }) {
                if let echoes = try? await dependencies.presenceRepository.fetchEchoes(for: epoch.id) {
                    allEchoes.append(contentsOf: echoes)
                }
            }

            await MainActor.run {
                if fetchedEpochs.isEmpty {
                    epochs = Epoch.mockWithLocations()
                } else {
                    epochs = fetchedEpochs
                }
                journeys = fetchedJourneys
                nearbyEchoes = allEchoes
                    .sorted { ($0.leftAt ?? .distantPast) > ($1.leftAt ?? .distantPast) }
                    .prefix(5)
                    .map { $0 }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                epochs = Epoch.mockWithLocations()
                journeys = LapseJourney.mockJourneys()
                isLoading = false
            }
        }
    }

    fileprivate func journey(for epochId: UInt64) -> LapseJourney? {
        journeys.first { $0.contains(epochId: epochId) }
    }

    @ViewBuilder
    fileprivate func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        case .journeyDetail(let journeyId):
            JourneyDetailView(journeyId: journeyId)
        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
