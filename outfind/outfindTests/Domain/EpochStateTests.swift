import Testing
import Foundation
@testable import outfind

/// Tests for EpochState value object
struct EpochStateTests {

    // MARK: - State Computation Tests

    @Test("Compute returns .none when epoch doesn't exist")
    func computeReturnsNoneWhenNotExists() {
        let state = EpochState.compute(
            exists: false,
            finalized: false,
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600)
        )
        #expect(state == .none)
    }

    @Test("Compute returns .finalized when epoch is finalized")
    func computeReturnsFinalizedWhenFinalized() {
        let state = EpochState.compute(
            exists: true,
            finalized: true,
            startTime: Date().addingTimeInterval(-7200),
            endTime: Date().addingTimeInterval(-3600)
        )
        #expect(state == .finalized)
    }

    @Test("Compute returns .scheduled when current time is before start")
    func computeReturnsScheduledBeforeStart() {
        let now = Date()
        let state = EpochState.compute(
            exists: true,
            finalized: false,
            startTime: now.addingTimeInterval(3600),
            endTime: now.addingTimeInterval(7200),
            currentTime: now
        )
        #expect(state == .scheduled)
    }

    @Test("Compute returns .active when current time is between start and end")
    func computeReturnsActiveBetweenStartAndEnd() {
        let now = Date()
        let state = EpochState.compute(
            exists: true,
            finalized: false,
            startTime: now.addingTimeInterval(-1800),
            endTime: now.addingTimeInterval(1800),
            currentTime: now
        )
        #expect(state == .active)
    }

    @Test("Compute returns .closed when current time is after end")
    func computeReturnsClosedAfterEnd() {
        let now = Date()
        let state = EpochState.compute(
            exists: true,
            finalized: false,
            startTime: now.addingTimeInterval(-7200),
            endTime: now.addingTimeInterval(-3600),
            currentTime: now
        )
        #expect(state == .closed)
    }

    // MARK: - State Query Tests

    @Test("isJoinable returns true for scheduled and active states")
    func isJoinableReturnsCorrectValues() {
        #expect(EpochState.none.isJoinable == false)
        #expect(EpochState.scheduled.isJoinable == true)
        #expect(EpochState.active.isJoinable == true)
        #expect(EpochState.closed.isJoinable == false)
        #expect(EpochState.finalized.isJoinable == false)
    }

    @Test("supportsPresenceDeclaration returns true only for active state")
    func supportsPresenceDeclarationOnlyActive() {
        #expect(EpochState.none.supportsPresenceDeclaration == false)
        #expect(EpochState.scheduled.supportsPresenceDeclaration == false)
        #expect(EpochState.active.supportsPresenceDeclaration == true)
        #expect(EpochState.closed.supportsPresenceDeclaration == false)
        #expect(EpochState.finalized.supportsPresenceDeclaration == false)
    }

    @Test("isTerminal returns true only for finalized state")
    func isTerminalOnlyFinalized() {
        #expect(EpochState.none.isTerminal == false)
        #expect(EpochState.scheduled.isTerminal == false)
        #expect(EpochState.active.isTerminal == false)
        #expect(EpochState.closed.isTerminal == false)
        #expect(EpochState.finalized.isTerminal == true)
    }

    @Test("supportsEphemeralData returns true only for active state (INV14)")
    func supportsEphemeralDataOnlyActive() {
        #expect(EpochState.active.supportsEphemeralData == true)
        #expect(EpochState.closed.supportsEphemeralData == false)
        #expect(EpochState.finalized.supportsEphemeralData == false)
    }

    // MARK: - Raw Value Tests

    @Test("Raw values match protocol specification")
    func rawValuesMatchProtocol() {
        #expect(EpochState.none.rawValue == 0)
        #expect(EpochState.scheduled.rawValue == 1)
        #expect(EpochState.active.rawValue == 2)
        #expect(EpochState.closed.rawValue == 3)
        #expect(EpochState.finalized.rawValue == 4)
    }

    // MARK: - Display Tests

    @Test("displayName returns human-readable names")
    func displayNameReturnsReadableNames() {
        #expect(EpochState.none.displayName == "None")
        #expect(EpochState.scheduled.displayName == "Scheduled")
        #expect(EpochState.active.displayName == "Active")
        #expect(EpochState.closed.displayName == "Closed")
        #expect(EpochState.finalized.displayName == "Finalized")
    }
}
