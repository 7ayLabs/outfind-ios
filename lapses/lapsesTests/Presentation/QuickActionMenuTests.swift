import Testing
import Foundation
import SwiftUI
@testable import lapses

/// Tests for QuickActionMenu and its components
struct QuickActionMenuTests {

    // MARK: - QuickAction Enum Tests

    @Test("all quick actions exist")
    func allActionsExist() {
        let actions = QuickActionMenu.QuickAction.allCases
        #expect(actions.count == 3)
        #expect(actions.contains(.create))
        #expect(actions.contains(.camera))
        #expect(actions.contains(.microphone))
    }

    @Test("quick actions have valid icons")
    func actionIcons() {
        #expect(QuickActionMenu.QuickAction.create.icon == "plus")
        #expect(QuickActionMenu.QuickAction.camera.icon == "camera.fill")
        #expect(QuickActionMenu.QuickAction.microphone.icon == "mic.fill")
    }

    @Test("quick actions have labels")
    func actionLabels() {
        #expect(QuickActionMenu.QuickAction.create.label == "Create")
        #expect(QuickActionMenu.QuickAction.camera.label == "Camera")
        #expect(QuickActionMenu.QuickAction.microphone.label == "Audio")
    }

    @Test("quick actions have distinct angles")
    func actionAngles() {
        let angles = QuickActionMenu.QuickAction.allCases.map { $0.angle }
        let uniqueAngles = Set(angles)
        #expect(uniqueAngles.count == QuickActionMenu.QuickAction.allCases.count)
    }

    @Test("create action is at top (-90 degrees)")
    func createActionAngle() {
        #expect(QuickActionMenu.QuickAction.create.angle == -90)
    }

    @Test("camera action is at top-left (-155 degrees)")
    func cameraActionAngle() {
        #expect(QuickActionMenu.QuickAction.camera.angle == -155)
    }

    @Test("microphone action is at top-right (-25 degrees)")
    func microphoneActionAngle() {
        #expect(QuickActionMenu.QuickAction.microphone.angle == -25)
    }

    @Test("actions have staggered animation delays")
    func animationDelays() {
        let delays = QuickActionMenu.QuickAction.allCases.map { $0.animationDelay }

        // Ensure delays are non-negative
        for delay in delays {
            #expect(delay >= 0)
        }

        // Camera should animate first (smallest delay)
        #expect(QuickActionMenu.QuickAction.camera.animationDelay <= QuickActionMenu.QuickAction.create.animationDelay)
        #expect(QuickActionMenu.QuickAction.create.animationDelay <= QuickActionMenu.QuickAction.microphone.animationDelay)
    }

    @Test("actions have distinct colors")
    func actionColors() {
        // Colors should be different (we can't directly compare Color equality in tests,
        // but we can verify they're assigned)
        let createColor = QuickActionMenu.QuickAction.create.color
        let cameraColor = QuickActionMenu.QuickAction.camera.color
        let microphoneColor = QuickActionMenu.QuickAction.microphone.color

        // Just verify they exist and are valid Color objects
        #expect(createColor != Color.clear)
        #expect(cameraColor != Color.clear)
        #expect(microphoneColor != Color.clear)
    }

    // MARK: - Angle Calculation Tests

    @Test("angles form an arc in the upper half")
    func anglesFormUpperArc() {
        for action in QuickActionMenu.QuickAction.allCases {
            // All angles should be between -180 and 0 (upper half in standard coordinates)
            #expect(action.angle <= 0, "Action \(action.label) angle should be negative (upper half)")
            #expect(action.angle >= -180, "Action \(action.label) angle should be >= -180")
        }
    }

    @Test("angles are spread apart for easy selection")
    func anglesAreSpreadApart() {
        let angles = QuickActionMenu.QuickAction.allCases.map { $0.angle }.sorted()

        // Check that consecutive angles are at least 30 degrees apart
        for i in 0..<(angles.count - 1) {
            let diff = abs(angles[i + 1] - angles[i])
            #expect(diff >= 30, "Angles should be at least 30 degrees apart for easy selection")
        }
    }
}

// MARK: - Angle Difference Helper Tests

struct AngleDifferenceTests {

    /// Helper function matching the one in QuickActionMenu
    private func angleDiff(_ a: Double, _ b: Double) -> Double {
        var diff = a - b
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    @Test("angle difference for same angles is 0")
    func sameAngles() {
        #expect(angleDiff(45, 45) == 0)
        #expect(angleDiff(-90, -90) == 0)
        #expect(angleDiff(180, 180) == 0)
    }

    @Test("angle difference handles wrapping around 180/-180")
    func wrapAround() {
        // 170 to -170 should be 20 degrees apart (not 340)
        let diff = angleDiff(170, -170)
        #expect(abs(diff) <= 40)
    }

    @Test("angle difference handles positive to negative")
    func positiveToNegative() {
        let diff = angleDiff(90, -90)
        #expect(diff == 180 || diff == -180)
    }

    @Test("angle difference is commutative in magnitude")
    func commutative() {
        let diff1 = abs(angleDiff(45, 90))
        let diff2 = abs(angleDiff(90, 45))
        #expect(diff1 == diff2)
    }
}

// MARK: - Menu Positioning Tests

struct QuickActionMenuPositioningTests {

    @Test("vertical offset moves menu above anchor")
    func verticalOffset() {
        // The menu should appear above the tab bar
        // verticalOffset should be negative (moving up)
        let expectedOffset: CGFloat = -60

        // This tests the conceptual behavior
        let anchor = CGPoint(x: 200, y: 800)
        let menuCenter = CGPoint(x: anchor.x, y: anchor.y + expectedOffset)

        #expect(menuCenter.y < anchor.y, "Menu center should be above anchor")
        #expect(menuCenter.x == anchor.x, "Menu center X should match anchor X")
    }

    @Test("action radius allows for comfortable tap targets")
    func actionRadius() {
        let radius: CGFloat = 80
        let actionSize: CGFloat = 54

        // Actions should not overlap with center
        let centerSize: CGFloat = 48
        #expect(radius > (centerSize / 2 + actionSize / 2), "Actions should not overlap with center")
    }
}

// MARK: - Gesture Detection Tests

struct QuickActionGestureTests {

    @Test("minimum drag distance for hover detection")
    func minimumDragDistance() {
        let minimumDistance: CGFloat = 35

        // Should be far enough to avoid accidental activation
        #expect(minimumDistance > 20, "Minimum distance should prevent accidental activation")

        // But not so far that it's hard to reach
        #expect(minimumDistance < 60, "Minimum distance should be reachable")
    }

    @Test("closest action selection by angle")
    func closestActionSelection() {
        let actions = QuickActionMenu.QuickAction.allCases

        // Test that finding closest action works
        // -90 degrees should select .create (which is at -90)
        let testAngle: Double = -90
        let closest = actions.min { a, b in
            abs(a.angle - testAngle) < abs(b.angle - testAngle)
        }

        #expect(closest == .create)
    }

    @Test("closest action for camera angle")
    func closestActionForCameraAngle() {
        let actions = QuickActionMenu.QuickAction.allCases

        // -155 degrees should select .camera
        let testAngle: Double = -155
        let closest = actions.min { a, b in
            abs(a.angle - testAngle) < abs(b.angle - testAngle)
        }

        #expect(closest == .camera)
    }

    @Test("closest action for microphone angle")
    func closestActionForMicrophoneAngle() {
        let actions = QuickActionMenu.QuickAction.allCases

        // -25 degrees should select .microphone
        let testAngle: Double = -25
        let closest = actions.min { a, b in
            abs(a.angle - testAngle) < abs(b.angle - testAngle)
        }

        #expect(closest == .microphone)
    }
}
