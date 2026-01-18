import Testing
import Foundation
@testable import outfind

/// Tests for Epoch entity
struct EpochTests {

    // MARK: - State Computation Tests

    @Test("state is computed correctly from timestamps")
    func stateIsComputedFromTimestamps() {
        let now = Date()

        // Scheduled: startTime is in the future
        let scheduled = Epoch.mock(state: .scheduled)
        #expect(scheduled.state == .scheduled)

        // Active: now is between startTime and endTime
        let active = Epoch.mock(state: .active)
        #expect(active.state == .active)

        // Closed: endTime is in the past, not finalized
        let closed = Epoch.mock(state: .closed)
        #expect(closed.state == .closed)

        // Finalized: finalized flag is true
        let finalized = Epoch.mock(state: .finalized)
        #expect(finalized.state == .finalized)
    }

    // MARK: - Time Computation Tests

    @Test("timeUntilNextPhase returns positive for scheduled epochs")
    func timeUntilNextPhaseForScheduled() {
        let epoch = Epoch.mock(state: .scheduled)
        #expect(epoch.timeUntilNextPhase > 0)
    }

    @Test("timeUntilNextPhase returns positive for active epochs")
    func timeUntilNextPhaseForActive() {
        let epoch = Epoch.mock(state: .active)
        #expect(epoch.timeUntilNextPhase > 0)
    }

    @Test("timeUntilNextPhase returns 0 for closed/finalized epochs")
    func timeUntilNextPhaseForTerminalStates() {
        #expect(Epoch.mock(state: .closed).timeUntilNextPhase == 0)
        #expect(Epoch.mock(state: .finalized).timeUntilNextPhase == 0)
    }

    @Test("duration is calculated correctly")
    func durationIsCalculatedCorrectly() {
        let now = Date()
        let epoch = createEpoch(
            startTime: now,
            endTime: now.addingTimeInterval(3600),
            finalized: false,
            exists: true
        )
        #expect(epoch.duration == 3600)
    }

    @Test("progress returns 0 for scheduled epochs")
    func progressForScheduled() {
        let epoch = Epoch.mock(state: .scheduled)
        #expect(epoch.progress == 0.0)
    }

    @Test("progress returns value between 0 and 1 for active epochs")
    func progressForActive() {
        let epoch = Epoch.mock(state: .active)
        #expect(epoch.progress >= 0.0)
        #expect(epoch.progress <= 1.0)
    }

    @Test("progress returns 1 for closed/finalized epochs")
    func progressForTerminalStates() {
        #expect(Epoch.mock(state: .closed).progress == 1.0)
        #expect(Epoch.mock(state: .finalized).progress == 1.0)
    }

    // MARK: - Capability Check Tests

    @Test("supportsEphemeralData is true only when active (INV14)")
    func supportsEphemeralDataOnlyActive() {
        #expect(Epoch.mock(state: .scheduled).supportsEphemeralData == false)
        #expect(Epoch.mock(state: .active).supportsEphemeralData == true)
        #expect(Epoch.mock(state: .closed).supportsEphemeralData == false)
        #expect(Epoch.mock(state: .finalized).supportsEphemeralData == false)
    }

    @Test("supportsDiscovery requires active state and capable epoch (INV21)")
    func supportsDiscoveryRequiresActiveAndCapable() {
        // Active + presenceWithSignals = supports discovery
        #expect(Epoch.mock(state: .active, capability: .presenceWithSignals).supportsDiscovery == true)
        #expect(Epoch.mock(state: .active, capability: .presenceWithEphemeralData).supportsDiscovery == true)

        // Active + presenceOnly = no discovery
        #expect(Epoch.mock(state: .active, capability: .presenceOnly).supportsDiscovery == false)

        // Not active = no discovery
        #expect(Epoch.mock(state: .scheduled, capability: .presenceWithSignals).supportsDiscovery == false)
        #expect(Epoch.mock(state: .closed, capability: .presenceWithSignals).supportsDiscovery == false)
    }

    @Test("supportsMessaging requires active state and capable epoch (INV23)")
    func supportsMessagingRequiresActiveAndCapable() {
        #expect(Epoch.mock(state: .active, capability: .presenceWithSignals).supportsMessaging == true)
        #expect(Epoch.mock(state: .active, capability: .presenceOnly).supportsMessaging == false)
        #expect(Epoch.mock(state: .closed, capability: .presenceWithSignals).supportsMessaging == false)
    }

    @Test("supportsMedia requires active state and ephemeral data capability (INV27)")
    func supportsMediaRequiresActiveAndEphemeralData() {
        #expect(Epoch.mock(state: .active, capability: .presenceWithEphemeralData).supportsMedia == true)
        #expect(Epoch.mock(state: .active, capability: .presenceWithSignals).supportsMedia == false)
        #expect(Epoch.mock(state: .active, capability: .presenceOnly).supportsMedia == false)
        #expect(Epoch.mock(state: .closed, capability: .presenceWithEphemeralData).supportsMedia == false)
    }

    @Test("isJoinable matches state.isJoinable")
    func isJoinableMatchesState() {
        #expect(Epoch.mock(state: .scheduled).isJoinable == true)
        #expect(Epoch.mock(state: .active).isJoinable == true)
        #expect(Epoch.mock(state: .closed).isJoinable == false)
        #expect(Epoch.mock(state: .finalized).isJoinable == false)
    }

    // MARK: - Equatable/Hashable Tests

    @Test("Epochs with same ID are equal")
    func epochsWithSameIdAreEqual() {
        let epoch1 = Epoch.mock(id: 42, title: "First")
        let epoch2 = Epoch.mock(id: 42, title: "Second")
        #expect(epoch1 == epoch2)
    }

    @Test("Epochs with different IDs are not equal")
    func epochsWithDifferentIdsAreNotEqual() {
        let epoch1 = Epoch.mock(id: 1)
        let epoch2 = Epoch.mock(id: 2)
        #expect(epoch1 != epoch2)
    }

    @Test("Epoch can be used in Set")
    func epochCanBeUsedInSet() {
        var set: Set<Epoch> = []
        let epoch1 = Epoch.mock(id: 1)
        let epoch2 = Epoch.mock(id: 2)
        let epoch1Duplicate = Epoch.mock(id: 1)

        set.insert(epoch1)
        set.insert(epoch2)
        set.insert(epoch1Duplicate)

        #expect(set.count == 2)
    }

    // MARK: - Mock Factory Tests

    @Test("mock creates epoch with correct state")
    func mockCreatesCorrectState() {
        #expect(Epoch.mock(state: .none).exists == false)
        #expect(Epoch.mock(state: .scheduled).state == .scheduled)
        #expect(Epoch.mock(state: .active).state == .active)
        #expect(Epoch.mock(state: .closed).state == .closed)
        #expect(Epoch.mock(state: .finalized).finalized == true)
    }

    // MARK: - Helper

    private func createEpoch(
        startTime: Date,
        endTime: Date,
        finalized: Bool,
        exists: Bool
    ) -> Epoch {
        Epoch(
            id: 1,
            contractAddress: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
            chainId: ProtocolConstants.chainId,
            startTime: startTime,
            endTime: endTime,
            finalized: finalized,
            exists: exists,
            capability: .presenceWithEphemeralData,
            dataPolicyHash: nil,
            title: "Test",
            description: nil,
            participantCount: 0,
            validatedCount: 0,
            tags: [],
            location: nil
        )
    }
}

// MARK: - EpochLocation Tests

struct EpochLocationTests {

    @Test("distance calculation is approximately correct")
    func distanceCalculationIsApproximatelyCorrect() {
        // New York City coordinates
        let nyc = EpochLocation(
            latitude: 40.7128,
            longitude: -74.0060,
            radius: 1000,
            name: "NYC"
        )

        // Distance from NYC to itself should be 0
        #expect(nyc.distance(from: 40.7128, lon: -74.0060) < 1)

        // Distance from NYC to Los Angeles (approx 3940 km)
        let distanceToLA = nyc.distance(from: 34.0522, lon: -118.2437)
        #expect(distanceToLA > 3_900_000)
        #expect(distanceToLA < 4_000_000)
    }

    @Test("EpochLocation is Codable")
    func epochLocationIsCodable() throws {
        let location = EpochLocation(
            latitude: 40.7128,
            longitude: -74.0060,
            radius: 1000,
            name: "Test Location"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(location)
        let decoded = try decoder.decode(EpochLocation.self, from: data)

        #expect(decoded == location)
    }
}
