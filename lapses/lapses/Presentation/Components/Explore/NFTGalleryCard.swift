//
//  NFTGalleryCard.swift
//  lapses
//
//  Card component for NFT gallery listings
//

import SwiftUI

// MARK: - NFT Gallery Card

struct NFTGalleryCard: View {
    let listing: LapseNFTListing
    let onTap: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with countdown overlay
            imageSection

            // Info section
            infoSection
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.surfaceElevated)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Image Section

    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            // Preview image
            AsyncImage(url: listing.previewImageURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            ProgressView()
                                .tint(Theme.Colors.textTertiary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 180)
            .clipped()

            // Badges overlay
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    // Hot badge
                    if listing.isHot {
                        HotBadge()
                    }

                    Spacer()

                    // Countdown badge
                    if listing.expiresAt != nil {
                        CountdownBadge(expiresAt: listing.expiresAt)
                    }
                }

                Spacer()
            }
            .padding(10)
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(listing.nft.epochTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            // Author
            Text("by \(listing.authorDisplayName)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)

            // Price and stats row
            HStack {
                // Price or listed status
                if let price = listing.formattedPrice {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(price)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        Text("Listed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                } else {
                    Text("Not Listed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Spacer()

                // Views
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 11))
                    Text(listing.formattedViewCount)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.textTertiary)
            }

            // Action buttons
            HStack(spacing: 8) {
                // View details button
                Button(action: onTap) {
                    Text("View Details")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.primaryFallback.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                // Like button
                Button(action: onLike) {
                    Image(systemName: listing.isLikedByUser ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(listing.isLikedByUser ? .red : Theme.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.surface)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
    }
}

// MARK: - Compact NFT Card

struct CompactNFTCard: View {
    let listing: LapseNFTListing
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                AsyncImage(url: listing.previewImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Theme.Colors.surface)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.nft.epochTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let price = listing.formattedPrice {
                            Text(price)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.Colors.primaryFallback)
                        }

                        if listing.isHot {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                Text("Hot")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(.orange)
                        }

                        Text("\(listing.formattedViewCount) views")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                }

                Spacer()

                // Urgency indicator
                if listing.urgencyLevel != .none && listing.urgencyLevel != .normal {
                    Circle()
                        .fill(listing.urgencyLevel.color)
                        .frame(width: 8, height: 8)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.surfaceElevated)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - My Collection Card

struct MyCollectionCard: View {
    let listing: LapseNFTListing
    let onListForSale: () -> Void
    let onUnlist: () -> Void
    let onView: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: listing.previewImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Rectangle()
                        .fill(Theme.Colors.surface)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(Theme.Colors.textTertiary)
                        )
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.nft.epochTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text("Created \(listing.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                if let price = listing.formattedPrice {
                    Text("Listed at \(price)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }

            Spacer()

            // Action button
            if listing.isListed {
                Button(action: onUnlist) {
                    Text("Unlist")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.error.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onListForSale) {
                    Text("List for Sale")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.primaryFallback.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.surfaceElevated)
        )
        .onTapGesture {
            onView()
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            Text("Gallery Cards")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(LapseNFTListing.mockListings().prefix(4)) { listing in
                    NFTGalleryCard(
                        listing: listing,
                        onTap: { print("Tapped \(listing.id)") },
                        onLike: { print("Liked \(listing.id)") },
                        onSave: { print("Saved \(listing.id)") }
                    )
                }
            }

            Divider()

            Text("Compact Cards")
                .font(.headline)

            ForEach(LapseNFTListing.mockListings().prefix(3)) { listing in
                CompactNFTCard(listing: listing) {
                    print("Tapped compact \(listing.id)")
                }
            }

            Divider()

            Text("My Collection Cards")
                .font(.headline)

            ForEach(LapseNFTListing.mockMyCollection()) { listing in
                MyCollectionCard(
                    listing: listing,
                    onListForSale: { print("List \(listing.id)") },
                    onUnlist: { print("Unlist \(listing.id)") },
                    onView: { print("View \(listing.id)") }
                )
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
