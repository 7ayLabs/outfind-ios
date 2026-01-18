import SwiftUI

// MARK: - Explore View

struct ExploreView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedFilter: EpochFilter.StateFilter = .all
    @State private var showWalletSheet = false
    @State private var showCreateEpoch = false

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

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
                        epochListView
                    }
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
            .sheet(isPresented: $showCreateEpoch) {
                CreateEpochView()
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button
                FloatingActionButton(.add) {
                    showCreateEpoch = true
                }
                .padding(.trailing, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
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
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Explore")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Discover nearby epochs")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Wallet button
            Button {
                showWalletSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    IconView(.wallet, size: .md, color: Theme.Colors.primaryFallback)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Search & Filter

    private var searchFilterView: some View {
        VStack(spacing: Theme.Spacing.sm) {
            SearchBar(text: $searchText, placeholder: "Search epochs")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(EpochFilter.StateFilter.allCases, id: \.self) { filter in
                        ChipButton(
                            filter.title,
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

    // MARK: - Epoch List

    private var epochListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(filteredEpochs) { epoch in
                    EpochCard(epoch: epoch) {
                        coordinator.showEpochDetail(epochId: epoch.id)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Filtered Epochs

    private var filteredEpochs: [Epoch] {
        var result = epochs

        // Apply state filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { $0.state == .active }
        case .scheduled:
            result = result.filter { $0.state == .scheduled }
        case .nearby:
            // For MVP, show all - location filtering comes in v0.6
            break
        }

        // Apply search
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

// MARK: - Filter Types

extension EpochFilter {
    enum StateFilter: CaseIterable {
        case all
        case active
        case scheduled
        case nearby

        var title: String {
            switch self {
            case .all: return "All"
            case .active: return "Active"
            case .scheduled: return "Upcoming"
            case .nearby: return "Nearby"
            }
        }

        var icon: AppIcon? {
            switch self {
            case .all: return nil
            case .active: return .epochActive
            case .scheduled: return .epochScheduled
            case .nearby: return .locationFill
            }
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
            // Handle
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
                // Profile card
                profileCard(for: user)

                // Network status
                if user.authMethod.isWallet {
                    HStack {
                        StatusIcon(.success, size: .md)

                        Text("Connected to Sepolia")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Spacer()
                    }
                    .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
                }

                Spacer()

                // Disconnect button
                Button {
                    disconnect()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
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
            // Avatar
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 80, height: 80)

                if let avatarURL = user.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        IconView(user.authMethod.isWallet ? .wallet : .google, size: .xl, color: Theme.Colors.primaryFallback)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    IconView(user.authMethod.isWallet ? .wallet : .google, size: .xl, color: Theme.Colors.primaryFallback)
                }
            }

            // Name and identifier
            VStack(spacing: Theme.Spacing.xxs) {
                if let displayName = user.displayName {
                    Text(displayName)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(user.displayIdentifier)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Auth method badge
            HStack(spacing: Theme.Spacing.xxs) {
                IconView(user.authMethod.isWallet ? .wallet : .google, size: .xs, color: Theme.Colors.primaryFallback)
                Text(user.authMethod.isWallet ? "Wallet" : "Google")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xxs)
            .background {
                Capsule()
                    .fill(Theme.Colors.primaryFallback.opacity(0.1))
            }

            // Protocol address if available
            if let address = user.protocolAddress {
                VStack(spacing: Theme.Spacing.xxs) {
                    Text("Protocol Address")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Button {
                        UIPasteboard.general.string = address.hex
                    } label: {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Text(address.abbreviated)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Theme.Colors.textSecondary)

                            IconView(.copy, size: .xs, color: Theme.Colors.textTertiary)
                        }
                    }
                }
                .padding(.top, Theme.Spacing.xs)
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
    ExploreView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
