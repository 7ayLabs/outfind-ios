//
//  ExploreCategoryTabs.swift
//  lapses
//
//  Category tabs for the Explore view with animated Web3 icons
//

import SwiftUI

// MARK: - Explore Category

enum ExploreCategory: String, CaseIterable, Sendable {
    case lapsers = "Lapsers"
    case predictions = "Predictions"
    case journeys = "Journeys"
    case nfts = "NFTs"
    case leaderboard = "Leaderboard"
}

// MARK: - Category Tabs View

struct ExploreCategoryTabs: View {
    @Binding var selectedCategory: ExploreCategory
    @Namespace private var tabAnimation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(ExploreCategory.allCases, id: \.self) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Category Tab

    private func categoryTab(_ category: ExploreCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 8) {
                // Animated Icon + Text
                HStack(spacing: 8) {
                    categoryIcon(category, isActive: isSelected)
                        .frame(width: 20, height: 20)

                    Text(category.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                }
                .foregroundStyle(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)

                // Underline indicator
                Rectangle()
                    .fill(isSelected ? Theme.Colors.primaryFallback : .clear)
                    .frame(height: 2)
                    .matchedGeometryEffect(id: "categoryUnderline", in: tabAnimation, isSource: isSelected)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category Icon

    @ViewBuilder
    private func categoryIcon(_ category: ExploreCategory, isActive: Bool) -> some View {
        switch category {
        case .lapsers:
            AnimatedLapsersIcon(isActive: isActive, size: 20)
        case .predictions:
            AnimatedChartIcon(isActive: isActive, size: 20)
        case .journeys:
            AnimatedPathIcon(isActive: isActive, size: 20)
        case .nfts:
            AnimatedCubeIcon(isActive: isActive, size: 20)
        case .leaderboard:
            AnimatedLeaderboardIcon(isActive: isActive, size: 20)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ExploreCategory = .nfts

        var body: some View {
            VStack {
                ExploreCategoryTabs(selectedCategory: $selected)

                Spacer()

                Text("Selected: \(selected.rawValue)")
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
        }
    }

    return PreviewWrapper()
}
