import SwiftUI

// MARK: - Profile Avatar With Badge

/// Avatar with glow effect and optional badge overlay
struct ProfileAvatarWithBadge: View {
    let avatarURL: URL?
    var badgeIcon: String?
    var size: CGFloat = 80
    var glowColor: Color = Theme.Colors.neonGreen

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(glowColor.opacity(0.3))
                    .frame(width: size + 16, height: size + 16)
                    .blur(radius: 16)

                // Avatar
                AsyncImage(url: avatarURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Theme.Colors.backgroundTertiary)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: size * 0.4))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(glowColor.opacity(0.6), lineWidth: 2)
                }
            }

            // Badge overlay
            if let badgeIcon = badgeIcon {
                Image(systemName: badgeIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background {
                        Circle()
                            .fill(Theme.Colors.primaryFallback)
                    }
                    .offset(x: 4, y: 4)
            }
        }
    }
}

// MARK: - Profile Action Button

/// Action button for chat or follow actions
struct ProfileActionButton: View {
    enum Style {
        case chat
        case follow(isFollowing: Bool)
    }

    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                if let title = title {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, title != nil ? 16 : 12)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(backgroundColor)
            }
            .overlay {
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var iconName: String {
        switch style {
        case .chat:
            return "message.fill"
        case .follow(let isFollowing):
            return isFollowing ? "checkmark" : "plus"
        }
    }

    private var title: String? {
        switch style {
        case .chat:
            return nil
        case .follow(let isFollowing):
            return isFollowing ? "Following" : "Follow"
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .chat:
            return Theme.Colors.textPrimary
        case .follow(let isFollowing):
            return isFollowing ? Theme.Colors.textPrimary : .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .chat:
            return Theme.Colors.backgroundSecondary
        case .follow(let isFollowing):
            return isFollowing ? Theme.Colors.backgroundSecondary : Theme.Colors.neonGreen
        }
    }

    private var borderColor: Color {
        switch style {
        case .chat:
            return Theme.Colors.textTertiary.opacity(0.3)
        case .follow(let isFollowing):
            return isFollowing ? Theme.Colors.neonGreen.opacity(0.5) : .clear
        }
    }
}

// MARK: - Profile Stats Row

/// Displays follower, following, and address counts
struct ProfileStatsRow: View {
    let followerCount: Int
    let followingCount: Int
    let addressCount: Int

    var body: some View {
        HStack(spacing: 20) {
            statItem(value: followerCount, label: "followers")
            Text("·")
                .foregroundStyle(Theme.Colors.textTertiary)
            statItem(value: followingCount, label: "following")

            Spacer()

            // Address indicator
            HStack(spacing: 4) {
                Image(systemName: "wallet.pass")
                    .font(.system(size: 12))
                Text("\(addressCount) addresses")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Theme.Colors.neonGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(Theme.Colors.neonGreen.opacity(0.15))
            }
        }
    }

    private func statItem(value: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Epoch Tag Chip

/// Pill-style tag with participant count
struct EpochTagChip: View {
    let tag: EpochTag

    var body: some View {
        HStack(spacing: 6) {
            Text(tag.name)
                .font(.system(size: 13, weight: .medium))
            Text("\(tag.participantCount)")
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(Theme.Colors.neonGreen.opacity(0.2))
                }
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Theme.Colors.backgroundSecondary)
        }
        .overlay {
            Capsule()
                .strokeBorder(Theme.Colors.neonGreen.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - Epoch Tags Section

/// Horizontal scrolling section of epoch tags
struct EpochTagsSection: View {
    let tags: [EpochTag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags) { tag in
                    EpochTagChip(tag: tag)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Followed By Section

/// Displays mutual connections with overlapping avatars
struct FollowedBySection: View {
    let mutualFollowers: [MutualFollower]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: -8) {
                // Overlapping avatars
                ForEach(Array(mutualFollowers.prefix(5).enumerated()), id: \.element.id) { index, follower in
                    AsyncImage(url: follower.avatarURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.primaryFallback, Theme.Colors.neonGreen.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Text(String(follower.name.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Theme.Colors.background, lineWidth: 2)
                    }
                    .zIndex(Double(5 - index))
                }

                if mutualFollowers.count > 5 {
                    Text("+\(mutualFollowers.count - 5)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.leading, 12)
                }
            }

            // Names text
            Text("Followed by \(formattedNames)")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    private var formattedNames: String {
        let names = mutualFollowers.prefix(3).map { $0.name }
        if mutualFollowers.count > 3 {
            return names.joined(separator: ", ") + " and \(mutualFollowers.count - 3) others you follow"
        }
        return names.joined(separator: " and ")
    }
}

// MARK: - Epoch NFT Card

/// NFT-style card for displaying epochs in grid
struct EpochNFTCard: View {
    let epoch: EpochNFT
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // NFT Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.neonGreen.opacity(0.4),
                                    Theme.Colors.primaryFallback.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Epoch icon overlay
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "circle.hexagongrid.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                            Spacer()
                        }
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(epoch.epochTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(epoch.participantCount)")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(10)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.backgroundSecondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.Colors.neonGreen.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Lapse NFT Card

/// NFT-style card for displaying lapses in grid
struct LapseNFTCard: View {
    let lapse: LapseItem
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image placeholder
                ZStack {
                    if let imageURL = lapse.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            gradientPlaceholder
                        }
                    } else {
                        gradientPlaceholder
                    }

                    // Lapse icon overlay
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(8)
                            Spacer()
                        }
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lapse.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    Text(lapse.createdAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(10)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.backgroundSecondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.Colors.primaryFallback.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var gradientPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.primaryFallback.opacity(0.5),
                        Theme.Colors.primaryFallback.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}


// MARK: - Previews

#Preview("Profile Avatar") {
    VStack(spacing: 20) {
        ProfileAvatarWithBadge(avatarURL: nil, badgeIcon: "music.note", size: 80)
        ProfileAvatarWithBadge(avatarURL: nil, size: 60)
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Action Buttons") {
    HStack(spacing: 12) {
        ProfileActionButton(style: .chat) {}
        ProfileActionButton(style: .follow(isFollowing: false)) {}
        ProfileActionButton(style: .follow(isFollowing: true)) {}
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Stats Row") {
    ProfileStatsRow(followerCount: 1247, followingCount: 892, addressCount: 3)
        .padding()
        .background(Theme.Colors.background)
}

#Preview("Epoch Tags") {
    EpochTagsSection(tags: EpochTag.mockTags)
        .background(Theme.Colors.background)
}

#Preview("Followed By") {
    FollowedBySection(mutualFollowers: MutualFollower.mockFollowers)
        .padding()
        .background(Theme.Colors.background)
}

#Preview("NFT Cards") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        EpochNFTCard(epoch: .mock())
        LapseNFTCard(lapse: LapseItem(title: "Opening keynote", epochId: 1))
    }
    .padding()
    .background(Theme.Colors.background)
}
