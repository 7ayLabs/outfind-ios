import SwiftUI

// MARK: - Emoji Reaction

struct EmojiReaction: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    var count: Int
    var isSelected: Bool

    static let mockReactions: [EmojiReaction] = [
        EmojiReaction(emoji: "🎉", count: 4, isSelected: false),
        EmojiReaction(emoji: "😍", count: 2, isSelected: true),
        EmojiReaction(emoji: "🔥", count: 7, isSelected: false),
        EmojiReaction(emoji: "👏", count: 3, isSelected: false)
    ]

    static let availableEmojis = ["🎉", "😍", "🔥", "👏", "😂", "❤️", "🙌", "💯"]
}

// MARK: - Emoji Reaction Bar

struct EmojiReactionBar: View {
    @Binding var reactions: [EmojiReaction]
    var onAddReaction: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(reactions.indices, id: \.self) { index in
                    EmojiReactionButton(
                        reaction: reactions[index],
                        onTap: {
                            toggleReaction(at: index)
                        }
                    )
                }

                // Add reaction button
                if let onAddReaction = onAddReaction {
                    Button(action: onAddReaction) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 36, height: 36)
                            .background {
                                Circle()
                                    .fill(Theme.Colors.backgroundTertiary)
                            }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func toggleReaction(at index: Int) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if reactions[index].isSelected {
                reactions[index].count -= 1
                reactions[index].isSelected = false
            } else {
                reactions[index].count += 1
                reactions[index].isSelected = true
            }
        }
    }
}

// MARK: - Emoji Reaction Button

struct EmojiReactionButton: View {
    let reaction: EmojiReaction
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(reaction.emoji)
                    .font(.system(size: 20))

                if reaction.count > 0 {
                    Text("\(reaction.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(reaction.isSelected ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                }

                if reaction.isSelected {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(reaction.isSelected
                        ? Theme.Colors.primaryFallback.opacity(0.15)
                        : Theme.Colors.backgroundSecondary)
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                reaction.isSelected
                                    ? Theme.Colors.primaryFallback.opacity(0.3)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Emoji Picker Sheet

struct EmojiPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Handle
            Capsule()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, Theme.Spacing.sm)

            Text("Add Reaction")
                .font(Typography.titleMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(EmojiReaction.availableEmojis, id: \.self) { emoji in
                    Button {
                        onSelect(emoji)
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 32))
                            .frame(width: 56, height: 56)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.Colors.backgroundTertiary)
                            }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()
        }
        .background(Theme.Colors.background)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        EmojiReactionBar(
            reactions: .constant(EmojiReaction.mockReactions),
            onAddReaction: {}
        )

        EmojiReactionBar(
            reactions: .constant([
                EmojiReaction(emoji: "🎉", count: 12, isSelected: true),
                EmojiReaction(emoji: "🐱", count: 5, isSelected: false)
            ])
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
