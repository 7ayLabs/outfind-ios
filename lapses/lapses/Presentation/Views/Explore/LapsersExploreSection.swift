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

// MARK: - Lapser Token Detail Sheet (Placeholder)

struct LapserTokenDetailSheet: View {
    let token: LapserToken
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        AsyncImage(url: token.creatorAvatarURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Theme.Colors.surface)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                        VStack(spacing: 6) {
                            HStack(spacing: 8) {
                                Text(token.creatorName)
                                    .font(.system(size: 24, weight: .bold))
                                if token.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(Theme.Colors.primaryFallback)
                                }
                            }
                            Text("@\(token.creatorUsername)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    .padding(.top, 20)

                    // Price
                    VStack(spacing: 8) {
                        Text(token.formattedPrice)
                            .font(.system(size: 40, weight: .bold, design: .rounded))

                        HStack(spacing: 6) {
                            Image(systemName: token.isPriceUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(token.formattedChange)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(token.isPriceUp ? .green : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill((token.isPriceUp ? Color.green : Color.red).opacity(0.15))
                        )
                    }

                    // Chart
                    AnimatedSparkline(
                        data: token.priceHistory,
                        isPositive: token.isPriceUp,
                        width: UIScreen.main.bounds.width - 48,
                        height: 120
                    )
                    .padding(.horizontal, 24)

                    // Stats
                    VStack(spacing: 0) {
                        statRow(label: "Market Cap", value: token.formattedMarketCap)
                        Divider().background(Theme.Colors.surface)
                        statRow(label: "24h Volume", value: token.formattedVolume)
                        Divider().background(Theme.Colors.surface)
                        statRow(label: "Holders", value: "\(token.holders)")
                        Divider().background(Theme.Colors.surface)
                        statRow(label: "Active Epochs", value: "\(token.activeEpochCount)")
                        Divider().background(Theme.Colors.surface)
                        statRow(label: "Presence Score", value: String(format: "%.1f", token.totalPresenceScore))
                    }
                    .padding(.horizontal, 20)

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Text("Buy")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.green)
                                )
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Text("Sell")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(white: 0.3))
                                )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Theme.Colors.surface))
                    }
                }
            }
        }
    }

    private func statRow(label: String, value: String) -> some View {
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
}

// MARK: - Preview

#Preview {
    ScrollView {
        LapsersExploreSection()
    }
    .background(Theme.Colors.background)
}
