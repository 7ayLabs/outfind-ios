//
//  LapsersExploreSection.swift
//  lapses
//
//  Ephemeral presence token discovery and trading section
//

import SwiftUI

// MARK: - Lapser Filter

enum LapserFilter: String, CaseIterable {
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

// MARK: - Lapsers Explore Section

struct LapsersExploreSection: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var tokens: [LapserToken] = []
    @State private var isLoading = true
    @State private var sectionAppeared = false
    @State private var selectedFilter: LapserFilter = .trending
    @State private var selectedToken: LapserToken?

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
        .sheet(item: $selectedToken) { token in
            LapserTokenDetailSheet(token: token)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 16) {
            // Filter tabs
            filterTabs

            // Tokens list
            if !filteredTokens.isEmpty {
                tokensList
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
                ForEach(LapserFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func filterTab(_ filter: LapserFilter) -> some View {
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

    // MARK: - Tokens List

    private var tokensList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(filteredTokens.enumerated()), id: \.element.id) { index, token in
                VStack(spacing: 0) {
                    LapserTokenRow(token: token)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedToken = token
                        }
                        .opacity(sectionAppeared ? 1 : 0)
                        .offset(y: sectionAppeared ? 0 : 20)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.04),
                            value: sectionAppeared
                        )

                    if index < filteredTokens.count - 1 {
                        Divider()
                            .background(Theme.Colors.surface)
                            .padding(.leading, 80)
                    }
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

    // MARK: - Filtered Tokens

    private var filteredTokens: [LapserToken] {
        switch selectedFilter {
        case .trending:
            return tokens.sorted { $0.priceChange24h > $1.priceChange24h }
        case .top:
            return tokens.sorted { $0.marketCap > $1.marketCap }
        case .new:
            return tokens.sorted { $0.lastActiveAt > $1.lastActiveAt }
        case .live:
            return tokens.filter { $0.activeEpochCount > 0 }.sorted { $0.activeEpochCount > $1.activeEpochCount }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No lapsers found")
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

            // Token row skeletons
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { index in
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            // Avatar skeleton
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.Colors.surface)
                                .frame(width: 56, height: 56)
                                .shimmer(isActive: true)

                            // Name/username skeleton
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 100, height: 16)
                                    .shimmer(isActive: true)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 80, height: 14)
                                    .shimmer(isActive: true)
                            }

                            Spacer()

                            // Chart skeleton
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.Colors.surface)
                                .frame(width: 80, height: 32)
                                .shimmer(isActive: true)

                            // Price skeleton
                            VStack(alignment: .trailing, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 60, height: 16)
                                    .shimmer(isActive: true)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Theme.Colors.surface)
                                    .frame(width: 70, height: 14)
                                    .shimmer(isActive: true)
                            }
                        }
                        .padding(.vertical, 12)

                        if index < 7 {
                            Divider()
                                .background(Theme.Colors.surface)
                                .padding(.leading, 80)
                        }
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
            let fetchedTokens = try await dependencies.lapserTokenRepository.fetchTrendingTokens()
            await MainActor.run {
                tokens = fetchedTokens
                isLoading = false
            }
        } catch {
            await MainActor.run {
                tokens = LapserToken.mockTokens()
                isLoading = false
            }
        }
    }
}

// MARK: - Lapser Token Row

struct LapserTokenRow: View {
    let token: LapserToken
    @State private var chartAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            avatarView

            // Name and username
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(token.creatorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    if token.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                }

                HStack(spacing: 4) {
                    if token.activeEpochCount > 0 {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    Text("@\(token.creatorUsername)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Sparkline chart
            AnimatedSparkline(
                data: token.priceHistory,
                isPositive: token.isPriceUp,
                width: 80,
                height: 32
            )
            .opacity(chartAppeared ? 1 : 0)
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                        chartAppeared = true
                    }
                } else {
                    chartAppeared = true
                }
            }

            // Price and change
            VStack(alignment: .trailing, spacing: 4) {
                Text(token.formattedPrice)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 3) {
                    Image(systemName: token.isPriceUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text(formatPercentage(token.priceChange24h))
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(token.isPriceUp ? .green : .red)
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.vertical, 12)
    }

    private var avatarView: some View {
        AsyncImage(url: token.creatorAvatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure, .empty:
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Theme.Colors.primaryFallback.opacity(0.3), Theme.Colors.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Text(String(token.creatorName.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
            @unknown default:
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            if token.isVerified {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.Colors.primaryFallback.opacity(0.5), lineWidth: 2)
            }
        }
    }

    private func formatPercentage(_ value: Double) -> String {
        if abs(value) >= 10000 {
            return String(format: "%.0f%%", value)
        } else if abs(value) >= 1000 {
            return String(format: "%.1f%%", value)
        } else if abs(value) >= 100 {
            return String(format: "%.1f%%", value)
        }
        return String(format: "%.2f%%", value)
    }
}

// MARK: - Lapser Token Detail Sheet

struct LapserTokenDetailSheet: View {
    let token: LapserToken
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var chartProgress: CGFloat = 0
    @State private var selectedPeriod: Int = 1

    private let periods = ["1H", "1D", "1W", "1M", "All"]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                sheetHeader

                // Profile section
                profileSection
                    .padding(.top, 24)

                // Price + Change
                priceSection
                    .padding(.top, 20)

                // Chart
                chartSection
                    .padding(.top, 16)

                // Period selector
                periodSelector
                    .padding(.top, 12)

                // Key metrics
                metricsGrid
                    .padding(.top, 24)

                // Presence info
                presenceSection
                    .padding(.top, 20)

                // Actions
                actionButtons
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Theme.Colors.background)
        .scrollIndicators(.hidden)
        .onAppear {
            animateChart()
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            // Drag indicator centered
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.Colors.surface))
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        HStack(spacing: 16) {
            // Avatar
            AsyncImage(url: token.creatorAvatarURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.3), Theme.Colors.surface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Text(String(token.creatorName.prefix(1)).uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(token.creatorName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    if token.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 0.3, green: 0.7, blue: 0.9))
                    }
                }

                Text("@\(token.creatorUsername)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                // Status badges
                HStack(spacing: 8) {
                    if token.activeEpochCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Active")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.green)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(formatCompact(Double(token.holders)))")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Price Section

    private var priceSection: some View {
        HStack(alignment: .firstTextBaseline) {
            // Price
            Text(token.formattedPrice)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            // Change indicator
            HStack(spacing: 4) {
                Image(systemName: token.isPriceUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 10, weight: .bold))
                Text(formatChangeCompact(token.priceChange24h))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(token.isPriceUp ? Color(red: 0.2, green: 0.8, blue: 0.5) : Color.red)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill((token.isPriceUp ? Color(red: 0.2, green: 0.8, blue: 0.5) : Color.red).opacity(0.12))
            )
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        DetailChartView(
            data: token.priceHistory,
            progress: reduceMotion ? 1 : chartProgress,
            isPositive: token.isPriceUp
        )
        .frame(height: 140)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(periods.enumerated()), id: \.offset) { index, period in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25)) {
                        selectedPeriod = index
                    }
                    animateChart()
                } label: {
                    Text(period)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedPeriod == index ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedPeriod == index ? Theme.Colors.surface : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.Colors.surface.opacity(0.5))
        )
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                icon: "chart.bar.fill",
                iconColor: Color(red: 0.95, green: 0.75, blue: 0.25),
                label: "Market Cap",
                value: token.formattedMarketCap
            )

            metricCard(
                icon: "arrow.left.arrow.right",
                iconColor: Color(red: 0.3, green: 0.7, blue: 0.9),
                label: "24h Volume",
                value: token.formattedVolume
            )

            metricCard(
                icon: "flame.fill",
                iconColor: Color(red: 0.95, green: 0.6, blue: 0.2),
                label: "24h High",
                value: formatPrice(highPrice)
            )

            metricCard(
                icon: "arrow.down.to.line",
                iconColor: Color(red: 0.6, green: 0.4, blue: 0.9),
                label: "24h Low",
                value: formatPrice(lowPrice)
            )
        }
    }

    private func metricCard(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.surface.opacity(0.4))
        )
    }

    // MARK: - Presence Section

    private var presenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Presence")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: 16) {
                // Presence Score
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        PresenceScoreRing(score: token.totalPresenceScore)
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f", token.totalPresenceScore))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text("Score")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Active epochs
                VStack(alignment: .center, spacing: 2) {
                    Text("\(token.activeEpochCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Epochs")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Spacer()

                // Last active
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeAgo(token.lastActiveAt))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Last active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.surface.opacity(0.4))
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Buy")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Theme.Colors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.success)
                )
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Sell")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.surface)
                )
            }
        }
    }

    // MARK: - Helpers

    private var highPrice: Double {
        token.currentPrice * 1.08
    }

    private var lowPrice: Double {
        token.currentPrice * 0.92
    }

    private func animateChart() {
        chartProgress = 0
        guard !reduceMotion else {
            chartProgress = 1
            return
        }
        withAnimation(.easeOut(duration: 0.6)) {
            chartProgress = 1
        }
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }

    private func formatPrice(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }

    private func formatChangeCompact(_ value: Double) -> String {
        if abs(value) >= 1000 {
            return String(format: "%.0f%%", value)
        }
        return String(format: "%.1f%%", value)
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }
}

// MARK: - Detail Chart View

private struct DetailChartView: View {
    let data: [Double]
    let progress: CGFloat
    let isPositive: Bool

    private var chartColor: Color {
        isPositive ? Color(red: 0.2, green: 0.8, blue: 0.5) : Color.red
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        if i > 0 { Spacer() }
                        Rectangle()
                            .fill(Theme.Colors.surface.opacity(0.5))
                            .frame(height: 1)
                    }
                }

                // Fill gradient
                ChartFillPath(data: data, progress: progress)
                    .fill(
                        LinearGradient(
                            colors: [chartColor.opacity(0.2), chartColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Line
                ChartLinePath(data: data, progress: progress)
                    .stroke(
                        chartColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )

                // End dot
                if progress > 0.95 {
                    let point = calculateEndPoint(width: width, height: height)
                    Circle()
                        .fill(chartColor)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
            }
        }
    }

    private func calculateEndPoint(width: CGFloat, height: CGFloat) -> CGPoint {
        guard let last = data.last, !data.isEmpty else {
            return CGPoint(x: width, y: height / 2)
        }
        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 100
        let range = maxVal - minVal
        let normalizedY = range > 0 ? (last - minVal) / range : 0.5
        return CGPoint(x: width - 4, y: height - CGFloat(normalizedY) * height * 0.85 - height * 0.075)
    }
}

// MARK: - Chart Paths

private struct ChartLinePath: Shape {
    let data: [Double]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }

        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 100
        let range = maxVal - minVal
        let stepX = rect.width / CGFloat(data.count - 1)

        let visibleCount = Int(CGFloat(data.count) * progress)
        guard visibleCount > 0 else { return path }

        for (i, value) in data.prefix(visibleCount).enumerated() {
            let normalizedY = range > 0 ? (value - minVal) / range : 0.5
            let x = CGFloat(i) * stepX
            let y = rect.height - CGFloat(normalizedY) * rect.height * 0.85 - rect.height * 0.075

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                let prev = data[i - 1]
                let prevNormY = range > 0 ? (prev - minVal) / range : 0.5
                let prevX = CGFloat(i - 1) * stepX
                let prevY = rect.height - CGFloat(prevNormY) * rect.height * 0.85 - rect.height * 0.075
                let midX = (prevX + x) / 2
                path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: midX, y: prevY))
            }
        }
        return path
    }
}

private struct ChartFillPath: Shape {
    let data: [Double]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }

        let minVal = data.min() ?? 0
        let maxVal = data.max() ?? 100
        let range = maxVal - minVal
        let stepX = rect.width / CGFloat(data.count - 1)

        let visibleCount = Int(CGFloat(data.count) * progress)
        guard visibleCount > 0 else { return path }

        let firstValue = data[0]
        let firstNormY = range > 0 ? (firstValue - minVal) / range : 0.5
        let firstY = rect.height - CGFloat(firstNormY) * rect.height * 0.85 - rect.height * 0.075

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: firstY))

        for (i, value) in data.prefix(visibleCount).enumerated() {
            let normalizedY = range > 0 ? (value - minVal) / range : 0.5
            let x = CGFloat(i) * stepX
            let y = rect.height - CGFloat(normalizedY) * rect.height * 0.85 - rect.height * 0.075

            if i > 0 {
                let prev = data[i - 1]
                let prevNormY = range > 0 ? (prev - minVal) / range : 0.5
                let prevX = CGFloat(i - 1) * stepX
                let prevY = rect.height - CGFloat(prevNormY) * rect.height * 0.85 - rect.height * 0.075
                let midX = (prevX + x) / 2
                path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: midX, y: prevY))
            }
        }

        let lastX = CGFloat(visibleCount - 1) * stepX
        path.addLine(to: CGPoint(x: lastX, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Presence Score Ring

private struct PresenceScoreRing: View {
    let score: Double

    private var progress: CGFloat {
        CGFloat(min(score, 100) / 100)
    }

    private var ringColor: Color {
        if score >= 90 { return Color(red: 0.2, green: 0.8, blue: 0.5) }
        if score >= 70 { return Color(red: 0.95, green: 0.75, blue: 0.25) }
        return Color(red: 0.95, green: 0.6, blue: 0.2)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.surface, lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Stat Row Helper

private func statRowView(label: String, value: String) -> some View {
    HStack {
        Text(label)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.Colors.textSecondary)
        Spacer()
        Text(value)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.Colors.textPrimary)
    }
    .padding(.vertical, 14)
}

// MARK: - Preview

#Preview {
    ScrollView {
        LapsersExploreSection()
    }
    .background(Theme.Colors.background)
}
