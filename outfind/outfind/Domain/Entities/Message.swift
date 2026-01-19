import Foundation

/// Represents a message in an epoch conversation
/// Messages are ephemeral and tied to epoch lifecycle (INV14, INV25)
struct Message: Identifiable, Equatable, Hashable, Sendable {
    /// Unique message identifier
    let id: String

    /// Epoch this message belongs to
    let epochId: UInt64

    /// Sender's user ID
    let senderId: String

    /// Content of the message
    let content: String

    /// When the message was sent
    let timestamp: Date

    /// Message delivery/read state
    let state: MessageState

    /// Whether this message was sent by the current user
    let isFromCurrentUser: Bool

    // MARK: - Computed Properties

    /// Formatted timestamp for display
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Short time display (e.g., "2m", "1h")
    var shortTime: String {
        let interval = Date().timeIntervalSince(timestamp)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)

        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}

// MARK: - Message State

enum MessageState: String, Sendable, Equatable, Hashable {
    /// Message is being sent
    case sending

    /// Message was sent successfully
    case sent

    /// Message was delivered to recipient
    case delivered

    /// Message was read by recipient
    case read

    /// Message failed to send
    case failed
}

// MARK: - Sample Messages

extension Message {
    static let sampleMessages: [Message] = [
        Message(
            id: "msg-1",
            epochId: 1,
            senderId: "user-2",
            content: "Hey! Are you coming to the event?",
            timestamp: Date().addingTimeInterval(-120),
            state: .read,
            isFromCurrentUser: false
        ),
        Message(
            id: "msg-2",
            epochId: 1,
            senderId: "current-user",
            content: "Yes! On my way now 🚀",
            timestamp: Date().addingTimeInterval(-60),
            state: .delivered,
            isFromCurrentUser: true
        ),
        Message(
            id: "msg-3",
            epochId: 1,
            senderId: "user-2",
            content: "Perfect, see you there!",
            timestamp: Date().addingTimeInterval(-30),
            state: .read,
            isFromCurrentUser: false
        )
    ]
}
