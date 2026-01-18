import Foundation

/// Represents a conversation in an epoch
/// Conversations are epoch-scoped and ephemeral (INV14, INV25)
struct Conversation: Identifiable, Equatable, Hashable, Sendable {
    /// Unique conversation identifier
    let id: String

    /// Epoch this conversation belongs to
    let epochId: UInt64

    /// Title of the epoch (for display)
    let epochTitle: String

    /// Emoji representing the epoch
    let epochEmoji: String

    /// Last message preview text
    let lastMessagePreview: String

    /// Timestamp of last message
    let lastMessageTime: Date

    /// Number of unread messages
    let unreadCount: Int

    /// Current conversation state
    let state: ConversationState

    /// Number of participants in this conversation
    let participantCount: Int

    // MARK: - Computed Properties

    /// Whether there are unread messages
    var hasUnread: Bool {
        unreadCount > 0
    }

    /// Formatted time for display
    var formattedTime: String {
        let interval = Date().timeIntervalSince(lastMessageTime)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Conversation State (Snapchat-inspired)

enum ConversationState: String, Sendable, Equatable, Hashable {
    /// New message waiting to be viewed
    case newMessage

    /// Tap to view (unopened snap style)
    case tapToView

    /// Tap to chat (awaiting reply)
    case tapToChat

    /// Message was opened/read
    case opened

    /// Message was received
    case received

    /// Message was sent
    case sent

    /// Epoch has ended, conversation archived
    case archived

    /// Display text for the state
    var displayText: String {
        switch self {
        case .newMessage: return "New message"
        case .tapToView: return "Tap to view"
        case .tapToChat: return "Tap to chat"
        case .opened: return "Opened"
        case .received: return "Received"
        case .sent: return "Sent"
        case .archived: return "Ended"
        }
    }

    /// Indicator color for the state
    var indicatorColor: String {
        switch self {
        case .newMessage, .tapToView: return "007AFF"  // Blue
        case .tapToChat: return "8E8E93"               // Gray
        case .opened, .received, .sent: return "34C759" // Green
        case .archived: return "8E8E93"                // Gray
        }
    }
}

// MARK: - Sample Conversations

extension Conversation {
    static let sampleConversations: [Conversation] = [
        Conversation(
            id: "conv-1",
            epochId: 1,
            epochTitle: "Tech Meetup SF",
            epochEmoji: "💻",
            lastMessagePreview: "Sarah: Anyone near the main stage?",
            lastMessageTime: Date().addingTimeInterval(-120),
            unreadCount: 3,
            state: .newMessage,
            participantCount: 42
        ),
        Conversation(
            id: "conv-2",
            epochId: 2,
            epochTitle: "Sunset Watch",
            epochEmoji: "🌅",
            lastMessagePreview: "You: See you there!",
            lastMessageTime: Date().addingTimeInterval(-3600),
            unreadCount: 0,
            state: .sent,
            participantCount: 18
        ),
        Conversation(
            id: "conv-3",
            epochId: 3,
            epochTitle: "Hackathon 2026",
            epochEmoji: "⚡️",
            lastMessagePreview: "Mike: Great presentation!",
            lastMessageTime: Date().addingTimeInterval(-7200),
            unreadCount: 0,
            state: .opened,
            participantCount: 156
        ),
        Conversation(
            id: "conv-4",
            epochId: 4,
            epochTitle: "Coffee & Code",
            epochEmoji: "☕️",
            lastMessagePreview: "Tap to view new message",
            lastMessageTime: Date().addingTimeInterval(-180),
            unreadCount: 1,
            state: .tapToView,
            participantCount: 12
        ),
        Conversation(
            id: "conv-5",
            epochId: 5,
            epochTitle: "Art Gallery Opening",
            epochEmoji: "🎨",
            lastMessagePreview: "Event has ended",
            lastMessageTime: Date().addingTimeInterval(-86400),
            unreadCount: 0,
            state: .archived,
            participantCount: 89
        )
    ]
}
