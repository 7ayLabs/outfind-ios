//
//  NFTsExploreSection.swift
//  lapses
//
//  NFT Gallery section with clean, minimalistic design
//

import SwiftUI

// MARK: - NFT Category

enum NFTCategory: String, CaseIterable {
    case all = "All"
    case trending = "Trending"
    case art = "Art"
    case collectibles = "Collectibles"
    case photography = "Photography"

    var icon: String? {
        switch self {
        case .all: return nil
        case .trending: return "flame"
        case .art: return "paintbrush"
        case .collectibles: return "square.stack.3d.up"
        case .photography: return "camera"
        }
    }
}

// MARK: - NFTs Explore Section

struct NFTsExploreSection: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var hotNFTs: [LapseNFTListing] = []
    @State private var epochCollections: [LapseNFTListing] = []
    @State private var isLoading = true
    @State private var sectionAppeared = false
    @State private var selectedCategory: NFTCategory = .all
    @State private var selectedListing: LapseNFTListing?

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
        .sheet(item: $selectedListing) { listing in
            NavigationStack {
                NFTDetailView(listing: listing)
            }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 24) {
            // Category pills
            categoryPills

            // Top Lapses Today
            if !hotNFTs.isEmpty {
                topLapsesSection
            }

            // Epoch Collections
            if !epochCollections.isEmpty {
                epochCollectionsSection
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Category Pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NFTCategory.allCases, id: \.self) { category in
                    categoryPill(category)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func categoryPill(_ category: NFTCategory) -> some View {
        let isSelected = selectedCategory == category

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                if let icon = category.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
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

    // MARK: - Top Lapses Section

    private var topLapsesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top lapses today")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(hotNFTs.prefix(6).enumerated()), id: \.element.id) { index, nft in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedListing = nft
                        } label: {
                            NFTCard(listing: nft)
                        }
                        .buttonStyle(ExploreCardButtonStyle())
                        .opacity(sectionAppeared ? 1 : 0)
                        .offset(y: sectionAppeared ? 0 : 20)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.06),
                            value: sectionAppeared
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation { sectionAppeared = true }
            } else {
                sectionAppeared = true
            }
        }
    }

    // MARK: - Epoch Collections Section

    private var epochCollectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Epoch collections")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(epochCollections.prefix(6)) { nft in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedListing = nft
                        } label: {
                            NFTCard(listing: nft, style: .collection)
                        }
                        .buttonStyle(ExploreCardButtonStyle())
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.Colors.surface)
                            .frame(width: 80, height: 36)
                            .shimmer(isActive: true)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.surface)
                            .frame(width: 200, height: 260)
                            .shimmer(isActive: true)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        do {
            let hot = try await dependencies.nftGalleryRepository.fetchHotNFTs()
            let recent = try await dependencies.nftGalleryRepository.fetchRecentNFTs()

            await MainActor.run {
                hotNFTs = hot
                epochCollections = recent
                isLoading = false
            }
        } catch {
            await MainActor.run {
                hotNFTs = LapseNFTListing.mockListings().filter { $0.isHot }
                epochCollections = LapseNFTListing.mockListings()
                isLoading = false
            }
        }
    }
}

// MARK: - NFT Card

private struct NFTCard: View {
    let listing: LapseNFTListing
    var style: CardStyle = .featured

    enum CardStyle {
        case featured, collection
    }

    // Mock 24h volume based on view count
    private var volume24h: String {
        let vol = Double(listing.viewCount) * 0.002 + Double(listing.likeCount) * 0.01
        if vol >= 1.0 {
            return String(format: "%.1f ETH", vol)
        } else {
            return String(format: "%.2f ETH", vol)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with overlay elements
            ZStack(alignment: .topLeading) {
                // Image
                AsyncImage(url: listing.previewImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.primaryFallback.opacity(0.2),
                                        Theme.Colors.primaryFallback.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 200, height: style == .featured ? 170 : 150)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Time badge (minimalistic)
                if let time = listing.formattedTimeRemaining {
                    MinimalTimeBadge(time: time, urgency: listing.urgencyLevel)
                        .padding(10)
                }
            }

            // Info section
            VStack(alignment: .leading, spacing: 8) {
                // Title with verified
                HStack(spacing: 4) {
                    Text(listing.nft.epochTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    if listing.isHot {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                }

                // Floor and Volume row
                HStack(spacing: 20) {
                    // Floor price
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Floor")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)

                        HStack(spacing: 3) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.Colors.primaryFallback)
                            Text(listing.formattedPrice ?? "—")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                    }

                    // 24h Volume
                    VStack(alignment: .leading, spacing: 2) {
                        Text("24h vol")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)

                        Text(volume24h)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 2)
        }
        .frame(width: 200)
    }
}

// MARK: - Minimal Time Badge

private struct MinimalTimeBadge: View {
    let time: String
    let urgency: UrgencyLevel

    private var badgeColor: Color {
        switch urgency {
        case .critical, .high:
            return .red
        case .moderate:
            return .orange
        default:
            return Theme.Colors.textPrimary
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if urgency == .critical || urgency == .high {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 5, height: 5)
            }

            Text(time)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(badgeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.black.opacity(0.6))
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        NFTsExploreSection()
    }
    .background(Theme.Colors.background)
}
