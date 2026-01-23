import Testing
import Foundation
@testable import lapses

/// Tests for PresenceState value object
struct PresenceStateTests {

    // MARK: - State Query Tests

    @Test("canInteract returns true for declared, validated, and finalized states")
    func canInteractReturnsCorrectValues() {
        #expect(PresenceState.none.canInteract == false)
        #expect(PresenceState.declared.canInteract == true)
        #expect(PresenceState.validated.canInteract == true)
        #expect(PresenceState.finalized.canInteract == true)
        #expect(PresenceState.slashed.canInteract == false)
    }

    @Test("isTerminal returns true only for finalized and slashed states")
    func isTerminalReturnsCorrectValues() {
        #expect(PresenceState.none.isTerminal == false)
        #expect(PresenceState.declared.isTerminal == false)
        #expect(PresenceState.validated.isTerminal == false)
        #expect(PresenceState.finalized.isTerminal == true)
        #expect(PresenceState.slashed.isTerminal == true)
    }

    @Test("requiresValidation returns true only for declared state")
    func requiresValidationOnlyDeclared() {
        #expect(PresenceState.none.requiresValidation == false)
        #expect(PresenceState.declared.requiresValidation == true)
        #expect(PresenceState.validated.requiresValidation == false)
        #expect(PresenceState.finalized.requiresValidation == false)
        #expect(PresenceState.slashed.requiresValidation == false)
    }

    @Test("isDiscoverable matches canInteract per INV22")
    func isDiscoverableMatchesCanInteract() {
        for state in PresenceState.allCases {
            #expect(state.isDiscoverable == state.canInteract)
        }
    }

    // MARK: - State Transition Tests

    @Test("validNextStates for none is only declared")
    func noneCanOnlyTransitionToDeclared() {
        #expect(PresenceState.none.validNextStates == [.declared])
    }

    @Test("validNextStates for declared includes validated and slashed")
    func declaredCanTransitionToValidatedOrSlashed() {
        #expect(PresenceState.declared.validNextStates == [.validated, .slashed])
    }

    @Test("validNextStates for validated includes finalized and slashed")
    func validatedCanTransitionToFinalizedOrSlashed() {
        #expect(PresenceState.validated.validNextStates == [.finalized, .slashed])
    }

    @Test("validNextStates for terminal states is empty")
    func terminalStatesHaveNoNextStates() {
        #expect(PresenceState.finalized.validNextStates.isEmpty)
        #expect(PresenceState.slashed.validNextStates.isEmpty)
    }

    @Test("canTransition validates transitions correctly")
    func canTransitionValidatesCorrectly() {
        // Valid transitions
        #expect(PresenceState.none.canTransition(to: .declared) == true)
        #expect(PresenceState.declared.canTransition(to: .validated) == true)
        #expect(PresenceState.declared.canTransition(to: .slashed) == true)
        #expect(PresenceState.validated.canTransition(to: .finalized) == true)
        #expect(PresenceState.validated.canTransition(to: .slashed) == true)

        // Invalid transitions
        #expect(PresenceState.none.canTransition(to: .validated) == false)
        #expect(PresenceState.none.canTransition(to: .finalized) == false)
        #expect(PresenceState.declared.canTransition(to: .finalized) == false)
        #expect(PresenceState.finalized.canTransition(to: .declared) == false)
        #expect(PresenceState.slashed.canTransition(to: .validated) == false)
    }

    // MARK: - Raw Value Tests

    @Test("Raw values match protocol specification")
    func rawValuesMatchProtocol() {
        #expect(PresenceState.none.rawValue == 0)
        #expect(PresenceState.declared.rawValue == 1)
        #expect(PresenceState.validated.rawValue == 2)
        #expect(PresenceState.finalized.rawValue == 3)
        #expect(PresenceState.slashed.rawValue == 4)
    }

    // MARK: - Comparable Tests

    @Test("States are comparable by progression")
    func statesAreComparableByProgression() {
        #expect(PresenceState.none < PresenceState.declared)
        #expect(PresenceState.declared < PresenceState.validated)
        #expect(PresenceState.validated < PresenceState.finalized)
        #expect(PresenceState.finalized < PresenceState.slashed)
    }

    // MARK: - Display Tests

    @Test("displayName returns human-readable names")
    func displayNameReturnsReadableNames() {
        #expect(PresenceState.none.displayName == "Not Joined")
        #expect(PresenceState.declared.displayName == "Declared")
        #expect(PresenceState.validated.displayName == "Validated")
        #expect(PresenceState.finalized.displayName == "Finalized")
        #expect(PresenceState.slashed.displayName == "Slashed")
    }

    @Test("stateDescription provides meaningful descriptions")
    func stateDescriptionProvidesMeaningfulDescriptions() {
        #expect(PresenceState.none.stateDescription.isEmpty == false)
        #expect(PresenceState.declared.stateDescription.isEmpty == false)
        #expect(PresenceState.validated.stateDescription.isEmpty == false)
        #expect(PresenceState.finalized.stateDescription.isEmpty == false)
        #expect(PresenceState.slashed.stateDescription.isEmpty == false)
    }

    @Test("systemImage returns valid SF Symbol names")
    func systemImageReturnsValidNames() {
        for state in PresenceState.allCases {
            #expect(state.systemImage.isEmpty == false)
        }
    }

    @Test("colorName returns valid color names")
    func colorNameReturnsValidNames() {
        for state in PresenceState.allCases {
            #expect(state.colorName.isEmpty == false)
        }
    }

    // MARK: - Codable Tests

    @Test("PresenceState encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for state in PresenceState.allCases {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(PresenceState.self, from: data)
            #expect(decoded == state)
        }
    }
}
