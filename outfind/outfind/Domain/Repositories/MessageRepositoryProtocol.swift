import Foundation

/// Repository protocol for message operations
/// Messages are ephemeral and epoch-scoped (INV14, INV25)
protocol MessageRepositoryProtocol: Sendable {
    /// Fetch all conversations for the current user
    func fetchConversations() async throws -> [Conversation]

    /// Fetch messages for a specific conversation
    func fetchMessages(conversationId: String) async throws -> [Message]

    /// Send a new message
    func sendMessage(epochId: UInt64, content: String) async throws -> Message

    /// Mark messages as read
    func markAsRead(conversationId: String) async throws

    /// Clear all messages for an epoch (INV14 - ephemeral data purge)
    func clearMessagesForEpoch(epochId: UInt64) async throws

    /// Observe new messages in real-time
    func observeMessages(conversationId: String) -> AsyncStream<Message>
}
