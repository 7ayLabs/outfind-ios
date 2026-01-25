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
    @State private var selectedMarket: PredictionMarket?
    @State private var voteSelection: VoteSelection?

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
        .sheet(item: $selectedMarket) { market in
            PredictionDetailSheet(market: market)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $voteSelection) { selection in
            VoteInputSheet(
                market: selection.market,
                option: selection.option,
                side: selection.side
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
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
        LazyVStack(spacing: 12) {
            ForEach(Array(filteredMarkets.enumerated()), id: \.element.id) { index, market in
                MarketListCard(market: market) { option, side in
                    voteSelection = VoteSelection(market: market, option: option, side: side)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedMarket = market
                }
                .opacity(sectionAppeared ? 1 : 0)
                .offset(y: sectionAppeared ? 0 : 20)
                .animation(
                    reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05),
                    value: sectionAppeared
                )
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
            // Filter tabs skeleton
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

            // Card skeletons
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 16) {
                        // Header skeleton
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.Colors.surface)
                                .frame(width: 52, height: 52)
                                .shimmer(isActive: true)

                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 180, height: 16)
                                    .shimmer(isActive: true)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 120, height: 14)
                                    .shimmer(isActive: true)
                            }

                            Spacer()
                        }

                        // Options skeleton
                        ForEach(0..<2, id: \.self) { _ in
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 3, height: 28)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 100, height: 14)
                                    .shimmer(isActive: true)

                                Spacer()

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 35, height: 14)
                                    .shimmer(isActive: true)

                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.Colors.surface)
                                        .frame(width: 52, height: 32)
                                        .shimmer(isActive: true)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.Colors.surface)
                                        .frame(width: 52, height: 32)
                                        .shimmer(isActive: true)
                                }
                            }
                        }

                        // Footer skeleton
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.surface)
                                .frame(width: 70, height: 12)
                                .shimmer(isActive: true)

                            Spacer()

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.surface)
                                .frame(width: 90, height: 12)
                                .shimmer(isActive: true)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.surface.opacity(0.3))
                    )
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

// MARK: - Currency Formatter

private func formatVolume(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "$%.2fM", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "$%.2fK", value / 1_000)
    }
    return String(format: "$%.0f", value)
}

// MARK: - Prediction Option

private struct PredictionOption: Identifiable {
    let id = UUID()
    let label: String
    let percentage: Double
    let isHighlighted: Bool
}

// MARK: - Vote Selection

private struct VoteSelection: Identifiable {
    let id = UUID()
    let market: PredictionMarket
    let option: PredictionOption
    let side: PredictionSide
}

// MARK: - Market List Card

private struct MarketListCard: View {
    let market: PredictionMarket
    let onVote: (PredictionOption, PredictionSide) -> Void

    // Generate mock options based on market type
    private var options: [PredictionOption] {
        let hashSeed = UInt64(bitPattern: Int64(market.id.hashValue))
        var seededRandom = SeededRandomGenerator(seed: hashSeed)

        switch market.predictionType {
        case .participation:
            let opt1Pct = market.yesPercentage * 0.3
            let opt2Pct = market.yesPercentage * 0.7
            return [
                PredictionOption(label: "Below target", percentage: opt1Pct, isHighlighted: false),
                PredictionOption(label: "Above target", percentage: opt2Pct, isHighlighted: true)
            ]
        case .creatorAttendance:
            return [
                PredictionOption(label: "On time", percentage: market.yesPercentage * 0.8, isHighlighted: true),
                PredictionOption(label: "Late arrival", percentage: market.yesPercentage * 0.2, isHighlighted: false)
            ]
        case .epochSuccess:
            let variance = seededRandom.next() * 10
            return [
                PredictionOption(label: "Full success", percentage: market.yesPercentage - variance, isHighlighted: true),
                PredictionOption(label: "Partial", percentage: variance + 5, isHighlighted: false)
            ]
        }
    }

    private var otherOptionsCount: Int {
        let hash = market.id.hashValue
        return 2 + abs(hash % 14)
    }

    // Cash value (ETH pool * USD conversion)
    private var volumeValue: Double {
        let hash = abs(market.id.hashValue % 100)
        return market.totalPool * 3200 * (80 + Double(hash))
    }

    // Test image URL
    private var imageURL: URL? {
        URL(string: "https://picsum.photos/seed/pred\(abs(market.id.hashValue) % 100)/100/100")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Image + Question
            HStack(alignment: .top, spacing: 12) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.surface)
                            .overlay {
                                Image(systemName: market.predictionType.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(market.question)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }

            // Options list
            VStack(spacing: 10) {
                ForEach(options) { option in
                    optionRow(option)
                }
            }

            // Footer: +X others + Volume
            HStack {
                Text("+\(otherOptionsCount) others")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                Spacer()

                Text("\(formatVolume(volumeValue)) Vol.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.surface.opacity(0.6))
        )
    }

    // MARK: - Option Row

    private func optionRow(_ option: PredictionOption) -> some View {
        HStack(spacing: 10) {
            // Left indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(option.isHighlighted ? Color.green : Color.clear)
                .frame(width: 3, height: 28)

            // Option label
            Text(option.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineLimit(1)

            Spacer()

            // Percentage
            Text(option.percentage < 1 ? "<1%" : "\(Int(option.percentage))%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 40, alignment: .trailing)

            // Yes/No buttons - now actionable
            HStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onVote(option, .yes)
                } label: {
                    Text("Yes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.15, green: 0.45, blue: 0.25))
                        .frame(width: 52, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onVote(option, .no)
                } label: {
                    Text("No")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 0.55, green: 0.2, blue: 0.2))
                        .frame(width: 52, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Vote Input Sheet

private struct VoteInputSheet: View {
    let market: PredictionMarket
    let option: PredictionOption
    let side: PredictionSide
    @Environment(\.dismiss) private var dismiss

    // State
    @State private var selectedAmount: Double = 25
    @State private var sliderProgress: CGFloat = 0.05
    @State private var isConfirming = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showSuccess = false

    private let maxAmount: Double = 500
    private let availableBalance: Double = 247.50
    private let quickAmounts: [Double] = [10, 25, 50, 100]

    // Computed
    private var potentialReturn: Double {
        let odds = side == .yes ? market.yesOdds : market.noOdds
        return selectedAmount * odds
    }

    private var probability: Double {
        side == .yes ? market.yesPercentage : market.noPercentage
    }

    private var canConfirm: Bool {
        selectedAmount > 0 && selectedAmount <= availableBalance
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                sheetHeader

                // Content
                VStack(spacing: 32) {
                    // Amount display
                    amountDisplay

                    // Slider
                    amountSlider

                    // Quick chips
                    quickChips

                    // Stats row
                    statsRow
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)

                Spacer()

                // Confirm area
                confirmSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }

            if showSuccess {
                successOverlay
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Top bar
            HStack(alignment: .center) {
                // Close
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.Colors.surface))
                }

                Spacer()

                // Probability tag
                HStack(spacing: 5) {
                    Circle()
                        .fill(side == .yes ? Color.green : Color.red.opacity(0.8))
                        .frame(width: 6, height: 6)
                    Text("\(Int(probability))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(Theme.Colors.surface)
                )

                Spacer()

                // Multiplier
                Text("\(String(format: "%.1fx", side == .yes ? market.yesOdds : market.noOdds))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(side == .yes ? Color.green : Color.red.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(side == .yes ? Color.green.opacity(0.3) : Color.red.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Question + Option
            VStack(spacing: 12) {
                Text(market.question)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Option + Side
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(option.isHighlighted ? Color.green : Theme.Colors.textTertiary)
                            .frame(width: 2, height: 12)
                        Text(option.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Text("•")
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(side == .yes ? "Yes" : "No")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(side == .yes ? Color.green : Color.red.opacity(0.85))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(String(format: "%.0f", selectedAmount))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25), value: selectedAmount)
        }
    }

    // MARK: - Amount Slider

    private var amountSlider: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let width = geo.size.width

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Theme.Colors.surface)
                        .frame(height: 8)

                    // Fill
                    Capsule()
                        .fill(side == .yes ? Color.green : Color.red.opacity(0.75))
                        .frame(width: max(20, width * sliderProgress), height: 8)

                    // Thumb
                    Circle()
                        .fill(Theme.Colors.textPrimary)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .offset(x: max(0, min(width - 24, width * sliderProgress - 12)))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let progress = max(0, min(1, value.location.x / width))
                                    sliderProgress = progress
                                    selectedAmount = round(progress * maxAmount)
                                }
                        )
                }
            }
            .frame(height: 24)

            // Labels
            HStack {
                Text("$0")
                Spacer()
                Text("$\(Int(maxAmount))")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    // MARK: - Quick Chips

    private var quickChips: some View {
        HStack(spacing: 8) {
            ForEach(quickAmounts, id: \.self) { amount in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25)) {
                        selectedAmount = amount
                        sliderProgress = amount / maxAmount
                    }
                } label: {
                    Text("$\(Int(amount))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedAmount == amount ? Theme.Colors.textOnAccent : Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedAmount == amount
                                      ? (side == .yes ? Color.green : Color.red.opacity(0.8))
                                      : Theme.Colors.surface)
                        )
                }
                .buttonStyle(.plain)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.25)) {
                    selectedAmount = min(availableBalance, maxAmount)
                    sliderProgress = selectedAmount / maxAmount
                }
            } label: {
                Text("MAX")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.surface, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            // Balance
            VStack(spacing: 4) {
                Text("Balance")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("$\(String(format: "%.0f", availableBalance))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Theme.Colors.surface)
                .frame(width: 1, height: 32)

            // Return
            VStack(spacing: 4) {
                Text("Return")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("$\(String(format: "%.0f", potentialReturn))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(side == .yes ? Color.green : Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Theme.Colors.surface)
                .frame(width: 1, height: 32)

            // Profit
            VStack(spacing: 4) {
                Text("Profit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("+$\(String(format: "%.0f", potentialReturn - selectedAmount))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.green)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.surface.opacity(0.5))
        )
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        VStack(spacing: 12) {
            // Swipe to confirm
            GeometryReader { geo in
                let width = geo.size.width
                let threshold = width * 0.65

                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.Colors.surface)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            (side == .yes ? Color.green : Color.red.opacity(0.7)).opacity(0.2)
                        )
                        .frame(width: max(56, swipeOffset + 56))

                    // Label
                    Text(canConfirm ? "Slide to confirm" : "Insufficient funds")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .opacity(swipeOffset < threshold * 0.4 ? 1 : 0)

                    // Thumb
                    RoundedRectangle(cornerRadius: 24)
                        .fill(canConfirm ? (side == .yes ? Color.green : Color.red.opacity(0.85)) : Theme.Colors.textTertiary.opacity(0.5))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: swipeOffset > threshold ? "checkmark" : "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textOnAccent)
                        )
                        .offset(x: swipeOffset + 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard canConfirm else { return }
                                    swipeOffset = max(0, min(width - 56, value.translation.width))
                                    if swipeOffset > threshold && !isConfirming {
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        isConfirming = true
                                    } else if swipeOffset < threshold {
                                        isConfirming = false
                                    }
                                }
                                .onEnded { _ in
                                    guard canConfirm else { return }
                                    if swipeOffset > threshold {
                                        withAnimation(.spring(response: 0.25)) {
                                            swipeOffset = width - 56
                                        }
                                        confirm()
                                    } else {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            swipeOffset = 0
                                            isConfirming = false
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 56)
            .opacity(canConfirm ? 1 : 0.5)

            // Disclaimer
            Text("Predictions are final and cannot be cancelled")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(side == .yes ? Color.green : Color.red.opacity(0.8))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnAccent)
                }

                VStack(spacing: 6) {
                    Text("Confirmed")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnAccent)

                    Text("$\(Int(selectedAmount)) on \(side == .yes ? "Yes" : "No")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textOnAccent.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Actions

    private func confirm() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.3)) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
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
