import Foundation

/// Presence-specific errors
enum PresenceError: Error, Equatable, Sendable {
    /// User is not in this epoch
    case notInEpoch

    /// Presence has already been declared
    case alreadyDeclared

    /// Presence validation failed
    case validationFailed(String)

    /// Insufficient stake for presence declaration
    case insufficientStake

    /// Epoch is not in Active state
    case epochNotActive

    /// Transaction to declare/validate presence failed
    case transactionFailed(String)

    /// Presence has been slashed
    case presenceSlashed(reason: String)

    /// Presence state doesn't allow this operation
    case invalidState(current: PresenceState, requiredMinimum: PresenceState)

    /// Quorum not yet reached
    case quorumNotReached(current: UInt64, required: UInt64)

    /// Network error
    case networkError(String)

    var localizedDescription: String {
        switch self {
        case .notInEpoch:
            return "You haven't joined this epoch"
        case .alreadyDeclared:
            return "Presence already declared"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .insufficientStake:
            return "Insufficient stake for presence declaration"
        case .epochNotActive:
            return "Epoch is not active"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .presenceSlashed(let reason):
            return "Presence slashed: \(reason)"
        case .invalidState(let current, let required):
            return "Invalid presence state: \(current.displayName) (requires at least \(required.displayName))"
        case .quorumNotReached(let current, let required):
            return "Quorum not reached: \(current)/\(required) votes"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }

    /// Whether this error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .networkError, .transactionFailed, .quorumNotReached:
            return true
        case .notInEpoch, .alreadyDeclared, .validationFailed, .insufficientStake,
             .epochNotActive, .presenceSlashed, .invalidState:
            return false
        }
    }
}
