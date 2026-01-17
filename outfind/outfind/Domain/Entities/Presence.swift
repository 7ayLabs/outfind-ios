import Foundation

/// Represents a user's presence state within an epoch
/// Presence is the gateway to all epoch features per INV22
struct Presence: Identifiable, Equatable, Hashable, Sendable {
    /// Composite ID: epochId:actorAddress
    var id: String { "\(epochId):\(actor.hex)" }

    /// The epoch this presence belongs to
    let epochId: UInt64

    /// The actor's Ethereum address
    let actor: Address

    // MARK: - On-Chain Data (from PresenceRegistry._presences[actor][epochId])

    /// Current presence state
    let state: PresenceState

    /// Timestamp when presence was declared (block.timestamp)
    let declaredAt: Date?

    /// Timestamp when presence was validated (quorum reached)
    let validatedAt: Date?

    /// Number of validator votes received
    let validationCount: UInt64

    // MARK: - Capability Checks

    /// Check if presence supports discovery in the given epoch (INV21, INV22)
    func canDiscover(in epoch: Epoch) -> Bool {
        epoch.capability.supportsDiscovery &&
        epoch.state == .active &&
        state.canInteract
    }

    /// Check if presence supports messaging in the given epoch (INV23)
    func canMessage(in epoch: Epoch) -> Bool {
        epoch.capability.supportsMessaging &&
        epoch.state == .active &&
        state.canInteract
    }

    /// Check if presence supports media capture in the given epoch (INV27)
    func canCaptureMedia(in epoch: Epoch) -> Bool {
        epoch.capability.supportsMedia &&
        epoch.state == .active &&
        state.canInteract
    }

    /// Check if presence supports viewing media in the given epoch (INV29)
    func canViewMedia(in epoch: Epoch) -> Bool {
        epoch.capability.supportsMedia &&
        epoch.state == .active &&
        state.canInteract
    }

    /// Check if this presence can interact with epoch features
    var canInteract: Bool {
        state.canInteract
    }

    /// Check if this presence is discoverable by others
    var isDiscoverable: Bool {
        state.isDiscoverable
    }

    // MARK: - Validation Progress

    /// Validation progress as a percentage (0.0 to 1.0)
    /// Returns 1.0 if already validated or finalized
    func validationProgress(quorumSize: UInt64) -> Double {
        guard quorumSize > 0 else { return 0.0 }
        guard state == .declared else { return state.rawValue >= PresenceState.validated.rawValue ? 1.0 : 0.0 }
        return min(Double(validationCount) / Double(quorumSize), 1.0)
    }

    /// Remaining votes needed for validation
    func votesNeeded(quorumSize: UInt64) -> UInt64 {
        guard state == .declared else { return 0 }
        return quorumSize > validationCount ? quorumSize - validationCount : 0
    }
}

// MARK: - Factory Methods

extension Presence {
    /// Create a presence with no state (not joined)
    static func none(epochId: UInt64, actor: Address) -> Presence {
        Presence(
            epochId: epochId,
            actor: actor,
            state: .none,
            declaredAt: nil,
            validatedAt: nil,
            validationCount: 0
        )
    }

    /// Create a mock presence for previews and testing
    static func mock(
        epochId: UInt64 = 1,
        actor: Address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!,
        state: PresenceState = .validated,
        validationCount: UInt64 = 3
    ) -> Presence {
        let now = Date()
        return Presence(
            epochId: epochId,
            actor: actor,
            state: state,
            declaredAt: state.rawValue >= PresenceState.declared.rawValue ? now.addingTimeInterval(-300) : nil,
            validatedAt: state.rawValue >= PresenceState.validated.rawValue ? now.addingTimeInterval(-60) : nil,
            validationCount: validationCount
        )
    }
}

// MARK: - Presence Update

/// Represents an update to presence state
enum PresenceUpdate: Equatable, Sendable {
    /// Presence state changed
    case stateChanged(PresenceState)

    /// Validation progress updated
    case validationProgress(count: UInt64, quorum: UInt64)

    /// Presence was slashed
    case slashed(reason: String)

    /// Error occurred
    case error(String)
}
