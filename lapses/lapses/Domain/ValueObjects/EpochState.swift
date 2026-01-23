import Foundation

/// Epoch lifecycle states per 7ay-presence protocol
/// Maps directly to EpochRegistry.EpochState enum in the smart contract
enum EpochState: UInt8, Codable, CaseIterable, Sendable {
    /// Epoch does not exist
    case none = 0

    /// Created but block.timestamp < startTime
    case scheduled = 1

    /// startTime <= block.timestamp < endTime
    case active = 2

    /// block.timestamp >= endTime && !finalized
    case closed = 3

    /// Permanently sealed (terminal state)
    case finalized = 4

    // MARK: - State Queries

    /// Whether the epoch can be joined (presence can be declared)
    var isJoinable: Bool {
        self == .scheduled || self == .active
    }

    /// Whether presence declaration is allowed
    /// Note: Protocol requires Active state for declaration
    var supportsPresenceDeclaration: Bool {
        self == .active
    }

    /// Whether ephemeral data operations are allowed (INV14)
    var supportsEphemeralData: Bool {
        self == .active
    }

    /// Whether this is a terminal state (no further transitions)
    var isTerminal: Bool {
        self == .finalized
    }

    /// Whether discovery is supported (INV21)
    var supportsDiscovery: Bool {
        self == .active
    }

    /// Whether messaging is supported (INV23)
    var supportsMessaging: Bool {
        self == .active
    }

    /// Whether media operations are supported (INV27, INV29)
    var supportsMedia: Bool {
        self == .active
    }

    // MARK: - Display

    /// Human-readable name for the state
    var displayName: String {
        switch self {
        case .none: return "None"
        case .scheduled: return "Scheduled"
        case .active: return "Active"
        case .closed: return "Closed"
        case .finalized: return "Finalized"
        }
    }

    /// System image name for the state
    var systemImage: String {
        switch self {
        case .none: return "circle.dashed"
        case .scheduled: return "calendar.badge.clock"
        case .active: return "circle.fill"
        case .closed: return "lock.fill"
        case .finalized: return "checkmark.seal.fill"
        }
    }
}

// MARK: - State Computation

extension EpochState {
    /// Compute epoch state from timestamps
    /// - Parameters:
    ///   - exists: Whether the epoch exists
    ///   - finalized: Whether the epoch has been finalized
    ///   - startTime: Epoch start timestamp
    ///   - endTime: Epoch end timestamp
    ///   - currentTime: Current timestamp (defaults to now)
    /// - Returns: Computed epoch state
    static func compute(
        exists: Bool,
        finalized: Bool,
        startTime: Date,
        endTime: Date,
        currentTime: Date = Date()
    ) -> EpochState {
        guard exists else { return .none }
        guard !finalized else { return .finalized }

        if currentTime < startTime {
            return .scheduled
        } else if currentTime < endTime {
            return .active
        } else {
            return .closed
        }
    }
}
