import Foundation

/// Epoch-specific errors
enum EpochError: Error, Equatable, Sendable {
    /// Epoch not found
    case notFound(epochId: UInt64)

    /// Epoch is not joinable (wrong state)
    case notJoinable(state: EpochState)

    /// User has already joined this epoch
    case alreadyJoined

    /// Epoch has closed
    case epochClosed

    /// Epoch capability doesn't support the requested feature
    case featureNotSupported(feature: String, capability: EpochCapability)

    /// Network error while fetching epoch
    case networkError(String)

    /// Contract interaction error
    case contractError(String)

    /// Epoch data is stale and needs refresh
    case staleData

    /// Invalid epoch ID
    case invalidEpochId

    var localizedDescription: String {
        switch self {
        case .notFound(let epochId):
            return "Epoch \(epochId) not found"
        case .notJoinable(let state):
            return "Cannot join epoch in \(state.displayName) state"
        case .alreadyJoined:
            return "You have already joined this epoch"
        case .epochClosed:
            return "This epoch has closed"
        case .featureNotSupported(let feature, let capability):
            return "\(feature) is not supported with \(capability.displayName)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .contractError(let message):
            return "Contract error: \(message)"
        case .staleData:
            return "Epoch data is stale, please refresh"
        case .invalidEpochId:
            return "Invalid epoch ID"
        }
    }

    /// Whether this error is recoverable
    var isRecoverable: Bool {
        switch self {
        case .networkError, .staleData:
            return true
        case .notFound, .notJoinable, .alreadyJoined, .epochClosed,
             .featureNotSupported, .contractError, .invalidEpochId:
            return false
        }
    }
}
