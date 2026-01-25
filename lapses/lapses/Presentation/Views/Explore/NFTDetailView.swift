//
//  NFTDetailView.swift
//  lapses
//
//  Full-screen NFT detail view with buy/offer actions
//

import SwiftUI

// MARK: - NFT Detail View

struct NFTDetailView: View {
    let listing: LapseNFTListing
    @Environment(\.dismiss) private var dismiss
    @State private var showBuySheet = false
    @State private var showOfferSheet = false
    @State private var isSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image
                heroImage

                // Content
                VStack(spacing: 24) {
                    // Title and creator
                    titleSection

                    // Price section
                    priceSection

                    // Stats
                    statsSection

                    // Price history chart
                    priceHistorySection

                    // Details
                    detailsSection

                    // Actions
                    actionButtons

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, 20)
            }
        }
        .background(Theme.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        isSaved.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18))
                            .foregroundStyle(isSaved ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                    }

                    Button {
                        // Share action
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        ZStack(alignment: .topLeading) {
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
                                    Theme.Colors.primaryFallback.opacity(0.3),
                                    Theme.Colors.primaryFallback.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                @unknown default:
                    Color.gray.opacity(0.2)
                }
            }
            .frame(height: 350)
            .clipped()

            // Time badge overlay
            if let time = listing.formattedTimeRemaining {
                HStack(spacing: 6) {
                    if listing.urgencyLevel == .critical || listing.urgencyLevel == .high {
                        Circle()
                            .fill(listing.urgencyLevel.color)
                            .frame(width: 8, height: 8)
                    }
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text(time)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(listing.urgencyLevel.color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.7))
                )
                .padding(16)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with verified
            HStack(spacing: 8) {
                Text(listing.nft.epochTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if listing.isHot {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }

            // Creator
            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Text(String(listing.authorDisplayName.prefix(2)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }

                Text("by")
                    .foregroundStyle(Theme.Colors.textTertiary)

                Text(listing.authorDisplayName)
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
            .font(.system(size: 14, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Price")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    HStack(spacing: 6) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.primaryFallback)

                        Text(listing.formattedPrice ?? "Not Listed")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }

                Spacer()

                // Price change indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("24h")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                        Text("+12.5%")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.surfaceElevated)
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(title: "Views", value: listing.formattedViewCount, icon: "eye.fill")
            Divider().frame(height: 40)
            statItem(title: "Likes", value: "\(listing.likeCount)", icon: "heart.fill")
            Divider().frame(height: 40)
            statItem(title: "Owners", value: "1", icon: "person.fill")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.surfaceElevated)
        )
    }

    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Price History Section

    private var priceHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price History")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            // Mock chart
            PriceHistoryChart()
                .frame(height: 120)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.surfaceElevated)
        )
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: 10) {
                detailRow(label: "Contract", value: listing.nft.contractAddress.abbreviated)
                detailRow(label: "Token ID", value: "#\(listing.nft.id)")
                detailRow(label: "Chain", value: "Sepolia")
                detailRow(label: "Created", value: listing.createdAt.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.surfaceElevated)
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Make Offer
            Button {
                showOfferSheet = true
            } label: {
                Text("Make Offer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryFallback)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.Colors.primaryFallback, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)

            // Buy Now
            if listing.isListed {
                Button {
                    showBuySheet = true
                } label: {
                    Text("Buy Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.Colors.primaryFallback)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Price History Chart

private struct PriceHistoryChart: View {
    @State private var progress: CGFloat = 0

    private let prices: [CGFloat] = [0.03, 0.035, 0.032, 0.04, 0.038, 0.045, 0.05, 0.048, 0.055, 0.052]

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minPrice = prices.min() ?? 0
            let maxPrice = prices.max() ?? 1
            let range = maxPrice - minPrice
            let stepX = width / CGFloat(prices.count - 1)

            ZStack {
                // Grid lines
                ForEach(0..<4, id: \.self) { i in
                    Path { path in
                        let y = height * CGFloat(i) / 3
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Theme.Colors.surface, lineWidth: 1)
                }

                // Chart fill
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, price) in prices.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = (price - minPrice) / range
                        let y = height - (normalizedY * height * 0.8) - height * 0.1
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.primaryFallback.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    Rectangle()
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                )

                // Chart line
                Path { path in
                    for (index, price) in prices.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = (price - minPrice) / range
                        let y = height - (normalizedY * height * 0.8) - height * 0.1

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: progress)
                .stroke(Theme.Colors.primaryFallback, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1)) {
                progress = 1
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NFTDetailView(listing: LapseNFTListing.mockListings().first!)
    }
}
