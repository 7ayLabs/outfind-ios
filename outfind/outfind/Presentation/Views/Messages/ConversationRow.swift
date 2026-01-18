import SwiftUI

// MARK: - Conversation Row (Snapchat-inspired)

/// Individual row component for the messages list
/// Displays epoch avatar, title, last message preview, and status indicator
struct ConversationRow: View {
    let conversation: Conversation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                // Epoch avatar/emoji
                epochAvatar

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(conversation.epochTitle)
                            .font(.system(size: 16, weight: conversation.hasUnread ? .semibold : .regular))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Time
                        Text(conversation.formattedTime)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }

                    HStack(spacing: Theme.Spacing.xxs) {
                        // State indicator
                        stateIndicator

                        Text(conversation.lastMessagePreview)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        // Unread badge or status icon
                        trailingIndicator
                    }
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(ConversationRowButtonStyle())
    }

    // MARK: - Epoch Avatar

    private var epochAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarGradient)
                .frame(width: 50, height: 50)

            Text(conversation.epochEmoji)
                .font(.system(size: 24))
        }
        .overlay(alignment: .bottomTrailing) {
            if conversation.state == .newMessage || conversation.state == .tapToView {
                Circle()
                    .fill(Theme.Colors.info)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(Theme.Colors.background, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: conversation.state.indicatorColor).opacity(0.2),
                Color(hex: conversation.state.indicatorColor).opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - State Indicator

    @ViewBuilder
    private var stateIndicator: some View {
        switch conversation.state {
        case .newMessage, .tapToView:
            Circle()
                .fill(Color(hex: "007AFF"))
                .frame(width: 8, height: 8)

        case .tapToChat:
            Circle()
                .stroke(Color(hex: "8E8E93"), lineWidth: 1.5)
                .frame(width: 8, height: 8)

        case .opened, .received, .sent:
            EmptyView()

        case .archived:
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    // MARK: - Trailing Indicator

    @ViewBuilder
    private var trailingIndicator: some View {
        if conversation.hasUnread {
            // Unread count badge
            Text("\(conversation.unreadCount)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background {
                    Capsule()
                        .fill(Theme.Colors.info)
                }
        } else {
            // Status icon based on state
            statusIcon
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch conversation.state {
        case .sent:
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Colors.textTertiary)

        case .opened:
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Colors.success)

        case .received:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Theme.Colors.success)

        case .archived:
            Image(systemName: "archivebox")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textTertiary)

        default:
            EmptyView()
        }
    }
}

// MARK: - Button Style

private struct ConversationRowButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .background {
                if configuration.isPressed {
                    Theme.Colors.backgroundTertiary
                }
            }
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ForEach(Conversation.sampleConversations) { conversation in
            ConversationRow(conversation: conversation, onTap: {})
            Divider()
                .padding(.leading, 78)
        }
    }
    .background(Theme.Colors.background)
}
