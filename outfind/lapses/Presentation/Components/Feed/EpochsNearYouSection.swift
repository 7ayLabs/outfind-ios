import SwiftUI

// MARK: - Epochs Near You Section

/// Section displaying popular/nearby epochs with large image cards.
/// Similar to "Group near you" design in reference images.
struct EpochsNearYouSection: View {
    let title: String
    let epochs: [Epoch]
    let bookmarkedIds: Set<UInt64>
    let onEpochTap: (UInt64) -> Void
    let onBookmark: (UInt64) -> Void
    let onDismiss: () -> Void

    init(
        title: String = "Epochs near you",
        epochs: [Epoch],
        bookmarkedIds: Set<UInt64> = [],
        onEpochTap: @escaping (UInt64) -> Void,
        onBookmark: @escaping (UInt64) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.epochs = epochs
        self.bookmarkedIds = bookmarkedIds
        self.onEpochTap = onEpochTap
        self.onBookmark = onBookmark
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            SectionHeader(
                title: title,
                showDismiss: true,
                onDismiss: onDismiss
            )

            // Horizontal scroll of nearby epoch cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(epochs) { epoch in
                        EpochNearbyCard(
                            epoch: epoch,
                            isBookmarked: bookmarkedIds.contains(epoch.id),
                            distance: formatDistance(for: epoch),
                            onTap: { onEpochTap(epoch.id) },
                            onBookmark: { onBookmark(epoch.id) }
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }

    private func formatDistance(for epoch: Epoch) -> String {
        let distances = ["0.5 mi", "1.2 mi", "2.3 mi", "4.9 mi", "0.8 mi"]
        return distances[Int(epoch.id) % distances.count]
    }
}

// MARK: - Epoch Nearby Card

/// Large card with full-width image, overlay title, and member count.
/// Design inspired by "Yoga Club" style cards in reference images.
struct EpochNearbyCard: View {
    let epoch: Epoch
    let isBookmarked: Bool
    let distance: String
    let onTap: () -> Void
    let onBookmark: () -> Void

    private let cardWidth: CGFloat = 300
    private let imageHeight: CGFloat = 180

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image with overlay
                imageArea

                // Info below image
                infoArea
            }
            .frame(width: cardWidth)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                    .fill(Theme.Colors.backgroundSecondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                    .strokeBorder(Theme.Colors.textTertiary.opacity(0.15), lineWidth: 1)
            }
            .shadow(Theme.Shadow.sm)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Image Area

    private var imageArea: some View {
        ZStack(alignment: .bottom) {
            // Gradient background (simulating image)
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: imageHeight)

            // Dark gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: Theme.CornerRadius.xl,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: Theme.CornerRadius.xl
                )
            )

            // Title overlay
            HStack(alignment: .bottom) {
                Text(epoch.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Spacer()

                // Bookmark button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    onBookmark()
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isBookmarked ? Theme.Colors.primaryFallback : .white)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial)
                        }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.CornerRadius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: Theme.CornerRadius.xl
            )
        )
    }

    private var gradientColors: [Color] {
        // Cycle through different colors based on epoch id
        let colorSets: [[Color]] = [
            [Color(hex: "667eea"), Color(hex: "764ba2")], // Purple
            [Color(hex: "f093fb"), Color(hex: "f5576c")], // Pink
            [Color(hex: "4facfe"), Color(hex: "00f2fe")], // Blue
            [Color(hex: "43e97b"), Color(hex: "38f9d7")], // Green
            [Color(hex: "fa709a"), Color(hex: "fee140")], // Warm
        ]
        return colorSets[Int(epoch.id) % colorSets.count]
    }

    // MARK: - Info Area

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Description
            if let description = epoch.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            // Member count and distance
            HStack(spacing: Theme.Spacing.md) {
                // Participant count (styled like "109 Members")
                Text("\(epoch.participantCount) Members")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                // Distance
                HStack(spacing: 2) {
                    Image(systemName: "location")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(distance)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .padding(Theme.Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            EpochsNearYouSection(
                title: "Popular epochs near you",
                epochs: Epoch.mockWithLocations(),
                bookmarkedIds: [1, 3],
                onEpochTap: { id in print("Tapped epoch \(id)") },
                onBookmark: { id in print("Bookmarked epoch \(id)") },
                onDismiss: { print("Dismissed") }
            )

            EpochsNearYouSection(
                title: "Groups near you",
                epochs: Array(Epoch.mockWithLocations().prefix(3)),
                onEpochTap: { _ in },
                onBookmark: { _ in },
                onDismiss: { }
            )
        }
        .padding(.vertical, Theme.Spacing.lg)
    }
    .background(Theme.Colors.background)
}
