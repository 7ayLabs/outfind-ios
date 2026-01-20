import SwiftUI
import Combine

// MARK: - Radial Menu View Model

/// Manages state for the 3-segment nested radial menu
/// Each segment expands into its own sub-radial when selected
@Observable
final class RadialMenuViewModel {
    // MARK: - Main Segment State

    /// Currently expanded segment (shows sub-radial)
    var expandedSegment: MainRadialSegment?

    /// Currently hovered/active sub-option index
    var activeSubOption: Int?

    // MARK: - Epoch Creation State

    var selectedDuration: EpochDuration = .twoHours
    var selectedVisibility: EpochVisibility = .publicEpoch
    var selectedCapability: EpochCapability = .presenceWithSignals

    // MARK: - Capture State

    /// Pending capture type after selection
    var pendingCaptureType: CaptureType?

    /// Flash enabled state
    var isFlashEnabled: Bool = false

    /// Max audio recording duration
    var maxAudioDuration: TimeInterval = 30

    // MARK: - Gesture State

    var isDragging = false
    var dragAngle: Double = 0
    var dragDistance: CGFloat = 0

    // MARK: - Completion State

    /// Whether epoch creation requirements are met
    var isReadyToCreate: Bool {
        expandedSegment == .createEpoch && selectedDuration != .thirtyMinutes
    }

    // MARK: - Segment Detection

    /// Get the main segment at a given angle (from center)
    func segmentAt(angle: Double) -> MainRadialSegment? {
        // Normalize angle to 0-360
        var normalizedAngle = angle
        if normalizedAngle < 0 { normalizedAngle += 360 }

        // Each segment covers 120° centered on its angle
        for segment in MainRadialSegment.allCases {
            let segmentAngle = segment.angle
            let halfSpread: Double = 60 // 120° / 2

            var start = segmentAngle - halfSpread
            var end = segmentAngle + halfSpread

            // Normalize
            if start < 0 { start += 360 }
            if end >= 360 { end -= 360 }

            // Check if angle is within segment bounds
            if start < end {
                if normalizedAngle >= start && normalizedAngle < end {
                    return segment
                }
            } else {
                // Handles wrap-around (e.g., 300-60 degrees)
                if normalizedAngle >= start || normalizedAngle < end {
                    return segment
                }
            }
        }
        return nil
    }

    /// Get sub-option index based on drag distance
    func subOptionIndex(distance: CGFloat, for segment: MainRadialSegment) -> Int? {
        let startDistance = RadialLayoutConstants.subOptionStartRadius
        guard distance > startDistance - 20 else { return nil }

        let options = segment.subOptions
        let spacing = RadialLayoutConstants.subOptionSpacing * 0.3
        let distanceIntoOptions = distance - startDistance + spacing / 2
        let index = Int(distanceIntoOptions / spacing)

        return min(max(0, index), options.count - 1)
    }

    // MARK: - Actions

    /// Expand a segment to show its sub-radial
    func expandSegment(_ segment: MainRadialSegment) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if expandedSegment == segment {
                expandedSegment = nil
                activeSubOption = nil
            } else {
                expandedSegment = segment
                activeSubOption = nil
            }
        }
    }

    /// Select a sub-option from the expanded radial
    func selectSubOption(_ option: RadialSubOption) {
        handleAction(option.action)
    }

    /// Handle the action from a selected sub-option
    private func handleAction(_ action: RadialAction) {
        switch action {
        // Epoch creation
        case .setDuration(let duration):
            selectedDuration = duration
            RadialHaptics.shared.selectionMade()

        case .setVisibility(let visibility):
            selectedVisibility = visibility
            RadialHaptics.shared.selectionMade()

        case .setCapability(let capability):
            selectedCapability = capability
            RadialHaptics.shared.selectionMade()

        case .quickCreate:
            RadialHaptics.shared.celebrate()

        // Camera actions
        case .capturePhoto:
            pendingCaptureType = .photo
            RadialHaptics.shared.selectionMade()

        case .captureVideo:
            pendingCaptureType = .video
            RadialHaptics.shared.selectionMade()

        case .captureSelfie:
            pendingCaptureType = .selfie
            RadialHaptics.shared.selectionMade()

        case .toggleFlash:
            isFlashEnabled.toggle()
            RadialHaptics.shared.selectionMade()

        // Audio actions
        case .recordAudio:
            pendingCaptureType = .audioRecording
            RadialHaptics.shared.selectionMade()

        case .recordVoiceNote:
            pendingCaptureType = .voiceNote
            RadialHaptics.shared.selectionMade()

        case .setMaxDuration(let duration):
            maxAudioDuration = duration
            RadialHaptics.shared.selectionMade()
        }
    }

    /// Reset all state
    func reset() {
        expandedSegment = nil
        activeSubOption = nil
        selectedDuration = .twoHours
        selectedVisibility = .publicEpoch
        selectedCapability = .presenceWithSignals
        pendingCaptureType = nil
        isFlashEnabled = false
        maxAudioDuration = 30
        isDragging = false
        dragAngle = 0
        dragDistance = 0
    }

    /// Clear pending capture type
    func clearPendingCapture() {
        pendingCaptureType = nil
    }
}

// MARK: - Epoch Duration

enum EpochDuration: String, CaseIterable {
    case thirtyMinutes = "30m"
    case oneHour = "1h"
    case twoHours = "2h"
    case fourHours = "4h"
    case eightHours = "8h"
    case twentyFourHours = "24h"

    var displayText: String { rawValue }

    var shortText: String {
        switch self {
        case .thirtyMinutes: return "30min"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .fourHours: return "4 hours"
        case .eightHours: return "8 hours"
        case .twentyFourHours: return "24 hours"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        case .twoHours: return 7200
        case .fourHours: return 14400
        case .eightHours: return 28800
        case .twentyFourHours: return 86400
        }
    }
}

// MARK: - Epoch Visibility

enum EpochVisibility: String, CaseIterable {
    case publicEpoch = "public"
    case friends = "friends"
    case privateEpoch = "private"

    var displayText: String {
        switch self {
        case .publicEpoch: return "Public"
        case .friends: return "Friends"
        case .privateEpoch: return "Private"
        }
    }

    var icon: String {
        switch self {
        case .publicEpoch: return "globe"
        case .friends: return "person.2.fill"
        case .privateEpoch: return "lock.fill"
        }
    }
}

// MARK: - Epoch Category

enum EpochCategory: String, CaseIterable {
    case social
    case work
    case event
    case gaming
    case creative

    var displayText: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .social: return "🎉"
        case .work: return "💼"
        case .event: return "🎪"
        case .gaming: return "🎮"
        case .creative: return "🎨"
        }
    }
}

// MARK: - Epoch Location

enum RadialLocationOption: String, CaseIterable {
    case current
    case custom
    case none

    var displayText: String {
        switch self {
        case .current: return "Current"
        case .custom: return "Custom"
        case .none: return "None"
        }
    }

    var icon: String {
        switch self {
        case .current: return "location.fill"
        case .custom: return "mappin"
        case .none: return "location.slash"
        }
    }
}
