import Testing
import Foundation
@testable import lapses

/// Tests for EpochCapability value object
struct EpochCapabilityTests {

    // MARK: - Capability Query Tests

    @Test("supportsDiscovery requires presenceWithSignals or higher (INV21-22)")
    func supportsDiscoveryRequiresSignals() {
        #expect(EpochCapability.presenceOnly.supportsDiscovery == false)
        #expect(EpochCapability.presenceWithSignals.supportsDiscovery == true)
        #expect(EpochCapability.presenceWithEphemeralData.supportsDiscovery == true)
    }

    @Test("supportsMessaging requires presenceWithSignals or higher (INV23-25)")
    func supportsMessagingRequiresSignals() {
        #expect(EpochCapability.presenceOnly.supportsMessaging == false)
        #expect(EpochCapability.presenceWithSignals.supportsMessaging == true)
        #expect(EpochCapability.presenceWithEphemeralData.supportsMessaging == true)
    }

    @Test("supportsStateSync requires presenceWithSignals or higher (INV26)")
    func supportsStateSyncRequiresSignals() {
        #expect(EpochCapability.presenceOnly.supportsStateSync == false)
        #expect(EpochCapability.presenceWithSignals.supportsStateSync == true)
        #expect(EpochCapability.presenceWithEphemeralData.supportsStateSync == true)
    }

    @Test("supportsMedia requires presenceWithEphemeralData (INV27-29)")
    func supportsMediaRequiresEphemeralData() {
        #expect(EpochCapability.presenceOnly.supportsMedia == false)
        #expect(EpochCapability.presenceWithSignals.supportsMedia == false)
        #expect(EpochCapability.presenceWithEphemeralData.supportsMedia == true)
    }

    // MARK: - Raw Value Tests

    @Test("Raw values match protocol specification")
    func rawValuesMatchProtocol() {
        #expect(EpochCapability.presenceOnly.rawValue == 0)
        #expect(EpochCapability.presenceWithSignals.rawValue == 1)
        #expect(EpochCapability.presenceWithEphemeralData.rawValue == 2)
    }

    // MARK: - Comparable Tests

    @Test("Capabilities are comparable by feature level")
    func capabilitiesAreComparable() {
        #expect(EpochCapability.presenceOnly < EpochCapability.presenceWithSignals)
        #expect(EpochCapability.presenceWithSignals < EpochCapability.presenceWithEphemeralData)
        #expect(EpochCapability.presenceOnly < EpochCapability.presenceWithEphemeralData)
    }

    // MARK: - Enabled Features Tests

    @Test("presenceOnly enables only presence feature")
    func presenceOnlyEnablesOnlyPresence() {
        let features = EpochCapability.presenceOnly.enabledFeatures
        #expect(features.contains(.presence))
        #expect(features.contains(.discovery) == false)
        #expect(features.contains(.messaging) == false)
        #expect(features.contains(.stateSync) == false)
        #expect(features.contains(.media) == false)
    }

    @Test("presenceWithSignals enables presence, discovery, messaging, stateSync")
    func presenceWithSignalsEnablesSignalFeatures() {
        let features = EpochCapability.presenceWithSignals.enabledFeatures
        #expect(features.contains(.presence))
        #expect(features.contains(.discovery))
        #expect(features.contains(.messaging))
        #expect(features.contains(.stateSync))
        #expect(features.contains(.media) == false)
    }

    @Test("presenceWithEphemeralData enables all features")
    func presenceWithEphemeralDataEnablesAllFeatures() {
        let features = EpochCapability.presenceWithEphemeralData.enabledFeatures
        #expect(features.contains(.presence))
        #expect(features.contains(.discovery))
        #expect(features.contains(.messaging))
        #expect(features.contains(.stateSync))
        #expect(features.contains(.media))
    }

    // MARK: - Display Tests

    @Test("displayName returns human-readable names")
    func displayNameReturnsReadableNames() {
        #expect(EpochCapability.presenceOnly.displayName == "Presence Only")
        #expect(EpochCapability.presenceWithSignals.displayName == "Signals Enabled")
        #expect(EpochCapability.presenceWithEphemeralData.displayName == "Full Features")
    }

    @Test("featureDescription provides meaningful descriptions")
    func featureDescriptionProvidesMeaningfulDescriptions() {
        for capability in EpochCapability.allCases {
            #expect(capability.featureDescription.isEmpty == false)
        }
    }

    @Test("systemImage returns valid SF Symbol names")
    func systemImageReturnsValidNames() {
        for capability in EpochCapability.allCases {
            #expect(capability.systemImage.isEmpty == false)
        }
    }

    // MARK: - Codable Tests

    @Test("EpochCapability encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for capability in EpochCapability.allCases {
            let data = try encoder.encode(capability)
            let decoded = try decoder.decode(EpochCapability.self, from: data)
            #expect(decoded == capability)
        }
    }
}
