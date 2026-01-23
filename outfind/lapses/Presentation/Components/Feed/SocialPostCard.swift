import SwiftUI

// MARK: - Social Post Card

/// Card component for displaying epoch-scoped social posts.
/// Design inspired by Nextdoor-style post layout with avatar, content, and reactions.
struct SocialPostCard: View {
    let post: EpochPost
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onMoreTap: () -> Void
    let onAuthorTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            postHeader
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)

            // Content
            postContent
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)

            // Location (if available)
            if post.hasLocation {
                locationPill
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)
            }

            // Reactions Footer
            reactionsFooter
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
        }
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.backgroundSecondary)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .strokeBorder(Theme.Colors.textTertiary.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - Post Header

    private var postHeader: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Author Avatar
            Button(action: onAuthorTap) {
                authorAvatar
            }
            .buttonStyle(.plain)

            // Author Info
            VStack(alignment: .leading, spacing: 2) {
                Button(action: onAuthorTap) {
                    Text(post.author.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .buttonStyle(.plain)

                HStack(spacing: Theme.Spacing.xxs) {
                    if let locationName = post.author.locationName {
                        Text(locationName)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Text("·")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(post.timeAgo)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            // More Button
            Button(action: onMoreTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
    }

    private var authorAvatar: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.primaryFallback.opacity(0.15))
                .frame(width: 44, height: 44)

            if let avatarURL = post.author.avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    authorInitial
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                authorInitial
            }
        }
    }

    private var authorInitial: some View {
        Text(String(post.author.name.prefix(1)).uppercased())
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Theme.Colors.primaryFallback)
    }

    // MARK: - Post Content

    private var postContent: some View {
        Text(post.content)
            .font(.system(size: 15))
            .foregroundStyle(Theme.Colors.textPrimary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Location Pill

    private var locationPill: some View {
        Button {
            // Open location/map
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(Theme.Colors.primaryFallback)
                    .frame(width: 8, height: 8)

                if let locationName = post.location?.name {
                    Text(locationName)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reactions Footer

    private var reactionsFooter: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Like Button
            reactionButton(
                icon: post.hasLiked ? "heart.fill" : "heart",
                count: post.reactionCount,
                color: post.hasLiked ? Theme.Colors.error : Theme.Colors.textSecondary,
                action: onLike
            )

            // Comment Button
            reactionButton(
                icon: "bubble.left",
                count: post.commentCount,
                color: Theme.Colors.textSecondary,
                action: onComment
            )

            // Share Button
            reactionButton(
                icon: "arrowshape.turn.up.right",
                count: post.shareCount,
                color: Theme.Colors.textSecondary,
                action: onShare
            )

            Spacer()
        }
    }

    private func reactionButton(
        icon: String,
        count: Int,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(EpochPost.mockPosts()) { post in
                SocialPostCard(
                    post: post,
                    onLike: { print("Liked \(post.id)") },
                    onComment: { print("Comment on \(post.id)") },
                    onShare: { print("Share \(post.id)") },
                    onMoreTap: { print("More for \(post.id)") },
                    onAuthorTap: { print("Author tapped") }
                )
            }
        }
        .padding(Theme.Spacing.md)
    }
    .background(Theme.Colors.background)
}
