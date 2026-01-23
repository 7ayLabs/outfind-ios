import SwiftUI

// MARK: - Main Radial Segment

/// Defines the 3 main segments of the radial menu
/// Each segment expands into its own sub-radial when selected
enum MainRadialSegment: String, CaseIterable, Identifiable {
    case createEpoch
    case camera
    case microphone

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .createEpoch: return "plus.circle.fill"
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        }
    }

    var displayName: String {
        switch self {
        case .createEpoch: return "Create"
        case .camera: return "Camera"
        case .microphone: return "Audio"
        }
    }

    var accentColor: Color {
        switch self {
        case .createEpoch: return Theme.Colors.primaryFallback
        case .camera: return Theme.Colors.info
        case .microphone: return Theme.Colors.warning
        }
    }

    /// Angle position in the radial layout (in degrees, 0 = top)
    var angle: Double {
        switch self {
        case .createEpoch: return 0      // Top
        case .camera: return 240         // Bottom-left
        case .microphone: return 120     // Bottom-right
        }
    }

    /// Sub-options for this segment's radial
    var subOptions: [RadialSubOption] {
        switch self {
        case .createEpoch:
            return [
                RadialSubOption(id: "30m", icon: "clock.fill", label: "30m", action: .setDuration(.thirtyMinutes)),
                RadialSubOption(id: "1h", icon: "clock.fill", label: "1h", action: .setDuration(.oneHour)),
                RadialSubOption(id: "2h", icon: "clock.fill", label: "2h", action: .setDuration(.twoHours)),
                RadialSubOption(id: "4h", icon: "clock.fill", label: "4h", action: .setDuration(.fourHours)),
                RadialSubOption(id: "public", icon: "globe", label: "Public", action: .setVisibility(.publicEpoch)),
                RadialSubOption(id: "friends", icon: "person.2.fill", label: "Friends", action: .setVisibility(.friends)),
            ]
        case .camera:
            return [
                RadialSubOption(id: "photo", icon: "camera.fill", label: "Photo", action: .capturePhoto),
                RadialSubOption(id: "video", icon: "video.fill", label: "Video", action: .captureVideo),
                RadialSubOption(id: "selfie", icon: "person.crop.circle", label: "Selfie", action: .captureSelfie),
                RadialSubOption(id: "flash", icon: "bolt.fill", label: "Flash", action: .toggleFlash),
            ]
        case .microphone:
            return [
                RadialSubOption(id: "voice", icon: "waveform", label: "Voice", action: .recordVoiceNote),
                RadialSubOption(id: "record", icon: "record.circle", label: "Record", action: .recordAudio),
                RadialSubOption(id: "15s", icon: "15.circle.fill", label: "15s", action: .setMaxDuration(15)),
                RadialSubOption(id: "30s", icon: "30.circle.fill", label: "30s", action: .setMaxDuration(30)),
                RadialSubOption(id: "60s", icon: "60.circle.fill", label: "60s", action: .setMaxDuration(60)),
            ]
        }
    }
}

// MARK: - Radial Sub-Option

/// A sub-option within a segment's radial menu
struct RadialSubOption: Identifiable, Equatable {
    let id: String
    let icon: String
    let label: String
    let action: RadialAction

    static func == (lhs: RadialSubOption, rhs: RadialSubOption) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Radial Action

/// Actions that can be triggered by selecting a sub-option
enum RadialAction: Equatable {
    // Epoch creation
    case setDuration(EpochDuration)
    case setVisibility(EpochVisibility)
    case setCapability(EpochCapability)
    case quickCreate

    // Camera actions
    case capturePhoto
    case captureVideo
    case captureSelfie
    case toggleFlash

    // Audio actions
    case recordAudio
    case recordVoiceNote
    case setMaxDuration(TimeInterval)
}

// MARK: - Capture Type

/// Types of media capture
enum CaptureType: Equatable {
    case photo
    case video
    case selfie
    case voiceNote
    case audioRecording
}

// MARK: - Radial Layout Constants

enum RadialLayoutConstants {
    /// Distance from center to main segments
    static let mainSegmentRadius: CGFloat = 90

    /// Size of main segment buttons
    static let mainSegmentSize: CGFloat = 56

    /// Distance from segment center to sub-options start
    static let subOptionStartRadius: CGFloat = 70

    /// Spacing between sub-options
    static let subOptionSpacing: CGFloat = 50

    /// Size of sub-option buttons
    static let subOptionSize: CGFloat = 44

    /// Angular spread of sub-options (degrees)
    static let subOptionArcSpread: Double = 120

    /// Center button size
    static let centerButtonSize: CGFloat = 48
}
