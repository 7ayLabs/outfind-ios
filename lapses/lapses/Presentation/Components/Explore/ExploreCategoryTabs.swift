//
//  ExploreCategoryTabs.swift
//  lapses
//
//  Category tabs for the Explore view with icon + text style
//

import SwiftUI

// MARK: - Explore Category

enum ExploreCategory: String, CaseIterable, Sendable {
    case nfts = "NFTs"
    case predictions = "Predictions"

    var icon: String {
        switch self {
        case .nfts:
            return "square.stack.3d.up.fill"
        case .predictions:
            return "chart.bar.fill"
        }
    }
}

// MARK: - Category Tabs View

struct ExploreCategoryTabs: View {
    @Binding var selectedCategory: ExploreCategory
    @Namespace private var tabAnimation

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(ExploreCategory.allCases, id: \.self) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 8)
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
            VStack(spacing: 6) {
                // Icon + Text
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.system(size: 13, weight: .semibold))

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
