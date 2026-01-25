import SwiftUI

// MARK: - Saved Insights Sheet

/// Sheet displayed when a post is saved via swipe gesture.
/// Design inspired by modern insight/bookmark UIs with stacked card visual.
struct SavedInsightsSheet: View {
    @Binding var isPresented: Bool
    let savedPost: EpochPost
    let allSavedPosts: [EpochPost]
    let onCreateNew: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var selectedFilter: SavedFilter = .all
    @State private var cardStackOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Soft pink/white gradient background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                dragIndicator
                    .padding(.top, Theme.Spacing.sm)

                // Header
                sheetHeader
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                // Filter chips
                filterChips
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                // Stacked cards visual
                stackedCardsView
                    .padding(.top, Theme.Spacing.lg)

                // Main saved card
                mainSavedCard
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)

                // Quote content
                quoteContent
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)

                Spacer()

                // Create new button
                createNewButton
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            startIdleAnimation()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")]
                : [Color(hex: "FFF5F5"), Theme.Colors.textOnAccent],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        Capsule()
            .fill(Theme.Colors.textTertiary.opacity(0.3))
            .frame(width: 36, height: 5)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Text("Saved Insights")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            // Close button with animation
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background {
                        Circle()
                            .fill(Theme.Colors.backgroundTertiary)
                    }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -20)
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                FilterChipButton(
                    title: "All",
                    icon: nil,
                    isSelected: selectedFilter == .all
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = .all
                    }
                }

                FilterChipButton(
                    title: "Audio Content",
                    icon: "waveform",
                    isSelected: selectedFilter == .audio
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = .audio
                    }
                }

                FilterChipButton(
                    title: "Categories",
                    icon: "folder",
                    isSelected: selectedFilter == .categories
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = .categories
                    }
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
    }

    // MARK: - Stacked Cards Visual

    private var stackedCardsView: some View {
        ZStack {
            // Background cards (stacked behind)
            ForEach(Array(allSavedPosts.prefix(3).enumerated()), id: \.element.id) { index, _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark
                          ? Theme.Colors.backgroundSecondary
                          : Theme.Colors.textOnAccent)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .frame(height: 60)
                    .offset(y: CGFloat(index) * 8 + cardStackOffset)
                    .scaleEffect(1 - CGFloat(index) * 0.03)
                    .opacity(1 - Double(index) * 0.2)
            }
        }
        .frame(height: 80)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)
    }

    // MARK: - Main Saved Card

    private var mainSavedCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Animated avatar
            AnimatedSaveAvatar(
                name: savedPost.author.name,
                avatarURL: savedPost.author.avatarURL
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(savedPost.author.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(savedPost.savedAt?.formatted(date: .abbreviated, time: .omitted) ?? "Just now")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            // Calendar icon button
            Button {
                // Open calendar/schedule action
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle()
                            .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark
                      ? Theme.Colors.backgroundSecondary
                      : Theme.Colors.textOnAccent)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
    }

    // MARK: - Quote Content

    private var quoteContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Quote marks
            Image(systemName: "quote.opening")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Theme.Colors.primaryFallback.opacity(0.5))

            // Content with highlighted portions
            Text(savedPost.content)
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineSpacing(5)
                .lineLimit(4)

            // Highlight chip (if content is long enough)
            if savedPost.content.count > 50 {
                highlightChip
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.primaryFallback.opacity(colorScheme == .dark ? 0.1 : 0.05))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appeared)
    }

    private var highlightChip: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Theme.Colors.primaryFallback)
                .frame(width: 6, height: 6)

            Text("Highlighted")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Colors.primaryFallback)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(Theme.Colors.primaryFallback.opacity(0.15))
        }
    }

    // MARK: - Create New Button

    private var createNewButton: some View {
        Button(action: onCreateNew) {
            HStack(spacing: 8) {
                Text("Create new")
                    .font(.system(size: 16, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(colorScheme == .dark ? Theme.Colors.textOnAccent : Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark
                          ? Theme.Colors.backgroundSecondary
                          : Color(hex: "1C1C1E"))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: appeared)
    }

    // MARK: - Idle Animation

    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            cardStackOffset = 3
        }
    }
}

// MARK: - Saved Filter Enum

enum SavedFilter {
    case all
    case audio
    case categories
}

// MARK: - Filter Chip Button

struct FilterChipButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? Theme.Colors.textOnAccent : Theme.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(isSelected
                          ? Theme.Colors.primaryFallback
                          : Theme.Colors.backgroundTertiary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Animated Save Avatar

struct AnimatedSaveAvatar: View {
    let name: String
    let avatarURL: URL?

    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Animated ring
            Circle()
                .stroke(Theme.Colors.primaryFallback.opacity(ringOpacity), lineWidth: 2)
                .frame(width: 52, height: 52)
                .scaleEffect(ringScale)

            // Avatar
            if let url = avatarURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    avatarPlaceholder
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                avatarPlaceholder
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(Theme.Colors.primaryFallback.opacity(0.15))
            .frame(width: 48, height: 48)
            .overlay {
                Text(String(name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            ringScale = 1.1
            ringOpacity = 0.5
        }
    }
}

// MARK: - Preview

#Preview {
    SavedInsightsSheet(
        isPresented: .constant(true),
        savedPost: EpochPost.mockPosts()[0],
        allSavedPosts: Array(EpochPost.mockPosts().prefix(5)),
        onCreateNew: {}
    )
}

#Preview("Dark Mode") {
    SavedInsightsSheet(
        isPresented: .constant(true),
        savedPost: EpochPost.mockPosts()[0],
        allSavedPosts: Array(EpochPost.mockPosts().prefix(5)),
        onCreateNew: {}
    )
    .preferredColorScheme(.dark)
}
