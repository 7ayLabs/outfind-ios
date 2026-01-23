import SwiftUI

// MARK: - Local Epochs Section

/// Hero section displaying featured/active epochs in horizontal scroll.
/// Includes dismissable header with "See More" button.
struct LocalEpochsSection: View {
    let epochs: [Epoch]
    let onEpochTap: (UInt64) -> Void
    let onDismiss: () -> Void
    let onSeeMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            SectionHeader(
                title: "Local Epochs",
                showDismiss: true,
                onDismiss: onDismiss
            )

            // Horizontal scroll of epoch cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(epochs) { epoch in
                        LocalEpochCard(
                            epoch: epoch,
                            distance: formatDistance(for: epoch),
                            onTap: { onEpochTap(epoch.id) }
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            // See More Button
            Button(action: onSeeMore) {
                Text("See More")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(Theme.Colors.backgroundSecondary)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .strokeBorder(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                    }
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func formatDistance(for epoch: Epoch) -> String {
        // In a real app, calculate from user's location
        // For now, return mock distance
        let distances = ["0.5 mi", "1.2 mi", "2.3 mi", "4.9 mi", "0.8 mi"]
        return distances[Int(epoch.id) % distances.count]
    }
}

// MARK: - Local Epoch Card

/// Large card for displaying featured epochs in horizontal scroll.
/// Shows image, title, description, rating, distance, and participant count.
struct LocalEpochCard: View {
    let epoch: Epoch
    let distance: String
    let onTap: () -> Void

    @State private var isFavorite = false

    private let cardWidth: CGFloat = 280
    private let imageHeight: CGFloat = 160

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image Area
                imageArea

                // Info Area
                infoArea
            }
            .frame(width: cardWidth)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Colors.backgroundSecondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .strokeBorder(Theme.Colors.textTertiary.opacity(0.15), lineWidth: 1)
            }
            .shadow(Theme.Shadow.sm)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Image Area

    private var imageArea: some View {
        ZStack(alignment: .topTrailing) {
            // Gradient background (simulating image)
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: imageHeight)
                .overlay(alignment: .topLeading) {
                    // State badge
                    if epoch.state == .active {
                        liveBadge
                            .padding(Theme.Spacing.sm)
                    }
                }

            // Favorite Button
            Button {
                withAnimation(Theme.Animation.spring) {
                    isFavorite.toggle()
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            } label: {
                Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isFavorite ? Theme.Colors.primaryFallback : .white)
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                    }
            }
            .padding(Theme.Spacing.sm)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.CornerRadius.lg,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: Theme.CornerRadius.lg
            )
        )
    }

    private var liveBadge: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Circle()
                .fill(Theme.Colors.epochActive)
                .frame(width: 6, height: 6)

            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(Color.black.opacity(0.5))
        }
    }

    private var gradientColors: [Color] {
        switch epoch.state {
        case .active:
            return [Theme.Colors.epochActive, Theme.Colors.epochActive.opacity(0.6)]
        case .scheduled:
            return [Theme.Colors.epochScheduled, Theme.Colors.epochScheduled.opacity(0.6)]
        default:
            return [Theme.Colors.primaryFallback, Theme.Colors.primaryFallback.opacity(0.6)]
        }
    }

    // MARK: - Info Area

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Title
            Text(epoch.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            // Description
            if let description = epoch.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)
            }

            // Footer: Rating, Participants, Distance
            HStack(spacing: Theme.Spacing.md) {
                // Rating (mock for now)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.warning)

                    Text("4.9")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                // Participants
                HStack(spacing: 2) {
                    Image(systemName: "person.2")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text("\(epoch.participantCount)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

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
            LocalEpochsSection(
                epochs: Epoch.mockWithLocations(),
                onEpochTap: { id in print("Tapped epoch \(id)") },
                onDismiss: { print("Dismissed") },
                onSeeMore: { print("See more") }
            )
        }
        .padding(.vertical, Theme.Spacing.lg)
    }
    .background(Theme.Colors.background)
}
