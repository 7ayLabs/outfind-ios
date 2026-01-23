import Testing
import Foundation
@testable import lapses

/// Tests for Presence entity
struct PresenceTests {

    // MARK: - ID Computation Tests

    @Test("id is composite of epochId and actor address")
    func idIsCompositeOfEpochIdAndActor() {
        let address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        let presence = Presence(
            epochId: 42,
            actor: address,
            state: .declared,
            declaredAt: Date(),
            validatedAt: nil,
            validationCount: 0
        )
        #expect(presence.id == "42:\(address.hex)")
    }

    // MARK: - Capability Check Tests

    @Test("canDiscover requires active epoch with signals capability and interactable state (INV21-22)")
    func canDiscoverRequiresAllConditions() {
        let presence = Presence.mock(state: .validated)

        // All conditions met
        let activeSignals = Epoch.mock(state: .active, capability: .presenceWithSignals)
        #expect(presence.canDiscover(in: activeSignals) == true)

        // Not active
        let scheduledSignals = Epoch.mock(state: .scheduled, capability: .presenceWithSignals)
        #expect(presence.canDiscover(in: scheduledSignals) == false)

        // No signals capability
        let activePresenceOnly = Epoch.mock(state: .active, capability: .presenceOnly)
        #expect(presence.canDiscover(in: activePresenceOnly) == false)

        // Presence can't interact
        let nonePresence = Presence.mock(state: .none)
        #expect(nonePresence.canDiscover(in: activeSignals) == false)
    }

    @Test("canMessage requires active epoch with messaging capability and interactable state (INV23)")
    func canMessageRequiresAllConditions() {
        let presence = Presence.mock(state: .declared)

        let activeSignals = Epoch.mock(state: .active, capability: .presenceWithSignals)
        #expect(presence.canMessage(in: activeSignals) == true)

        let activePresenceOnly = Epoch.mock(state: .active, capability: .presenceOnly)
        #expect(presence.canMessage(in: activePresenceOnly) == false)

        let slashedPresence = Presence.mock(state: .slashed)
        #expect(slashedPresence.canMessage(in: activeSignals) == false)
    }

    @Test("canCaptureMedia requires active epoch with ephemeral data capability (INV27)")
    func canCaptureMediaRequiresEphemeralData() {
        let presence = Presence.mock(state: .validated)

        let activeEphemeral = Epoch.mock(state: .active, capability: .presenceWithEphemeralData)
        #expect(presence.canCaptureMedia(in: activeEphemeral) == true)

        let activeSignals = Epoch.mock(state: .active, capability: .presenceWithSignals)
        #expect(presence.canCaptureMedia(in: activeSignals) == false)
    }

    @Test("canViewMedia requires active epoch with ephemeral data capability (INV29)")
    func canViewMediaRequiresActiveEphemeralData() {
        let presence = Presence.mock(state: .validated)

        let activeEphemeral = Epoch.mock(state: .active, capability: .presenceWithEphemeralData)
        #expect(presence.canViewMedia(in: activeEphemeral) == true)

        // Closed epoch = no media access per INV29
        let closedEphemeral = Epoch.mock(state: .closed, capability: .presenceWithEphemeralData)
        #expect(presence.canViewMedia(in: closedEphemeral) == false)
    }

    @Test("canInteract delegates to state.canInteract")
    func canInteractDelegatesToState() {
        #expect(Presence.mock(state: .none).canInteract == false)
        #expect(Presence.mock(state: .declared).canInteract == true)
        #expect(Presence.mock(state: .validated).canInteract == true)
        #expect(Presence.mock(state: .finalized).canInteract == true)
        #expect(Presence.mock(state: .slashed).canInteract == false)
    }

    @Test("isDiscoverable delegates to state.isDiscoverable")
    func isDiscoverableDelegatesToState() {
        for state in PresenceState.allCases {
            let presence = Presence.mock(state: state)
            #expect(presence.isDiscoverable == state.isDiscoverable)
        }
    }

    // MARK: - Validation Progress Tests

    @Test("validationProgress returns correct percentage")
    func validationProgressReturnsCorrectPercentage() {
        let presence = Presence(
            epochId: 1,
            actor: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
            state: .declared,
            declaredAt: Date(),
            validatedAt: nil,
            validationCount: 2
        )

        // 2 out of 5 = 40%
        #expect(presence.validationProgress(quorumSize: 5) == 0.4)

        // 2 out of 2 = 100%
        #expect(presence.validationProgress(quorumSize: 2) == 1.0)

        // 2 out of 1 = capped at 100%
        #expect(presence.validationProgress(quorumSize: 1) == 1.0)
    }

    @Test("validationProgress returns 0 when quorum is 0")
    func validationProgressReturnsZeroWhenQuorumZero() {
        let presence = Presence.mock(state: .declared, validationCount: 5)
        #expect(presence.validationProgress(quorumSize: 0) == 0.0)
    }

    @Test("validationProgress returns 1 for already validated/finalized")
    func validationProgressReturnsOneForValidated() {
        #expect(Presence.mock(state: .validated).validationProgress(quorumSize: 5) == 1.0)
        #expect(Presence.mock(state: .finalized).validationProgress(quorumSize: 5) == 1.0)
    }

    @Test("validationProgress returns 0 for none/slashed")
    func validationProgressReturnsZeroForInvalid() {
        #expect(Presence.mock(state: .none).validationProgress(quorumSize: 5) == 0.0)
        #expect(Presence.mock(state: .slashed).validationProgress(quorumSize: 5) == 0.0)
    }

    @Test("votesNeeded returns remaining votes correctly")
    func votesNeededReturnsRemainingVotes() {
        let presence = Presence(
            epochId: 1,
            actor: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
            state: .declared,
            declaredAt: Date(),
            validatedAt: nil,
            validationCount: 2
        )

        #expect(presence.votesNeeded(quorumSize: 5) == 3)
        #expect(presence.votesNeeded(quorumSize: 2) == 0)
        #expect(presence.votesNeeded(quorumSize: 1) == 0)
    }

    @Test("votesNeeded returns 0 for non-declared states")
    func votesNeededReturnsZeroForNonDeclared() {
        #expect(Presence.mock(state: .none).votesNeeded(quorumSize: 5) == 0)
        #expect(Presence.mock(state: .validated).votesNeeded(quorumSize: 5) == 0)
        #expect(Presence.mock(state: .finalized).votesNeeded(quorumSize: 5) == 0)
        #expect(Presence.mock(state: .slashed).votesNeeded(quorumSize: 5) == 0)
    }

    // MARK: - Factory Method Tests

    @Test("none factory creates presence with none state")
    func noneFactoryCreatesNoneState() {
        let address = Address(rawValue: "0x1234567890123456789012345678901234567890")!
        let presence = Presence.none(epochId: 42, actor: address)

        #expect(presence.epochId == 42)
        #expect(presence.actor == address)
        #expect(presence.state == .none)
        #expect(presence.declaredAt == nil)
        #expect(presence.validatedAt == nil)
        #expect(presence.validationCount == 0)
    }

    @Test("mock factory creates presence with correct state")
    func mockFactoryCreatesCorrectState() {
        let validated = Presence.mock(state: .validated)
        #expect(validated.state == .validated)
        #expect(validated.declaredAt != nil)
        #expect(validated.validatedAt != nil)

        let declared = Presence.mock(state: .declared)
        #expect(declared.state == .declared)
        #expect(declared.declaredAt != nil)
        #expect(declared.validatedAt == nil)
    }

    // MARK: - Equatable/Hashable Tests

    @Test("Presences with same id are equal")
    func presencesWithSameIdAreEqual() {
        let presence1 = Presence.mock(epochId: 1, state: .declared)
        let presence2 = Presence.mock(epochId: 1, state: .validated)
        #expect(presence1 == presence2)
    }

    @Test("Presences with different ids are not equal")
    func presencesWithDifferentIdsAreNotEqual() {
        let presence1 = Presence.mock(epochId: 1)
        let presence2 = Presence.mock(epochId: 2)
        #expect(presence1 != presence2)
    }
}

// MARK: - PresenceUpdate Tests

struct PresenceUpdateTests {

    @Test("PresenceUpdate cases are equatable")
    func presenceUpdateCasesAreEquatable() {
        #expect(PresenceUpdate.stateChanged(.declared) == PresenceUpdate.stateChanged(.declared))
        #expect(PresenceUpdate.stateChanged(.declared) != PresenceUpdate.stateChanged(.validated))

        #expect(PresenceUpdate.validationProgress(count: 2, quorum: 5) == PresenceUpdate.validationProgress(count: 2, quorum: 5))
        #expect(PresenceUpdate.validationProgress(count: 2, quorum: 5) != PresenceUpdate.validationProgress(count: 3, quorum: 5))

        #expect(PresenceUpdate.slashed(reason: "test") == PresenceUpdate.slashed(reason: "test"))
        #expect(PresenceUpdate.slashed(reason: "a") != PresenceUpdate.slashed(reason: "b"))

        #expect(PresenceUpdate.error("msg") == PresenceUpdate.error("msg"))
        #expect(PresenceUpdate.error("a") != PresenceUpdate.error("b"))
    }
}
