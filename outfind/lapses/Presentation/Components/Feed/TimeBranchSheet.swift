import SwiftUI

// MARK: - Time Branch Sheet

/// Simple sheet for viewing time branches: comments, journeys, and future messages.
struct TimeBranchSheet: View {
    let post: EpochPost
    @Binding var isPresented: Bool
    let onStartJourney: () -> Void

    @State private var selectedTab: TimeBranchTab = .comments
    @State private var branches: [TimeBranch] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)

                // Content
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(filteredBranches) { branch in
                            branchRow(branch)
                        }

                        if filteredBranches.isEmpty {
                            emptyState
                                .padding(.top, 60)
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle("Time Branches")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
            .task {
                await loadBranches()
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(TimeBranchTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
    }

    private func tabButton(_ tab: TimeBranchTab) -> some View {
        let isSelected = selectedTab == tab
        let count = countForTab(tab)

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 4) {
                Text(tab.label)
                    .font(.system(size: 13, weight: .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Theme.Colors.primaryFallback)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Branch Row

    private func branchRow(_ branch: TimeBranch) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Avatar
            Circle()
                .fill(Theme.Colors.primaryFallback.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(branch.authorName.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(branch.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Text(branch.timeAgo)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Text(branch.content)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineSpacing(3)

                // Special cards for journeys/future
                if branch.type == .journey {
                    journeyIndicator
                }

                if branch.type == .futureMessage {
                    futureIndicator(branch)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    private var journeyIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 12, weight: .medium))

            Text("View journey")
                .font(.system(size: 12, weight: .medium))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.primaryFallback)
        .padding(Theme.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.primaryFallback.opacity(0.1))
        }
    }

    private func futureIndicator(_ branch: TimeBranch) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 12, weight: .medium))

            Text("Reveals \(branch.revealDate ?? "soon")")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.epochScheduled)
        .padding(Theme.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.Colors.epochScheduled.opacity(0.1))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: selectedTab.icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No \(selectedTab.label.lowercased()) yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)

            if selectedTab == .journeys {
                Button {
                    onStartJourney()
                    isPresented = false
                } label: {
                    Text("Start a Journey")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background {
                            Capsule()
                                .fill(Theme.Colors.primaryFallback)
                        }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Helpers

    private var filteredBranches: [TimeBranch] {
        branches.filter { $0.type == selectedTab.branchType }
    }

    private func countForTab(_ tab: TimeBranchTab) -> Int {
        branches.filter { $0.type == tab.branchType }.count
    }

    private func loadBranches() async {
        try? await Task.sleep(for: .milliseconds(200))

        await MainActor.run {
            branches = TimeBranch.mockBranches()
        }
    }
}

// MARK: - Time Branch Tab

enum TimeBranchTab: CaseIterable {
    case comments
    case journeys
    case futureMessages

    var label: String {
        switch self {
        case .comments: return "Comments"
        case .journeys: return "Journeys"
        case .futureMessages: return "Future"
        }
    }

    var icon: String {
        switch self {
        case .comments: return "bubble.left"
        case .journeys: return "point.3.connected.trianglepath.dotted"
        case .futureMessages: return "clock"
        }
    }

    var branchType: TimeBranchType {
        switch self {
        case .comments: return .comment
        case .journeys: return .journey
        case .futureMessages: return .futureMessage
        }
    }
}

// MARK: - Time Branch Type

enum TimeBranchType {
    case comment
    case journey
    case futureMessage
}

// MARK: - Time Branch Model

struct TimeBranch: Identifiable {
    let id = UUID()
    let type: TimeBranchType
    let authorName: String
    let content: String
    let timeAgo: String
    let revealDate: String?

    static func mockBranches() -> [TimeBranch] {
        [
            TimeBranch(type: .comment, authorName: "Sofia M.", content: "This is such a vibe! Love the energy here.", timeAgo: "2m", revealDate: nil),
            TimeBranch(type: .comment, authorName: "Alex Chen", content: "Can't wait for the next epoch!", timeAgo: "5m", revealDate: nil),
            TimeBranch(type: .journey, authorName: "Maria J.", content: "Started: Weekend Adventures", timeAgo: "10m", revealDate: nil),
            TimeBranch(type: .comment, authorName: "Jordan K.", content: "The atmosphere was incredible", timeAgo: "15m", revealDate: nil),
            TimeBranch(type: .futureMessage, authorName: "Time Capsule", content: "A message will be revealed...", timeAgo: "Scheduled", revealDate: "in 2 hours"),
            TimeBranch(type: .journey, authorName: "Carlos R.", content: "Continuing from last week", timeAgo: "20m", revealDate: nil),
        ]
    }
}

// MARK: - Preview

#Preview {
    TimeBranchSheet(
        post: EpochPost.mockPosts()[0],
        isPresented: .constant(true),
        onStartJourney: {}
    )
}

#Preview("Dark") {
    TimeBranchSheet(
        post: EpochPost.mockPosts()[0],
        isPresented: .constant(true),
        onStartJourney: {}
    )
    .preferredColorScheme(.dark)
}
