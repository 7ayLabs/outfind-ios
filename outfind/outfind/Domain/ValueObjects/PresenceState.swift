import Foundation

/// Presence lifecycle states per 7ay-presence protocol
/// Maps directly to PresenceRegistry.PresenceState enum in the smart contract
enum PresenceState: UInt8, Codable, CaseIterable, Comparable, Sendable {
    /// No presence exists for this (actor, epoch) pair
    case none = 0

    /// Actor declared presence, awaiting validator quorum
    case declared = 1

    /// Validator quorum reached, presence validated
    case validated = 2

    /// Permanently recorded after epoch close (terminal)
    case finalized = 3

    /// Invalidated by successful dispute (terminal)
    case slashed = 4

    // MARK: - State Queries

    /// Whether this presence can interact with epoch features (INV22)
    /// Declared, Validated, and Finalized states can interact
    var canInteract: Bool {
        switch self {
        case .declared, .validated, .finalized:
            return true
        case .none, .slashed:
            return false
        }
    }

    /// Whether this is a terminal state (no further transitions)
    var isTerminal: Bool {
        self == .finalized || self == .slashed
    }

    /// Whether validation is required before full participation
    var requiresValidation: Bool {
        self == .declared
    }

    /// Whether this presence can be discovered by others (INV22)
    var isDiscoverable: Bool {
        canInteract
    }

    // MARK: - State Transitions

    /// Valid next states from current state per protocol
    var validNextStates: Set<PresenceState> {
        switch self {
        case .none:
            return [.declared]
        case .declared:
            return [.validated, .slashed]
        case .validated:
            return [.finalized, .slashed]
        case .finalized, .slashed:
            return [] // Terminal states
        }
    }

    /// Whether a transition to the given state is valid
    func canTransition(to newState: PresenceState) -> Bool {
        validNextStates.contains(newState)
    }

    // MARK: - Comparable

    static func < (lhs: PresenceState, rhs: PresenceState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: - Display

    /// Human-readable name for the state
    var displayName: String {
        switch self {
        case .none: return "Not Joined"
        case .declared: return "Declared"
        case .validated: return "Validated"
        case .finalized: return "Finalized"
        case .slashed: return "Slashed"
        }
    }

    /// Short description of the state
    var stateDescription: String {
        switch self {
        case .none:
            return "You haven't joined this epoch"
        case .declared:
            return "Awaiting validator confirmation"
        case .validated:
            return "Your presence is confirmed"
        case .finalized:
            return "Presence permanently recorded"
        case .slashed:
            return "Presence invalidated"
        }
    }

    /// System image name for the state
    var systemImage: String {
        switch self {
        case .none: return "person.badge.plus"
        case .declared: return "clock.badge.checkmark"
        case .validated: return "checkmark.circle.fill"
        case .finalized: return "checkmark.seal.fill"
        case .slashed: return "xmark.circle.fill"
        }
    }

    /// Color name for the state
    var colorName: String {
        switch self {
        case .none: return "secondary"
        case .declared: return "orange"
        case .validated: return "green"
        case .finalized: return "blue"
        case .slashed: return "red"
        }
    }
}
