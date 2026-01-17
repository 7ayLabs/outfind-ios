import Foundation

/// Epoch capability levels per 7ay-presence protocol v0.5+
/// Maps directly to EpochRegistry.EpochCapability enum in the smart contract
enum EpochCapability: UInt8, Codable, CaseIterable, Comparable, Sendable {
    /// Basic presence tracking only (v0.4 compatible)
    /// No messaging, discovery, or ephemeral data
    case presenceOnly = 0

    /// Enables node discovery and protocol messaging (v0.6.0-0.3)
    /// Required for semantic layer operations
    case presenceWithSignals = 1

    /// Enables ephemeral media within epoch (v0.6.4+)
    /// Includes all presenceWithSignals features plus media support
    case presenceWithEphemeralData = 2

    // MARK: - Capability Queries

    /// Whether node discovery is supported (INV21-22)
    var supportsDiscovery: Bool {
        rawValue >= EpochCapability.presenceWithSignals.rawValue
    }

    /// Whether protocol messaging is supported (INV23-25)
    var supportsMessaging: Bool {
        rawValue >= EpochCapability.presenceWithSignals.rawValue
    }

    /// Whether state synchronization is supported (INV26)
    var supportsStateSync: Bool {
        rawValue >= EpochCapability.presenceWithSignals.rawValue
    }

    /// Whether ephemeral media is supported (INV27-29)
    var supportsMedia: Bool {
        rawValue >= EpochCapability.presenceWithEphemeralData.rawValue
    }

    // MARK: - Comparable

    static func < (lhs: EpochCapability, rhs: EpochCapability) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    // MARK: - Display

    /// Human-readable name for the capability
    var displayName: String {
        switch self {
        case .presenceOnly:
            return "Presence Only"
        case .presenceWithSignals:
            return "Signals Enabled"
        case .presenceWithEphemeralData:
            return "Full Features"
        }
    }

    /// Short description of what features are enabled
    var featureDescription: String {
        switch self {
        case .presenceOnly:
            return "Basic presence tracking"
        case .presenceWithSignals:
            return "Discovery & messaging enabled"
        case .presenceWithEphemeralData:
            return "Discovery, messaging & media enabled"
        }
    }

    /// System image name for the capability
    var systemImage: String {
        switch self {
        case .presenceOnly:
            return "person.fill"
        case .presenceWithSignals:
            return "bubble.left.and.bubble.right.fill"
        case .presenceWithEphemeralData:
            return "camera.fill"
        }
    }

    /// Features enabled for this capability level
    var enabledFeatures: Set<EpochFeature> {
        switch self {
        case .presenceOnly:
            return [.presence]
        case .presenceWithSignals:
            return [.presence, .discovery, .messaging, .stateSync]
        case .presenceWithEphemeralData:
            return [.presence, .discovery, .messaging, .stateSync, .media]
        }
    }
}

/// Individual features that can be enabled by epoch capability
enum EpochFeature: String, CaseIterable, Sendable {
    case presence
    case discovery
    case messaging
    case stateSync
    case media
}
