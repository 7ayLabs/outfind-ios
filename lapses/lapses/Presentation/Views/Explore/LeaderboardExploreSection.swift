//
//  LeaderboardExploreSection.swift
//  lapses
//
//  ATH Leaderboard for Lapses, Epochs, and Journeys
//

import SwiftUI

// MARK: - Leaderboard Category

enum LeaderboardCategory: String, CaseIterable {
    case lapses = "Lapses"
    case epochs = "Epochs"
    case journeys = "Journeys"
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id: String
    let rank: Int
    let title: String
    let creator: String
    let tradedAmount: Double
    let poolSize: Double
    let liquidity: Double
    let participantCount: Int
    let sparklineData: [CGFloat]
    let change24h: Double
}

// MARK: - Leaderboard Section

struct LeaderboardExploreSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedCategory: LeaderboardCategory = .lapses
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var sectionAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                content
            }
        }
        .task { await loadData() }
    }

    private var content: some View {
        VStack(spacing: 20) {
            categoryTabs
            statsHeader
            leaderboardList
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                categoryTab(category)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.surfaceElevated)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func categoryTab(_ category: LeaderboardCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedCategory = category
            }
        } label: {
            Text(category.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Theme.Colors.background : Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Theme.Colors.textPrimary : .clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statItem(title: "Total Traded", value: "847.5 ETH", icon: "arrow.left.arrow.right")
            Divider().frame(height: 36)
            statItem(title: "Total Pool", value: "312.8 ETH", icon: "drop.fill")
            Divider().frame(height: 36)
            statItem(title: "Liquidity", value: "156.2 ETH", icon: "chart.line.uptrend.xyaxis")
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.surfaceElevated)
        )
        .padding(.horizontal, Theme.Spacing.md)
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.primaryFallback)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Time High")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text("24h")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Header row
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 28, alignment: .leading)
                Text("Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Trade")
                    .frame(width: 60, alignment: .trailing)
                Text("Pool")
                    .frame(width: 50, alignment: .trailing)
                Text("Trend")
                    .frame(width: 50, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.horizontal, 12)

            LazyVStack(spacing: 1) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(entry: entry)
                        .opacity(sectionAppeared ? 1 : 0)
                        .offset(y: sectionAppeared ? 0 : 12)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.04),
                            value: sectionAppeared
                        )
                }
            }
            .background(Theme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, Theme.Spacing.md)
        }
        .onAppear {
            withAnimation { sectionAppeared = true }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.surfaceElevated)
                .frame(height: 44)
                .shimmer(isActive: true)
                .padding(.horizontal, Theme.Spacing.md)

            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.surfaceElevated)
                .frame(height: 70)
                .shimmer(isActive: true)
                .padding(.horizontal, Theme.Spacing.md)

            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 0)
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(height: 60)
                    .shimmer(isActive: true)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private func loadData() async {
        try? await Task.sleep(nanoseconds: 400_000_000)
        await MainActor.run {
            entries = LeaderboardEntry.mockEntries(for: selectedCategory)
            isLoading = false
        }
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            Text("\(entry.rank)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(rankColor)
                .frame(width: 28, alignment: .leading)

            // Name & Creator
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(entry.creator)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Traded
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 7))
                    Text(String(format: "%.2f", entry.tradedAmount))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Theme.Colors.textPrimary)

                Text(changeText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(entry.change24h >= 0 ? .green : .red)
            }
            .frame(width: 60, alignment: .trailing)

            // Pool
            Text(String(format: "%.1f", entry.poolSize))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 50, alignment: .trailing)

            // Sparkline
            LeaderboardSparkline(data: entry.sparklineData, isPositive: entry.change24h >= 0)
                .frame(width: 50, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.Colors.surfaceElevated)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return .orange
        default: return Theme.Colors.textSecondary
        }
    }

    private var changeText: String {
        let sign = entry.change24h >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", entry.change24h))%"
    }
}

// MARK: - Sparkline

private struct LeaderboardSparkline: View {
    let data: [CGFloat]
    let isPositive: Bool
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let stepX = width / CGFloat(max(data.count - 1, 1))
            let maxVal = data.max() ?? 1
            let minVal = data.min() ?? 0
            let range = max(maxVal - minVal, 0.01)

            Path { path in
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = (value - minVal) / range
                    let y = height - (normalizedY * height * 0.8) - height * 0.1

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .trim(from: 0, to: progress)
            .stroke(
                isPositive ? Color.green : Color.red,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
        .onAppear {
            guard !reduceMotion else {
                progress = 1
                return
            }
            withAnimation(.easeOut(duration: 0.4)) {
                progress = 1
            }
        }
    }
}

// MARK: - Mock Data

extension LeaderboardEntry {
    static func mockEntries(for category: LeaderboardCategory) -> [LeaderboardEntry] {
        switch category {
        case .lapses:
            return [
                LeaderboardEntry(id: "l1", rank: 1, title: "Genesis Drop", creator: "0x1234...5678", tradedAmount: 45.2, poolSize: 12.5, liquidity: 8.2, participantCount: 1247, sparklineData: [0.5, 0.6, 0.55, 0.7, 0.8, 0.75, 0.9, 1.0], change24h: 12.5),
                LeaderboardEntry(id: "l2", rank: 2, title: "Sunset Collective", creator: "sunset.eth", tradedAmount: 38.7, poolSize: 10.2, liquidity: 6.8, participantCount: 892, sparklineData: [0.6, 0.5, 0.7, 0.65, 0.8, 0.85, 0.82, 0.9], change24h: 8.3),
                LeaderboardEntry(id: "l3", rank: 3, title: "Urban Explorers", creator: "urban.dao", tradedAmount: 31.4, poolSize: 8.9, liquidity: 5.4, participantCount: 723, sparklineData: [0.4, 0.5, 0.45, 0.6, 0.55, 0.7, 0.65, 0.8], change24h: -2.1),
                LeaderboardEntry(id: "l4", rank: 4, title: "Night Owls", creator: "nocturn.eth", tradedAmount: 28.1, poolSize: 7.5, liquidity: 4.9, participantCount: 634, sparklineData: [0.5, 0.55, 0.6, 0.58, 0.65, 0.7, 0.72, 0.75], change24h: 5.6),
                LeaderboardEntry(id: "l5", rank: 5, title: "Coffee Runs", creator: "caffeine.dao", tradedAmount: 24.8, poolSize: 6.8, liquidity: 4.2, participantCount: 567, sparklineData: [0.6, 0.58, 0.55, 0.5, 0.52, 0.48, 0.45, 0.5], change24h: -4.2),
                LeaderboardEntry(id: "l6", rank: 6, title: "Art Basel", creator: "artlover.eth", tradedAmount: 22.3, poolSize: 6.1, liquidity: 3.8, participantCount: 489, sparklineData: [0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.72], change24h: 3.8)
            ]
        case .epochs:
            return [
                LeaderboardEntry(id: "e1", rank: 1, title: "ETH Denver 2025", creator: "ethdenver.eth", tradedAmount: 82.5, poolSize: 28.4, liquidity: 18.2, participantCount: 3421, sparklineData: [0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0], change24h: 15.2),
                LeaderboardEntry(id: "e2", rank: 2, title: "Devcon VII", creator: "devcon.eth", tradedAmount: 67.8, poolSize: 22.1, liquidity: 14.5, participantCount: 2847, sparklineData: [0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.82, 0.85], change24h: 9.8),
                LeaderboardEntry(id: "e3", rank: 3, title: "Token 2049", creator: "token2049.eth", tradedAmount: 54.2, poolSize: 18.7, liquidity: 11.3, participantCount: 2134, sparklineData: [0.55, 0.6, 0.58, 0.65, 0.7, 0.68, 0.75, 0.78], change24h: 6.4),
                LeaderboardEntry(id: "e4", rank: 4, title: "NFT NYC", creator: "nftnyc.eth", tradedAmount: 48.9, poolSize: 15.2, liquidity: 9.8, participantCount: 1876, sparklineData: [0.7, 0.65, 0.6, 0.58, 0.55, 0.52, 0.5, 0.48], change24h: -3.5),
                LeaderboardEntry(id: "e5", rank: 5, title: "Consensus", creator: "consensus.eth", tradedAmount: 42.1, poolSize: 13.8, liquidity: 8.4, participantCount: 1654, sparklineData: [0.5, 0.55, 0.6, 0.62, 0.65, 0.68, 0.7, 0.72], change24h: 4.2),
                LeaderboardEntry(id: "e6", rank: 6, title: "Paris Blockchain", creator: "pbws.eth", tradedAmount: 38.7, poolSize: 12.1, liquidity: 7.6, participantCount: 1423, sparklineData: [0.45, 0.5, 0.52, 0.55, 0.58, 0.6, 0.62, 0.65], change24h: 2.8)
            ]
        case .journeys:
            return [
                LeaderboardEntry(id: "j1", rank: 1, title: "Genesis Collectors", creator: "genesis.dao", tradedAmount: 125.8, poolSize: 42.3, liquidity: 28.5, participantCount: 12847, sparklineData: [0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.98, 1.0], change24h: 18.5),
                LeaderboardEntry(id: "j2", rank: 2, title: "DeFi Summer", creator: "defi.eth", tradedAmount: 98.4, poolSize: 35.6, liquidity: 22.1, participantCount: 8934, sparklineData: [0.6, 0.65, 0.7, 0.75, 0.78, 0.82, 0.85, 0.88], change24h: 11.2),
                LeaderboardEntry(id: "j3", rank: 3, title: "NFT Renaissance", creator: "nftren.eth", tradedAmount: 76.2, poolSize: 28.9, liquidity: 17.8, participantCount: 6521, sparklineData: [0.5, 0.55, 0.6, 0.65, 0.7, 0.72, 0.75, 0.78], change24h: 7.8),
                LeaderboardEntry(id: "j4", rank: 4, title: "Metaverse Pioneers", creator: "meta.dao", tradedAmount: 64.5, poolSize: 24.1, liquidity: 14.6, participantCount: 5234, sparklineData: [0.55, 0.58, 0.6, 0.58, 0.55, 0.52, 0.5, 0.48], change24h: -2.4),
                LeaderboardEntry(id: "j5", rank: 5, title: "DAO Builders", creator: "builders.eth", tradedAmount: 52.8, poolSize: 19.7, liquidity: 11.9, participantCount: 4123, sparklineData: [0.45, 0.5, 0.55, 0.58, 0.62, 0.65, 0.68, 0.7], change24h: 5.6),
                LeaderboardEntry(id: "j6", rank: 6, title: "Art Collective", creator: "artcol.dao", tradedAmount: 45.1, poolSize: 16.8, liquidity: 9.8, participantCount: 3456, sparklineData: [0.4, 0.45, 0.5, 0.52, 0.55, 0.58, 0.6, 0.62], change24h: 3.2)
            ]
        }
    }
}

#Preview {
    ScrollView {
        LeaderboardExploreSection()
    }
    .background(Theme.Colors.background)
}
