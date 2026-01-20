import Foundation
import CoreLocation

/// Represents a time-bounded epoch in the 7ay-presence protocol
/// Epochs are the fundamental unit of ephemerality - all social data
/// is scoped to an epoch and destroyed when it closes.
struct Epoch: Identifiable, Equatable, Hashable, Sendable {
    /// Unique epoch identifier (on-chain epochId)
    let id: UInt64

    /// EpochRegistry contract address
    let contractAddress: Address

    /// Chain ID (11155111 for Sepolia)
    let chainId: UInt64

    // MARK: - On-Chain Data (from EpochRegistry._epochs[epochId])

    /// When the epoch starts (Active phase begins)
    let startTime: Date

    /// When the epoch ends (Closed phase begins)
    let endTime: Date

    /// Whether the epoch has been finalized on-chain
    let finalized: Bool

    /// Whether this epoch exists on-chain
    let exists: Bool

    // MARK: - Capability (from EpochRegistry._epochCapabilities[epochId])

    /// Epoch capability level determining available features
    let capability: EpochCapability

    /// Data policy hash (for PresenceWithEphemeralData epochs)
    let dataPolicyHash: Data?

    // MARK: - Metadata (from API, not on-chain)

    /// Human-readable epoch title
    let title: String

    /// Optional description
    let description: String?

    /// Number of participants who have declared presence
    let participantCount: UInt64

    /// Number of participants with validated presence
    let validatedCount: UInt64

    /// Optional tags for categorization
    let tags: [String]

    /// Optional location information
    let location: EpochLocation?

    // MARK: - Journey Properties

    /// ID of the journey this epoch belongs to (if any)
    var journeyId: String?

    /// Order of this epoch within its journey (1-indexed)
    var journeyOrder: Int?

    /// Whether this epoch is part of a journey
    var isPartOfJourney: Bool { journeyId != nil }

    // MARK: - Computed Properties

    /// Current epoch state computed from timestamps
    var state: EpochState {
        EpochState.compute(
            exists: exists,
            finalized: finalized,
            startTime: startTime,
            endTime: endTime
        )
    }

    /// Time remaining until next phase transition
    var timeUntilNextPhase: TimeInterval {
        let now = Date()
        switch state {
        case .scheduled:
            return startTime.timeIntervalSince(now)
        case .active:
            return endTime.timeIntervalSince(now)
        case .closed, .finalized, .none:
            return 0
        }
    }

    /// Duration of the epoch in seconds
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// Progress through the epoch (0.0 to 1.0) when active
    var progress: Double {
        guard state == .active else {
            return state == .closed || state == .finalized ? 1.0 : 0.0
        }
        let now = Date()
        let elapsed = now.timeIntervalSince(startTime)
        return min(max(elapsed / duration, 0.0), 1.0)
    }

    // MARK: - Capability Checks

    /// Whether ephemeral data is supported (INV14)
    var supportsEphemeralData: Bool {
        state == .active
    }

    /// Whether discovery is supported (INV21)
    var supportsDiscovery: Bool {
        state == .active && capability.supportsDiscovery
    }

    /// Whether messaging is supported (INV23)
    var supportsMessaging: Bool {
        state == .active && capability.supportsMessaging
    }

    /// Whether media is supported (INV27, INV29)
    var supportsMedia: Bool {
        state == .active && capability.supportsMedia
    }

    /// Whether the epoch can be joined
    var isJoinable: Bool {
        state.isJoinable
    }

    // MARK: - Map Support

    /// CLLocationCoordinate2D for MapKit integration
    var coordinate: CLLocationCoordinate2D? {
        guard let location = location else { return nil }
        return CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    /// Whether this epoch has a valid location for map display
    var hasLocation: Bool {
        location != nil
    }
}

// MARK: - Supporting Types

/// Optional location information for an epoch
struct EpochLocation: Equatable, Hashable, Codable, Sendable {
    let latitude: Double
    let longitude: Double
    let radius: Double // meters
    let name: String?

    /// Distance from a given coordinate in meters
    func distance(from lat: Double, lon: Double) -> Double {
        // Haversine formula for distance calculation
        let earthRadius = 6371000.0 // meters
        let dLat = (lat - latitude) * .pi / 180
        let dLon = (lon - longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(latitude * .pi / 180) * cos(lat * .pi / 180) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}

// MARK: - Factory Methods

extension Epoch {
    /// Create a mock epoch for previews and testing
    static func mock(
        id: UInt64 = 1,
        title: String = "Test Epoch",
        state: EpochState = .active,
        capability: EpochCapability = .presenceWithEphemeralData,
        participantCount: UInt64 = 42,
        location: EpochLocation? = nil
    ) -> Epoch {
        let now = Date()
        let startTime: Date
        let endTime: Date
        let finalized: Bool

        switch state {
        case .none:
            startTime = now.addingTimeInterval(3600)
            endTime = now.addingTimeInterval(7200)
            finalized = false
        case .scheduled:
            startTime = now.addingTimeInterval(3600)
            endTime = now.addingTimeInterval(7200)
            finalized = false
        case .active:
            startTime = now.addingTimeInterval(-1800)
            endTime = now.addingTimeInterval(1800)
            finalized = false
        case .closed:
            startTime = now.addingTimeInterval(-7200)
            endTime = now.addingTimeInterval(-3600)
            finalized = false
        case .finalized:
            startTime = now.addingTimeInterval(-7200)
            endTime = now.addingTimeInterval(-3600)
            finalized = true
        }

        return Epoch(
            id: id,
            contractAddress: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
            chainId: ProtocolConstants.chainId,
            startTime: startTime,
            endTime: endTime,
            finalized: finalized,
            exists: state != .none,
            capability: capability,
            dataPolicyHash: nil,
            title: title,
            description: "A test epoch for development",
            participantCount: participantCount,
            validatedCount: participantCount / 2,
            tags: ["test", "development"],
            location: location
        )
    }

    /// Create mock epochs with sample locations for map testing
    static func mockWithLocations() -> [Epoch] {
        // Sample locations around San Francisco
        let locations: [(lat: Double, lon: Double, name: String)] = [
            (37.7749, -122.4194, "Downtown SF"),
            (37.7849, -122.4094, "Financial District"),
            (37.7649, -122.4294, "SoMa"),
            (37.7949, -122.3994, "Embarcadero"),
            (37.7549, -122.4394, "Mission"),
            (37.7699, -122.4669, "Golden Gate Park"),
            (37.8044, -122.2712, "Oakland"),
            (37.7879, -122.4074, "Union Square")
        ]

        let titles = [
            "Tech Meetup 2026",
            "Coffee & Code",
            "Sunset Yoga Session",
            "Web3 Builders",
            "Music in the Park",
            "Art Walk",
            "Startup Pitch Night",
            "Food Festival"
        ]

        let states: [EpochState] = [.active, .active, .active, .scheduled, .scheduled, .active, .scheduled, .active]
        let capabilities: [EpochCapability] = [
            .presenceWithEphemeralData, .presenceWithSignals, .presenceOnly, .presenceWithSignals,
            .presenceWithEphemeralData, .presenceWithSignals, .presenceOnly, .presenceWithEphemeralData
        ]

        return locations.enumerated().map { index, loc in
            Epoch.mock(
                id: UInt64(index + 1),
                title: titles[index],
                state: states[index],
                capability: capabilities[index],
                participantCount: UInt64.random(in: 5...100),
                location: EpochLocation(
                    latitude: loc.lat,
                    longitude: loc.lon,
                    radius: 500,
                    name: loc.name
                )
            )
        }
    }
}
