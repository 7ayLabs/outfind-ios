import SwiftUI

// MARK: - Conversation Row (Web3 Green Theme)

/// Individual row component for the messages list
/// Displays epoch avatar, title, last message preview, LIVE indicator, and status
struct ConversationRow: View {
    let conversation: Conversation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                // Epoch avatar/emoji
                epochAvatar

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    // Title row with LIVE badge
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(conversation.epochTitle)
                            .font(.system(size: 16, weight: conversation.hasUnread ? .semibold : .regular))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        // LIVE indicator
                        if conversation.isLive {
                            liveBadge
                        }

                        Spacer()

                        // Time remaining or last message time
                        if let timeRemaining = conversation.formattedTimeRemaining, conversation.isLive {
                            Text(timeRemaining)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.Colors.liveGreen)
                        } else {
                            Text(conversation.formattedTime)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }

                    // Participants and last message
                    HStack(spacing: Theme.Spacing.xs) {
                        // Participant count
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(conversation.participantCount)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Theme.Colors.textTertiary)

                        Text("·")
                            .foregroundStyle(Theme.Colors.textTertiary)

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

    // MARK: - LIVE Badge

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Theme.Colors.liveGreen)
                .frame(width: 6, height: 6)

            Text("LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.Colors.liveGreen)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(Theme.Colors.liveGreen.opacity(0.15))
        }
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
                    .fill(Theme.Colors.neonGreen)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(Theme.Colors.background, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            } else if conversation.isLive {
                // Green dot for live epochs
                Circle()
                    .fill(Theme.Colors.liveGreen)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle()
                            .stroke(Theme.Colors.background, lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var avatarGradient: LinearGradient {
        // Use green gradient for live/active epochs
        if conversation.isLive {
            return LinearGradient(
                colors: [
                    Theme.Colors.liveGreen.opacity(0.2),
                    Theme.Colors.deepTeal.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
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
            // Green dot for new messages
            Circle()
                .fill(Theme.Colors.neonGreen)
                .frame(width: 8, height: 8)

        case .tapToChat:
            Circle()
                .stroke(Theme.Colors.tabInactive, lineWidth: 1.5)
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
            // Unread count badge - green gradient
            Text("\(conversation.unreadCount)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule()
                        .fill(Theme.Colors.greenGradient)
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
