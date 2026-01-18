import SwiftUI

// MARK: - Home View

/// Main home view with sections structure
/// Inspired by Airbnb (image #8) with search, categories, and horizontal sections
struct HomeView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var searchText = ""
    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var selectedCategory: EpochCategory = .all
    @State private var showWalletSheet = false

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header with search
                        headerSection
                            .padding(.horizontal, Theme.Spacing.md)

                        // Category grid (image #9 style)
                        CategoryGridSection(selectedCategory: $selectedCategory)
                            .padding(.top, Theme.Spacing.md)

                        // Featured section
                        if let featured = featuredEpoch {
                            FeaturedEpochCard(epoch: featured) {
                                coordinator.showEpochDetail(epochId: featured.id)
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.lg)
                        }

                        // Active epochs section
                        if !activeEpochs.isEmpty {
                            HorizontalEpochSection(
                                title: "Active Now",
                                subtitle: "Join the action",
                                epochs: activeEpochs,
                                onEpochTap: { epoch in
                                    coordinator.showEpochDetail(epochId: epoch.id)
                                }
                            )
                            .padding(.top, Theme.Spacing.lg)
                        }

                        // Upcoming section
                        if !upcomingEpochs.isEmpty {
                            HorizontalEpochSection(
                                title: "Coming Soon",
                                subtitle: "Don't miss out",
                                epochs: upcomingEpochs,
                                onEpochTap: { epoch in
                                    coordinator.showEpochDetail(epochId: epoch.id)
                                }
                            )
                            .padding(.top, Theme.Spacing.lg)
                        }

                        // For You section (like image #8 "Airbnb Originals")
                        ForYouSection(
                            epochs: filteredEpochs,
                            onEpochTap: { epoch in
                                coordinator.showEpochDetail(epochId: epoch.id)
                            }
                        )
                        .padding(.top, Theme.Spacing.lg)

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
            .sheet(isPresented: $showWalletSheet) {
                WalletSheetView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await loadEpochs()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Top bar
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("outfind")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    HStack(spacing: Theme.Spacing.xxs) {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 6, height: 6)
                        Text("Sepolia Testnet")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Profile button
                Button {
                    showWalletSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)

                        IconView(.presence, size: .md, color: Theme.Colors.primaryFallback)
                    }
                }
            }
            .padding(.top, Theme.Spacing.md)

            // Search bar
            SearchBar(text: $searchText, placeholder: "Search epochs, categories...")
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

    private var filteredEpochs: [Epoch] {
        var result = epochs

        // Filter by category
        if selectedCategory != .all {
            result = result.filter { epoch in
                switch selectedCategory {
                case .presence:
                    return epoch.capability == .presenceOnly
                case .social:
                    return epoch.capability == .presenceWithSignals
                case .media:
                    return epoch.capability == .presenceWithEphemeralData
                case .nearby:
                    return true // TODO: Implement location filtering
                default:
                    return true
                }
            }
        }

        // Filter by search
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

// MARK: - Epoch Category

enum EpochCategory: CaseIterable {
    case all
    case presence
    case social
    case media
    case nearby
    case events
    case gaming

    var title: String {
        switch self {
        case .all: return "All"
        case .presence: return "Presence"
        case .social: return "Social"
        case .media: return "Media"
        case .nearby: return "Nearby"
        case .events: return "Events"
        case .gaming: return "Gaming"
        }
    }

    var icon: AppIcon {
        switch self {
        case .all: return .epoch
        case .presence: return .presence
        case .social: return .signals
        case .media: return .media
        case .nearby: return .locationFill
        case .events: return .epochScheduled
        case .gaming: return .sparkle
        }
    }

    var color: Color {
        switch self {
        case .all: return Theme.Colors.primaryFallback
        case .presence: return Color(hex: "FF6B6B")
        case .social: return Color(hex: "4ECDC4")
        case .media: return Color(hex: "FFE66D")
        case .nearby: return Color(hex: "95E1D3")
        case .events: return Color(hex: "DDA0DD")
        case .gaming: return Color(hex: "87CEEB")
        }
    }

    var subtitle: String? {
        switch self {
        case .presence: return "Check in"
        case .social: return "Connect"
        case .media: return "Share"
        case .nearby: return "Local"
        case .events: return "Join"
        case .gaming: return "Play"
        default: return nil
        }
    }
}

// MARK: - Category Grid Section (Image #9 style)

struct CategoryGridSection: View {
    @Binding var selectedCategory: EpochCategory

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]

    // Categories to show in grid (excluding 'all')
    private var gridCategories: [EpochCategory] {
        EpochCategory.allCases.filter { $0 != .all }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack {
                Text("Categories")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    selectedCategory = .all
                } label: {
                    Text("See all")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Grid layout (image #9 style)
            LazyVGrid(columns: columns, spacing: Theme.Spacing.sm) {
                ForEach(gridCategories, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(Theme.Animation.quick) {
                            selectedCategory = selectedCategory == category ? .all : category
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Category Card (Image #9 style)

struct CategoryCard: View {
    let category: EpochCategory
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Icon
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    IconView(category.icon, size: .md, color: category.color)
                }

                // Title
                Text(category.title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                // Subtitle
                if let subtitle = category.subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .fill(category.color.opacity(isSelected ? 0.25 : 0.1))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                                .strokeBorder(category.color, lineWidth: 2)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Featured Epoch Card

struct FeaturedEpochCard: View {
    let epoch: Epoch
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Featured")
                            .font(Typography.labelSmall)
                            .foregroundStyle(Theme.Colors.primaryFallback)

                        Text(epoch.title)
                            .font(Typography.titleLarge)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(2)

                        if let description = epoch.description {
                            Text(description)
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    // Countdown badge
                    VStack(spacing: Theme.Spacing.xxs) {
                        Text(formattedTimeRemaining.0)
                            .font(Typography.headlineMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text(formattedTimeRemaining.1)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(Theme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                            .fill(Theme.Colors.epochActive.opacity(0.15))
                    }
                }

                // Footer with stats
                HStack(spacing: Theme.Spacing.md) {
                    ViewCountBadge(viewCount: Int(epoch.participantCount), avatars: [])

                    CapabilityBadge(capability: epoch.capability)

                    Spacer()

                    Text("Join now")
                        .font(Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    IconView(.forward, size: .sm, color: Theme.Colors.primaryFallback)
                }
            }
            .glassCard(style: .regular, cornerRadius: Theme.CornerRadius.lg)
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

// MARK: - Horizontal Epoch Section (Image #8 style)

struct HorizontalEpochSection: View {
    let title: String
    let subtitle: String?
    let epochs: [Epoch]
    let onEpochTap: (Epoch) -> Void

    init(
        title: String,
        subtitle: String? = nil,
        epochs: [Epoch],
        onEpochTap: @escaping (Epoch) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.epochs = epochs
        self.onEpochTap = onEpochTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Section header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(epochs) { epoch in
                        CompactEpochCard(epoch: epoch) {
                            onEpochTap(epoch)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
}

// MARK: - Compact Epoch Card (for horizontal scroll)

struct CompactEpochCard: View {
    let epoch: Epoch
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Image placeholder with gradient
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    stateColor.opacity(0.4),
                                    stateColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 100)

                    // State icon
                    EpochStateIcon(epoch.state, size: .xl)

                    // Badge overlay
                    VStack {
                        HStack {
                            Spacer()
                            Text(epoch.state.displayName)
                                .font(Typography.labelSmall)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, Theme.Spacing.xxs)
                                .background {
                                    Capsule()
                                        .fill(stateColor)
                                }
                        }
                        Spacer()
                    }
                    .padding(Theme.Spacing.xs)
                }

                // Title
                Text(epoch.title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .leading)

                // Stats
                HStack(spacing: Theme.Spacing.xs) {
                    ViewCountBadge(viewCount: Int(epoch.participantCount), avatars: [], compact: true)

                    Spacer()

                    TimerBadge(timeRemaining: epoch.timeUntilNextPhase)
                }
                .frame(width: 160)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
}

// MARK: - For You Section

struct ForYouSection: View {
    let epochs: [Epoch]
    let onEpochTap: (Epoch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Tabs
            HStack(spacing: Theme.Spacing.lg) {
                Text("For you")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Recent")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Epoch list with liquid glass style (image #7)
            VStack(spacing: Theme.Spacing.md) {
                ForEach(epochs.prefix(5)) { epoch in
                    LiquidGlassEpochCard(epoch: epoch) {
                        onEpochTap(epoch)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - View Count Badge (Image #7 style)

struct ViewCountBadge: View {
    let viewCount: Int
    let avatars: [URL]
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? Theme.Spacing.xxs : Theme.Spacing.xs) {
            // Stacked avatars
            if !avatars.isEmpty {
                HStack(spacing: -8) {
                    ForEach(avatars.prefix(3), id: \.self) { url in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Theme.Colors.backgroundTertiary)
                        }
                        .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Theme.Colors.background, lineWidth: 1)
                        }
                    }
                }
            } else {
                // Default participant icons
                HStack(spacing: -6) {
                    ForEach(0..<min(3, max(1, viewCount)), id: \.self) { index in
                        Circle()
                            .fill(participantColor(for: index))
                            .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)
                            .overlay {
                                Circle()
                                    .stroke(Theme.Colors.background, lineWidth: 1)
                            }
                    }
                }
            }

            Text("\(viewCount) views")
                .font(compact ? Typography.caption : Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func participantColor(for index: Int) -> Color {
        let colors: [Color] = [
            Theme.Colors.primaryFallback,
            Theme.Colors.epochScheduled,
            Theme.Colors.info
        ]
        return colors[index % colors.count].opacity(0.6)
    }
}

// MARK: - Liquid Glass Epoch Card (Image #7 style)

struct LiquidGlassEpochCard: View {
    let epoch: Epoch
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Image collage placeholder (2 images like image #7)
                HStack(spacing: Theme.Spacing.xs) {
                    // Left image
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    stateColor.opacity(0.5),
                                    stateColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)
                        .overlay {
                            EpochStateIcon(epoch.state, size: .xl)
                        }

                    // Right image
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    capabilityColor.opacity(0.4),
                                    capabilityColor.opacity(0.2)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .frame(height: 140)
                        .overlay {
                            IconView(capabilityIcon, size: .xl, color: capabilityColor)
                        }
                }

                // View count with stacked avatars (image #7 style)
                ViewCountBadge(viewCount: Int(epoch.participantCount), avatars: [])

                // Title and description card
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        IconView(epoch.capability == .presenceWithEphemeralData ? .media : .epoch, size: .sm, color: Theme.Colors.primaryFallback)

                        Text(epoch.title)
                            .font(Typography.titleSmall)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)
                    }

                    if let description = epoch.description {
                        Text(description)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(2)
                    }
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
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

// MARK: - Wallet Sheet View

private struct WalletSheetView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var currentUser: User?
    @State private var isDisconnecting = false
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("Profile")
                .font(Typography.titleLarge)
                .foregroundStyle(Theme.Colors.textPrimary)

            if isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.xl)
            } else if let user = currentUser {
                profileCard(for: user)

                Spacer()

                Button {
                    disconnect()
                } label: {
                    HStack {
                        if isDisconnecting {
                            ProgressView()
                                .tint(Theme.Colors.error)
                                .scaleEffect(0.8)
                        }
                        Text("Disconnect")
                            .font(Typography.titleSmall)
                    }
                    .foregroundStyle(Theme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                    }
                }
                .disabled(isDisconnecting)
            } else {
                Text("Not connected")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.vertical, Theme.Spacing.xl)
            }

            SecondaryButton("Done") {
                dismiss()
            }
        }
        .padding()
        .background(Theme.Colors.background)
        .task {
            isLoading = true
            currentUser = await dependencies.authenticationRepository.currentUser
            isLoading = false
        }
    }

    @ViewBuilder
    private func profileCard(for user: User) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 80, height: 80)

                IconView(user.authMethod.isWallet ? .wallet : .google, size: .xl, color: Theme.Colors.primaryFallback)
            }

            VStack(spacing: Theme.Spacing.xxs) {
                if let displayName = user.displayName {
                    Text(displayName)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(user.displayIdentifier)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    private func disconnect() {
        isDisconnecting = true
        Task {
            try? await dependencies.authenticationRepository.disconnect()
            await MainActor.run {
                dismiss()
                coordinator.handleWalletDisconnected()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
