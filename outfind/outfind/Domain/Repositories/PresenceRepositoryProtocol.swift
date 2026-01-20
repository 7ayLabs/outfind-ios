import Foundation

/// Repository protocol for presence operations
protocol PresenceRepositoryProtocol: Sendable {
    /// Get current user's presence in an epoch
    /// - Parameters:
    ///   - actor: Actor's address
    ///   - epochId: Epoch ID
    /// - Returns: Presence if exists, nil otherwise
    func fetchPresence(actor: Address, epochId: UInt64) async throws -> Presence?

    /// Declare presence in an epoch (on-chain transaction)
    /// INV4: Only actor can declare own presence
    /// - Parameters:
    ///   - epochId: Epoch ID
    ///   - stake: Optional stake amount
    /// - Returns: Declared presence
    func declarePresence(epochId: UInt64, stake: UInt64?) async throws -> Presence

    /// Subscribe to presence events
    /// - Parameters:
    ///   - actor: Actor's address
    ///   - epochId: Epoch ID
    /// - Returns: Async stream of presence events
    func subscribeToPresenceEvents(actor: Address, epochId: UInt64) -> AsyncStream<PresenceEvent>

    /// Unsubscribe from presence events
    /// - Parameters:
    ///   - actor: Actor's address
    ///   - epochId: Epoch ID
    func unsubscribeFromPresenceEvents(actor: Address, epochId: UInt64) async

    /// Get all participants in an epoch
    /// - Parameter epochId: Epoch ID
    /// - Returns: Array of presences
    func fetchParticipants(epochId: UInt64) async throws -> [Presence]

    /// Get the current quorum size
    /// - Returns: Number of votes required for validation
    func fetchQuorumSize() async throws -> UInt64

    /// Get echoes (ghost presences) for an epoch
    /// Echoes are presences of users who left within the last 24 hours
    /// - Parameter epochId: Epoch ID
    /// - Returns: Array of echo presences sorted by recency
    func fetchEchoes(for epochId: UInt64) async throws -> [Presence]
}

// MARK: - Events

/// Presence-related events
enum PresenceEvent: Equatable, Sendable {
    /// Presence declared (PresenceDeclared event)
    case declared(Presence)

    /// Validation vote received
    case validationVote(count: UInt64, quorum: UInt64)

    /// Presence validated (PresenceValidated event)
    case validated(Presence)

    /// Presence finalized (PresenceFinalized event)
    case finalized(Presence)

    /// Presence slashed (PresenceSlashedEvent)
    case slashed(reason: String)

    /// Error occurred
    case error(String)
}
