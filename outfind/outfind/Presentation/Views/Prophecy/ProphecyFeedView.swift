import SwiftUI

// MARK: - Prophecy Feed View

/// Shows a feed of prophecies from friends and the user
/// Displays who's committed to attend upcoming epochs
struct ProphecyFeedView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var friendProphecies: [Prophecy] = []
    @State private var myProphecies: [Prophecy] = []
    @State private var stats: ProphecyStats = .empty
    @State private var isLoading = true
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)

                // Stats card
                statsCard
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)

                // Tab picker
                Picker("", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("My Prophecies").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

                // Content
                if isLoading {
                    loadingView
                } else {
                    TabView(selection: $selectedTab) {
                        friendsFeed
                            .tag(0)

                        myPropheciesFeed
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Prophecies")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("See who's committed")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Crystal ball icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.warning.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.Colors.warning)
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            statItem(
                value: "\(stats.totalProphecies)",
                label: "Total",
                color: Theme.Colors.primaryFallback
            )

            Divider()
                .frame(height: 30)

            statItem(
                value: "\(stats.fulfilledCount)",
                label: "Fulfilled",
                color: Theme.Colors.success
            )

            Divider()
                .frame(height: 30)

            statItem(
                value: "\(Int(stats.reputationScore))%",
                label: "Score",
                color: Theme.Colors.warning
            )
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading prophecies...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Friends Feed

    private var friendsFeed: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                if friendProphecies.isEmpty {
                    emptyState(
                        icon: "person.2.fill",
                        title: "No Friend Prophecies",
                        message: "Your friends haven't made any prophecies yet"
                    )
                } else {
                    ForEach(friendProphecies) { prophecy in
                        ProphecyCard(prophecy: prophecy) {
                            coordinator.showEpochDetail(epochId: prophecy.epochId)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    // MARK: - My Prophecies Feed

    private var myPropheciesFeed: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                if myProphecies.isEmpty {
                    emptyState(
                        icon: "sparkles",
                        title: "No Prophecies Yet",
                        message: "Commit to attend future epochs to build your reputation"
                    )
                } else {
                    ForEach(myProphecies) { prophecy in
                        ProphecyCard(prophecy: prophecy, showUser: false) {
                            coordinator.showEpochDetail(epochId: prophecy.epochId)
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    // MARK: - Empty State

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(Theme.Colors.backgroundTertiary)
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            VStack(spacing: 4) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Load Data

    private func loadData() async {
        isLoading = true
        do {
            async let friendsTask = dependencies.prophecyRepository.fetchFriendProphecies()
            async let myTask = dependencies.prophecyRepository.fetchMyProphecies()
            async let statsTask = dependencies.prophecyRepository.fetchProphecyStats()

            let (friends, mine, fetchedStats) = try await (friendsTask, myTask, statsTask)

            await MainActor.run {
                friendProphecies = friends
                myProphecies = mine
                stats = fetchedStats
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Prophecy Card

struct ProphecyCard: View {
    let prophecy: Prophecy
    var showUser: Bool = true
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: prophecy.status.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(statusColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    if showUser, let userName = prophecy.userDisplayName {
                        Text(userName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }

                    if let epochTitle = prophecy.epochTitle {
                        Text(epochTitle)
                            .font(.system(size: 14, weight: showUser ? .regular : .semibold))
                            .foregroundStyle(showUser ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                            .lineLimit(1)
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        // Status badge
                        Text(prophecy.status.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(statusColor.opacity(0.15))
                            }

                        // Stake amount
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.Colors.warning)

                            Text("\(Int(prophecy.stakeAmount))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }

                        // Time
                        Text(timeAgo(prophecy.committedAt))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
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

    private var statusColor: Color {
        switch prophecy.status {
        case .pending: return Theme.Colors.warning
        case .fulfilled: return Theme.Colors.success
        case .broken: return Theme.Colors.error
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Preview

#Preview {
    ProphecyFeedView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
