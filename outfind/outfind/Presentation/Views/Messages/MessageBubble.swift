import SwiftUI

// MARK: - Message Bubble

/// Individual message bubble component
/// Displays message content with sender alignment and status
struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Message content
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundStyle(message.isFromCurrentUser ? .white : Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background {
                        bubbleBackground
                    }

                // Time and status
                HStack(spacing: Theme.Spacing.xxs) {
                    Text(message.shortTime)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textTertiary)

                    if message.isFromCurrentUser {
                        messageStatusIcon
                    }
                }
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xxs)
    }

    // MARK: - Bubble Background

    private var bubbleBackground: some View {
        Group {
            if message.isFromCurrentUser {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.Colors.primaryFallback)
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.Colors.backgroundTertiary)
            }
        }
    }

    // MARK: - Status Icon

    @ViewBuilder
    private var messageStatusIcon: some View {
        switch message.state {
        case .sending:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 12, height: 12)

        case .sent:
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Theme.Colors.textTertiary)

        case .delivered:
            HStack(spacing: -3) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Theme.Colors.textTertiary)

        case .read:
            HStack(spacing: -3) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(Theme.Colors.info)

        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.error)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.sm) {
        ForEach(Message.sampleMessages) { message in
            MessageBubble(message: message)
        }
    }
    .padding(.vertical)
    .background(Theme.Colors.background)
}
