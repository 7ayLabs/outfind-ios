import SwiftUI

// MARK: - Explore Section

/// Explore view with horizontal categories, story circles, and featured cards
struct ExploreSection: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies
    @Environment(\.colorScheme) private var colorScheme

    // Data state
    @State private var epochs: [Epoch] = []
    @State private var lapses: [EpochPost] = []
    @State private var isLoading = true

    // Filter state
    @State private var addedEpochs: Set<UInt64> = []

    // UI state
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var tilesAppeared = false

    // Animation states
    @State private var storyBorderPhase: CGFloat = 0

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar as header
                    searchBar
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.xl)

                    if isLoading {
                        loadingView
                            .frame(height: 400)
                    } else {
                        // Story circles - Popular Lapses
                        if !filteredLapses.isEmpty {
                            storiesSection
                                .padding(.top, Theme.Spacing.lg)
                        }

                        // Featured epochs carousel
                        if !filteredEpochs.isEmpty {
                            featuredEpochsSection
                                .padding(.top, Theme.Spacing.xl)
                        }

                        // Trending epochs list
                        if !filteredEpochs.isEmpty {
                            trendingSection
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
            .navigationBarHidden(true)
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .task {
                await loadData()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    tilesAppeared = true
                }
            }
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


// MARK: - Stories Section (Popular Lapses)

extension ExploreSection {
    fileprivate var storiesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Popular Lapses", showSeeAll: true)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(Array(filteredLapses.prefix(10).enumerated()), id: \.element.id) { index, lapse in
                        storyCircle(lapse, index: index)
                            .opacity(tilesAppeared ? 1 : 0)
                            .offset(y: tilesAppeared ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05), value: tilesAppeared)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                storyBorderPhase = 1
            }
        }
    }

    // Test image URL for avatars
    private func testAvatarURL(for index: Int) -> URL? {
        URL(string: "https://i.pravatar.cc/150?img=\(index + 1)")
    }

    fileprivate func storyCircle(_ lapse: EpochPost, index: Int) -> some View {
        let hasUnviewed = index < 5 // Mock: first 5 are "unviewed"

        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            // Open lapse detail/story viewer
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                // Avatar with minimalist ring
                ZStack {
                    // Ring border - animated trim for unviewed
                    if hasUnviewed {
                        Circle()
                            .stroke(
                                Theme.Colors.textPrimary,
                                lineWidth: 2
                            )
                            .frame(width: 68, height: 68)
                            .opacity(storyBorderPhase)
                    } else {
                        // Static subtle ring for viewed
                        Circle()
                            .strokeBorder(
                                Theme.Colors.textTertiary.opacity(0.2),
                                lineWidth: 1.5
                            )
                            .frame(width: 68, height: 68)
                    }

                    // Avatar image - use test image URL
                    AsyncImage(url: testAvatarURL(for: index)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                                .overlay {
                                    Text(String(lapse.author.name.prefix(1)).uppercased())
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                        case .empty:
                            Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                                .overlay {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                }
                        @unknown default:
                            Circle()
                                .fill(Theme.Colors.backgroundSecondary)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                }

                // Author name
                Text(lapse.author.name.components(separatedBy: " ").first ?? lapse.author.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Featured Epochs Section

extension ExploreSection {
    fileprivate var featuredEpochsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Popular Epochs Near You", showSeeAll: true)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(Array(filteredEpochs.prefix(6).enumerated()), id: \.element.id) { index, epoch in
                        featuredEpochCard(epoch)
                            .opacity(tilesAppeared ? 1 : 0)
                            .offset(x: tilesAppeared ? 0 : 40)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2 + Double(index) * 0.08), value: tilesAppeared)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // Test image URL for epoch cards
    private func testEpochImageURL(for epochId: UInt64) -> URL? {
        let imageIndex = Int(epochId % 30) + 1
        return URL(string: "https://picsum.photos/seed/\(imageIndex)/400/500")
    }

    fileprivate func featuredEpochCard(_ epoch: Epoch) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            coordinator.showEpochDetail(epochId: epoch.id)
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Background - test image
                AsyncImage(url: testEpochImageURL(for: epoch.id)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.primaryFallback.opacity(0.6),
                                        Theme.Colors.primaryFallback.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    @unknown default:
                        Color.gray
                    }
                }
                .frame(width: 200, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))

                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))

                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Live badge if active
                    if epoch.state == .active {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.Colors.epochActive)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(.black.opacity(0.4))
                        }
                    }

                    Spacer()

                    // Title
                    Text(epoch.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Location
                    if let locationName = epoch.location?.name {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                            Text(locationName)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.85))
                    }

                    // Rating/participants row
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 11))
                            Text("\(epoch.participantCount)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.8))

                        Spacer()

                        // Star rating (mock)
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", Double.random(in: 4.0...5.0)))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .frame(width: 200, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        }
        .buttonStyle(ExploreCardButtonStyle())
    }
}

// MARK: - Trending Section

extension ExploreSection {
    fileprivate var trendingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            sectionHeader(title: "Trending", showSeeAll: true)
                .padding(.horizontal, Theme.Spacing.md)

            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(filteredEpochs.suffix(4).enumerated()), id: \.element.id) { index, epoch in
                    trendingEpochRow(epoch)
                        .opacity(tilesAppeared ? 1 : 0)
                        .offset(y: tilesAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4 + Double(index) * 0.06), value: tilesAppeared)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    fileprivate func trendingEpochRow(_ epoch: Epoch) -> some View {
        let isAdded = addedEpochs.contains(epoch.id)

        return Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            coordinator.showEpochDetail(epochId: epoch.id)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Thumbnail with test image
                AsyncImage(url: testEpochImageURL(for: epoch.id)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .fill(Theme.Colors.primaryFallback.opacity(0.2))
                            .overlay {
                                Image(systemName: epoch.capability.systemImage)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(Theme.Colors.primaryFallback)
                            }
                    @unknown default:
                        Color.gray
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(epoch.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.sm) {
                        // Location
                        if let locationName = epoch.location?.name {
                            Text(locationName)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                                .lineLimit(1)
                        }

                        // Separator
                        Circle()
                            .fill(Theme.Colors.textTertiary)
                            .frame(width: 3, height: 3)

                        // Participants
                        HStack(spacing: 2) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text("\(epoch.participantCount)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Add button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    toggleAdded(epoch.id)
                } label: {
                    Image(systemName: isAdded ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isAdded ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(isAdded ? Theme.Colors.primaryFallback.opacity(0.15) : Theme.Colors.backgroundTertiary)
                        }
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
        .buttonStyle(ExploreCardButtonStyle())
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
