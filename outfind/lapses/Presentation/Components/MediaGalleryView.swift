import SwiftUI

// MARK: - Media Post

struct MediaPost: Identifiable, Equatable {
    let id = UUID()
    let imageURLs: [URL]
    let viewCount: Int
    let viewerAvatars: [URL]
    var reactions: [EmojiReaction]

    static let mockPosts: [MediaPost] = [
        MediaPost(
            imageURLs: [
                URL(string: "https://picsum.photos/seed/a1/400/500")!,
                URL(string: "https://picsum.photos/seed/a2/400/500")!
            ],
            viewCount: 59,
            viewerAvatars: [
                URL(string: "https://i.pravatar.cc/100?img=1")!,
                URL(string: "https://i.pravatar.cc/100?img=2")!,
                URL(string: "https://i.pravatar.cc/100?img=3")!
            ],
            reactions: [
                EmojiReaction(emoji: "🎉", count: 4, isSelected: false),
                EmojiReaction(emoji: "😍", count: 2, isSelected: true)
            ]
        ),
        MediaPost(
            imageURLs: [
                URL(string: "https://picsum.photos/seed/b1/400/500")!,
                URL(string: "https://picsum.photos/seed/b2/400/500")!
            ],
            viewCount: 53,
            viewerAvatars: [
                URL(string: "https://i.pravatar.cc/100?img=4")!,
                URL(string: "https://i.pravatar.cc/100?img=5")!
            ],
            reactions: [
                EmojiReaction(emoji: "🔥", count: 8, isSelected: false),
                EmojiReaction(emoji: "👏", count: 3, isSelected: false)
            ]
        ),
        MediaPost(
            imageURLs: [
                URL(string: "https://picsum.photos/seed/c1/400/500")!
            ],
            viewCount: 127,
            viewerAvatars: [
                URL(string: "https://i.pravatar.cc/100?img=6")!,
                URL(string: "https://i.pravatar.cc/100?img=7")!,
                URL(string: "https://i.pravatar.cc/100?img=8")!,
                URL(string: "https://i.pravatar.cc/100?img=9")!
            ],
            reactions: [
                EmojiReaction(emoji: "❤️", count: 15, isSelected: true),
                EmojiReaction(emoji: "🙌", count: 6, isSelected: false)
            ]
        )
    ]
}

// MARK: - Media Gallery View

struct MediaGalleryView: View {
    @Binding var posts: [MediaPost]

    var body: some View {
        LazyVStack(spacing: Theme.Spacing.lg) {
            ForEach(posts.indices, id: \.self) { index in
                MediaPostCard(post: $posts[index])
            }
        }
    }
}

// MARK: - Media Post Card

struct MediaPostCard: View {
    @Binding var post: MediaPost
    @State private var showEmojiPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Emoji reactions at top
            EmojiReactionBar(
                reactions: $post.reactions,
                onAddReaction: { showEmojiPicker = true }
            )

            // Image grid
            MediaImageGrid(imageURLs: post.imageURLs)

            // View count row
            ViewCountRow(
                viewCount: post.viewCount,
                avatarURLs: post.viewerAvatars
            )
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet { emoji in
                addReaction(emoji)
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    private func addReaction(_ emoji: String) {
        // Check if reaction already exists
        if let index = post.reactions.firstIndex(where: { $0.emoji == emoji }) {
            post.reactions[index].count += 1
            post.reactions[index].isSelected = true
        } else {
            post.reactions.append(EmojiReaction(emoji: emoji, count: 1, isSelected: true))
        }
    }
}

// MARK: - Media Image Grid

struct MediaImageGrid: View {
    let imageURLs: [URL]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(imageURLs.prefix(2), id: \.absoluteString) { url in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.backgroundTertiary)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minHeight: 200)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.backgroundTertiary)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - View Count Row

struct ViewCountRow: View {
    let viewCount: Int
    let avatarURLs: [URL]

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Stacked avatars
            AvatarStack(avatarURLs: avatarURLs.prefix(3).map { $0 })

            // View count
            Text("\(viewCount) views")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Avatar Stack

struct AvatarStack: View {
    let avatarURLs: [URL]
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: -10) {
            ForEach(avatarURLs.indices, id: \.self) { index in
                AsyncImage(url: avatarURLs[index]) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Circle()
                            .fill(Theme.Colors.backgroundTertiary)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: size * 0.5))
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Theme.Colors.background, lineWidth: 2)
                }
                .zIndex(Double(avatarURLs.count - index))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        MediaGalleryView(posts: .constant(MediaPost.mockPosts))
    }
    .background(Theme.Colors.background)
}
