//
//  PredictionsExploreSection.swift
//  lapses
//
//  Prediction markets section with clean design and animated sparklines
//

import SwiftUI

// MARK: - Prediction Filter

enum PredictionFilter: String, CaseIterable {
    case trending = "Trending"
    case top = "Top"
    case new = "New"
    case live = "Live"

    var icon: String {
        switch self {
        case .trending: return "chart.line.uptrend.xyaxis"
        case .top: return "crown.fill"
        case .new: return "sparkles"
        case .live: return "antenna.radiowaves.left.and.right"
        }
    }
}

// MARK: - Predictions Explore Section

struct PredictionsExploreSection: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var markets: [PredictionMarket] = []
    @State private var isLoading = true
    @State private var sectionAppeared = false
    @State private var selectedFilter: PredictionFilter = .trending

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                content
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 16) {
            // Filter tabs
            filterTabs

            // Markets list
            if !filteredMarkets.isEmpty {
                marketsList
            } else {
                emptyState
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PredictionFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func filterTab(_ filter: PredictionFilter) -> some View {
        let isSelected = selectedFilter == filter

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(filter == .live && isSelected ? .green : (isSelected ? Theme.Colors.background : Theme.Colors.textSecondary))
                Text(filter.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.textPrimary : Theme.Colors.surface)
            )
            .foregroundStyle(isSelected ? Theme.Colors.background : Theme.Colors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Markets List

    private var marketsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredMarkets.enumerated()), id: \.element.id) { index, market in
                MarketRow(market: market, imageIndex: index)
                    .opacity(sectionAppeared ? 1 : 0)
                    .offset(x: sectionAppeared ? 0 : 20)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.04),
                        value: sectionAppeared
                    )

                if index < filteredMarkets.count - 1 {
                    Divider()
                        .background(Theme.Colors.surface)
                        .padding(.leading, 68)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .onAppear {
            if !reduceMotion {
                withAnimation { sectionAppeared = true }
            } else {
                sectionAppeared = true
            }
        }
    }

    // MARK: - Filtered Markets

    private var filteredMarkets: [PredictionMarket] {
        switch selectedFilter {
        case .trending:
            return markets.sorted { $0.totalPool > $1.totalPool }
        case .top:
            return markets.sorted { $0.yesVoters + $0.noVoters > $1.yesVoters + $1.noVoters }
        case .new:
            return markets.sorted { $0.endTime > $1.endTime }
        case .live:
            return markets.filter { $0.isActive }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No predictions found")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.Colors.surface)
                            .frame(width: 90, height: 36)
                            .shimmer(isActive: true)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Theme.Colors.surface)
                            .frame(width: 48, height: 48)
                            .shimmer(isActive: true)

                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.surface)
                                .frame(width: 140, height: 14)
                                .shimmer(isActive: true)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.surface)
                                .frame(width: 80, height: 11)
                                .shimmer(isActive: true)
                        }

                        Spacer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.surface)
                            .frame(width: 50, height: 28)
                            .shimmer(isActive: true)
                    }
                    .padding(.vertical, 14)

                    if index < 4 {
                        Divider()
                            .background(Theme.Colors.surface)
                            .padding(.leading, 68)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        do {
            let active = try await dependencies.predictionMarketRepository.fetchActiveMarkets()
            let trending = try await dependencies.predictionMarketRepository.fetchTrendingMarkets()

            await MainActor.run {
                markets = Array(Set(active + trending))
                isLoading = false
            }
        } catch {
            await MainActor.run {
                markets = PredictionMarket.mockMarkets()
                isLoading = false
            }
        }
    }
}

// MARK: - Market Row

private struct MarketRow: View {
    let market: PredictionMarket
    let imageIndex: Int

    // Generate consistent sparkline data per market
    private var sparklineData: [Double] {
        // Use bitPattern to safely convert Int to UInt64
        let hashSeed = UInt64(bitPattern: Int64(market.id.hashValue))
        var seededRandom = SeededRandomGenerator(seed: hashSeed)
        let baseValue = market.yesPercentage
        return (0..<14).map { i in
            let variance = seededRandom.next() * 15 - 7.5
            return min(100, max(0, baseValue + variance + Double(i) * 0.3))
        }
    }

    private var percentageChange: Double {
        let first = sparklineData.first ?? 50
        let last = sparklineData.last ?? 50
        return last - first
    }

    private var isPositive: Bool {
        percentageChange >= 0
    }

    // Test image URL
    private var imageURL: URL? {
        URL(string: "https://picsum.photos/seed/pred\(abs(market.id.hashValue) % 100)/100/100")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with test image
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    isPositive ? Color.green.opacity(0.4) : Color.red.opacity(0.4),
                                    isPositive ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: market.predictionType.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isPositive ? .green : .red)
                        }
                @unknown default:
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(market.question)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    if market.isActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "at")
                        .font(.system(size: 10, weight: .medium))
                    Text(market.epochTitle.lowercased().replacingOccurrences(of: " ", with: "").prefix(14))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            // Sparkline with gradient
            AnimatedSparkline(data: sparklineData, isPositive: isPositive)
                .frame(width: 56, height: 28)

            // Value and change
            VStack(alignment: .trailing, spacing: 2) {
                Text(market.formattedPool)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f%%", abs(percentageChange)))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(isPositive ? .green : .red)
            }
            .frame(minWidth: 65, alignment: .trailing)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Animated Sparkline

private struct AnimatedSparkline: View {
    let data: [Double]
    let isPositive: Bool

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minValue = data.min() ?? 0
            let maxValue = data.max() ?? 100
            let range = max(maxValue - minValue, 1)
            let stepX = width / CGFloat(data.count - 1)

            ZStack {
                // Gradient fill under the line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = (value - minValue) / range
                        let y = height - (CGFloat(normalizedY) * height * 0.8) - height * 0.1

                        if index == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            (isPositive ? Color.green : Color.red).opacity(0.2),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    Rectangle()
                        .scaleEffect(x: animationProgress, y: 1, anchor: .leading)
                )

                // Line
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = (value - minValue) / range
                        let y = height - (CGFloat(normalizedY) * height * 0.8) - height * 0.1

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: animationProgress)
                .stroke(
                    isPositive ? Color.green : Color.red,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Seeded Random Generator

private struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> Double {
        // Simple xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1000) / 1000.0
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        PredictionsExploreSection()
    }
    .background(Theme.Colors.background)
}
