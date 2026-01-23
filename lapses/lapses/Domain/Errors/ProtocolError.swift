import Foundation

/// Protocol-level errors mapped from 7ay-presence smart contracts (v0.4)
/// Error priority order per spec: InvalidActor > UnauthorizedActor > InvalidEpoch > PresenceSlashed > EpochNotActive > CallerNotValidator
enum ProtocolError: Error, Equatable, Sendable {
    // MARK: - Actor Errors

    /// Actor address is zero
    case invalidActor

    /// Caller is not the actor (INV4: only actor can declare own presence)
    case unauthorizedActor

    // MARK: - Epoch Errors

    /// Epoch ID is zero or epoch doesn't exist
    case invalidEpoch

    /// Epoch is not in Active state
    case epochNotActive(currentState: EpochState)

    /// Epoch has already been finalized
    case epochFinalized

    /// Epoch doesn't support required capability
    case insufficientCapability(required: EpochCapability, actual: EpochCapability)

    // MARK: - Presence Errors

    /// Presence has been slashed
    case presenceSlashed

    /// Presence not in expected state
    case invalidPresenceState(expected: PresenceState, actual: PresenceState)

    /// Presence already exists
    case presenceAlreadyExists

    /// Presence doesn't exist
    case presenceNotFound

    /// Cannot finalize presence in current epoch state
    case presenceNotFinalizable

    // MARK: - Validator Errors

    /// Caller is not an active validator
    case callerNotValidator

    /// Validator already voted on this presence
    case validatorAlreadyVoted

    /// Validator already voted on this dispute
    case validatorAlreadyVotedOnDispute

    // MARK: - Dispute Errors

    /// Dispute already exists for this presence
    case disputeAlreadyExists

    /// Dispute not found
    case disputeNotFound

    /// Dispute window has closed
    case disputeWindowClosed

    /// Dispute is not in Pending state
    case disputeNotPending

    // MARK: - Network Errors

    /// Transaction failed
    case transactionFailed(String)

    /// RPC error
    case rpcError(String)

    /// Network unreachable
    case networkUnreachable

    // MARK: - Unknown

    /// Unknown error
    case unknown(String)

    // MARK: - Localized Description

    var localizedDescription: String {
        switch self {
        case .invalidActor:
            return "Invalid actor address"
        case .unauthorizedActor:
            return "You can only declare your own presence"
        case .invalidEpoch:
            return "Invalid or non-existent epoch"
        case .epochNotActive(let state):
            return "Epoch is not active (current state: \(state.displayName))"
        case .epochFinalized:
            return "Epoch has been finalized"
        case .insufficientCapability(let required, let actual):
            return "Epoch doesn't support \(required.displayName) (has \(actual.displayName))"
        case .presenceSlashed:
            return "Your presence has been slashed"
        case .invalidPresenceState(let expected, let actual):
            return "Invalid presence state: expected \(expected.displayName), got \(actual.displayName)"
        case .presenceAlreadyExists:
            return "You have already joined this epoch"
        case .presenceNotFound:
            return "Presence not found"
        case .presenceNotFinalizable:
            return "Presence cannot be finalized in current epoch state"
        case .callerNotValidator:
            return "Only validators can perform this action"
        case .validatorAlreadyVoted:
            return "You have already voted on this presence"
        case .validatorAlreadyVotedOnDispute:
            return "You have already voted on this dispute"
        case .disputeAlreadyExists:
            return "A dispute already exists for this presence"
        case .disputeNotFound:
            return "Dispute not found"
        case .disputeWindowClosed:
            return "Dispute window has closed"
        case .disputeNotPending:
            return "Dispute is not pending"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .rpcError(let message):
            return "RPC error: \(message)"
        case .networkUnreachable:
            return "Network unreachable"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
