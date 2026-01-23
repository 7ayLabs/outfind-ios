import Foundation

/// Mock implementation of MessageRepositoryProtocol for development and testing
@MainActor
final class MockMessageRepository: MessageRepositoryProtocol, @unchecked Sendable {
    private var conversations: [Conversation] = Conversation.sampleConversations
    private var messages: [String: [Message]] = [
        "conv-1": Message.sampleMessages,
        "conv-2": Message.sampleMessages,
        "conv-3": Message.sampleMessages,
        "conv-4": Message.sampleMessages,
        "conv-5": Message.sampleMessages,
        "conv-6": Message.sampleMessages
    ]

    nonisolated func fetchConversations() async throws -> [Conversation] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        return await MainActor.run { conversations }
    }

    nonisolated func fetchMessages(conversationId: String) async throws -> [Message] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 300_000_000)
        return await MainActor.run { messages[conversationId] ?? [] }
    }

    nonisolated func sendMessage(epochId: UInt64, content: String) async throws -> Message {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 200_000_000)

        let message = Message(
            id: UUID().uuidString,
            epochId: epochId,
            senderId: "current-user",
            content: content,
            timestamp: Date(),
            state: .sent,
            isFromCurrentUser: true
        )

        // Add to local storage
        let convId = "conv-\(epochId)"
        await MainActor.run {
            if messages[convId] != nil {
                messages[convId]?.append(message)
            } else {
                messages[convId] = [message]
            }
        }

        return message
    }

    nonisolated func markAsRead(conversationId: String) async throws {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000)

        await MainActor.run {
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                let conv = conversations[index]
                conversations[index] = Conversation(
                    id: conv.id,
                    epochId: conv.epochId,
                    epochTitle: conv.epochTitle,
                    epochEmoji: conv.epochEmoji,
                    lastMessagePreview: conv.lastMessagePreview,
                    lastMessageTime: conv.lastMessageTime,
                    unreadCount: 0,
                    state: .opened,
                    participantCount: conv.participantCount,
                    isCreatedByCurrentUser: conv.isCreatedByCurrentUser,
                    epochState: conv.epochState,
                    epochTimeRemaining: conv.epochTimeRemaining
                )
            }
        }
    }

    nonisolated func clearMessagesForEpoch(epochId: UInt64) async throws {
        let convId = "conv-\(epochId)"
        await MainActor.run {
            messages[convId] = []
            conversations.removeAll { $0.epochId == epochId }
        }
    }

    nonisolated func observeMessages(conversationId: String) -> AsyncStream<Message> {
        AsyncStream { continuation in
            // In a real implementation, this would connect to WebSocket
            // For mock, we just yield existing messages
            Task {
                if let msgs = await MainActor.run(body: { messages[conversationId] }) {
                    for message in msgs {
                        continuation.yield(message)
                    }
                }
                continuation.finish()
            }
        }
    }
}
