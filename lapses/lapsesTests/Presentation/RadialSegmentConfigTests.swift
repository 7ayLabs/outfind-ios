import Testing
import Foundation
@testable import lapses

/// Tests for RadialSegmentConfig and related types
struct MainRadialSegmentTests {

    // MARK: - Segment Properties Tests

    @Test("all main radial segments exist")
    func allSegmentsExist() {
        let segments = MainRadialSegment.allCases
        #expect(segments.count == 3)
        #expect(segments.contains(.createEpoch))
        #expect(segments.contains(.camera))
        #expect(segments.contains(.microphone))
    }

    @Test("segments have unique IDs")
    func uniqueIds() {
        let ids = MainRadialSegment.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == MainRadialSegment.allCases.count)
    }

    @Test("segments have valid SF Symbol icons")
    func validIcons() {
        for segment in MainRadialSegment.allCases {
            #expect(!segment.icon.isEmpty)
        }
        #expect(MainRadialSegment.createEpoch.icon == "plus.circle.fill")
        #expect(MainRadialSegment.camera.icon == "camera.fill")
        #expect(MainRadialSegment.microphone.icon == "mic.fill")
    }

    @Test("segments have display names")
    func displayNames() {
        #expect(MainRadialSegment.createEpoch.displayName == "Create")
        #expect(MainRadialSegment.camera.displayName == "Camera")
        #expect(MainRadialSegment.microphone.displayName == "Audio")
    }

    @Test("segments have distinct angles")
    func distinctAngles() {
        let angles = MainRadialSegment.allCases.map { $0.angle }
        let uniqueAngles = Set(angles)
        #expect(uniqueAngles.count == MainRadialSegment.allCases.count)
    }

    @Test("createEpoch is at top (0 degrees)")
    func createEpochAngle() {
        #expect(MainRadialSegment.createEpoch.angle == 0)
    }

    @Test("camera is at bottom-left (240 degrees)")
    func cameraAngle() {
        #expect(MainRadialSegment.camera.angle == 240)
    }

    @Test("microphone is at bottom-right (120 degrees)")
    func microphoneAngle() {
        #expect(MainRadialSegment.microphone.angle == 120)
    }

    // MARK: - Sub-Options Tests

    @Test("createEpoch has duration and visibility options")
    func createEpochSubOptions() {
        let options = MainRadialSegment.createEpoch.subOptions
        #expect(options.count >= 4) // At least 4 duration options

        // Check for duration options
        let durationOptions = options.filter {
            if case .setDuration = $0.action { return true }
            return false
        }
        #expect(durationOptions.count >= 4)

        // Check for visibility options
        let visibilityOptions = options.filter {
            if case .setVisibility = $0.action { return true }
            return false
        }
        #expect(visibilityOptions.count >= 2)
    }

    @Test("camera has capture options")
    func cameraSubOptions() {
        let options = MainRadialSegment.camera.subOptions
        #expect(options.count >= 3) // Photo, video, selfie at minimum

        let actionTypes = options.map { $0.action }
        #expect(actionTypes.contains(.capturePhoto))
        #expect(actionTypes.contains(.captureVideo))
        #expect(actionTypes.contains(.captureSelfie))
    }

    @Test("microphone has recording options")
    func microphoneSubOptions() {
        let options = MainRadialSegment.microphone.subOptions
        #expect(options.count >= 2) // Voice note and record at minimum

        let actionTypes = options.map { $0.action }
        #expect(actionTypes.contains(.recordVoiceNote))
        #expect(actionTypes.contains(.recordAudio))
    }

    @Test("all sub-options have unique IDs within segment")
    func uniqueSubOptionIds() {
        for segment in MainRadialSegment.allCases {
            let ids = segment.subOptions.map { $0.id }
            let uniqueIds = Set(ids)
            #expect(uniqueIds.count == segment.subOptions.count, "Duplicate IDs in \(segment.displayName)")
        }
    }

    @Test("all sub-options have icons and labels")
    func subOptionsHaveIconsAndLabels() {
        for segment in MainRadialSegment.allCases {
            for option in segment.subOptions {
                #expect(!option.icon.isEmpty, "Missing icon for \(option.id)")
                #expect(!option.label.isEmpty, "Missing label for \(option.id)")
            }
        }
    }
}

// MARK: - RadialSubOption Tests

struct RadialSubOptionTests {

    @Test("options are equatable by ID")
    func optionEquality() {
        let option1 = RadialSubOption(id: "test", icon: "star", label: "Test", action: .capturePhoto)
        let option2 = RadialSubOption(id: "test", icon: "star", label: "Test", action: .capturePhoto)
        let option3 = RadialSubOption(id: "other", icon: "star", label: "Test", action: .capturePhoto)

        #expect(option1 == option2)
        #expect(option1 != option3)
    }

    @Test("options are identifiable")
    func optionIdentifiable() {
        let option = RadialSubOption(id: "unique-id", icon: "star", label: "Test", action: .capturePhoto)
        #expect(option.id == "unique-id")
    }
}

// MARK: - RadialAction Tests

struct RadialActionTests {

    @Test("duration actions are equatable")
    func durationActionEquality() {
        let action1 = RadialAction.setDuration(.oneHour)
        let action2 = RadialAction.setDuration(.oneHour)
        let action3 = RadialAction.setDuration(.twoHours)

        #expect(action1 == action2)
        #expect(action1 != action3)
    }

    @Test("visibility actions are equatable")
    func visibilityActionEquality() {
        let action1 = RadialAction.setVisibility(.publicEpoch)
        let action2 = RadialAction.setVisibility(.publicEpoch)
        let action3 = RadialAction.setVisibility(.friends)

        #expect(action1 == action2)
        #expect(action1 != action3)
    }

    @Test("capture actions are equatable")
    func captureActionEquality() {
        #expect(RadialAction.capturePhoto == RadialAction.capturePhoto)
        #expect(RadialAction.captureVideo == RadialAction.captureVideo)
        #expect(RadialAction.captureSelfie == RadialAction.captureSelfie)
        #expect(RadialAction.capturePhoto != RadialAction.captureVideo)
    }

    @Test("audio actions are equatable")
    func audioActionEquality() {
        #expect(RadialAction.recordAudio == RadialAction.recordAudio)
        #expect(RadialAction.recordVoiceNote == RadialAction.recordVoiceNote)
        #expect(RadialAction.recordAudio != RadialAction.recordVoiceNote)
    }

    @Test("max duration actions are equatable")
    func maxDurationActionEquality() {
        let action1 = RadialAction.setMaxDuration(15)
        let action2 = RadialAction.setMaxDuration(15)
        let action3 = RadialAction.setMaxDuration(30)

        #expect(action1 == action2)
        #expect(action1 != action3)
    }

    @Test("different action types are not equal")
    func crossActionInequality() {
        let duration = RadialAction.setDuration(.oneHour)
        let visibility = RadialAction.setVisibility(.publicEpoch)
        let capture = RadialAction.capturePhoto

        #expect(duration != visibility)
        #expect(visibility != capture)
        #expect(capture != duration)
    }
}

// MARK: - CaptureType Tests

struct CaptureTypeTests {

    @Test("capture types are equatable")
    func captureTypeEquality() {
        #expect(CaptureType.photo == CaptureType.photo)
        #expect(CaptureType.video == CaptureType.video)
        #expect(CaptureType.selfie == CaptureType.selfie)
        #expect(CaptureType.voiceNote == CaptureType.voiceNote)
        #expect(CaptureType.audioRecording == CaptureType.audioRecording)
    }

    @Test("different capture types are not equal")
    func captureTypeInequality() {
        #expect(CaptureType.photo != CaptureType.video)
        #expect(CaptureType.video != CaptureType.selfie)
        #expect(CaptureType.voiceNote != CaptureType.audioRecording)
    }
}

// MARK: - RadialLayoutConstants Tests

struct RadialLayoutConstantsTests {

    @Test("main segment radius is positive")
    func mainSegmentRadius() {
        #expect(RadialLayoutConstants.mainSegmentRadius > 0)
    }

    @Test("main segment size is positive")
    func mainSegmentSize() {
        #expect(RadialLayoutConstants.mainSegmentSize > 0)
    }

    @Test("sub option start radius is positive")
    func subOptionStartRadius() {
        #expect(RadialLayoutConstants.subOptionStartRadius > 0)
    }

    @Test("sub option spacing is positive")
    func subOptionSpacing() {
        #expect(RadialLayoutConstants.subOptionSpacing > 0)
    }

    @Test("sub option size is positive")
    func subOptionSize() {
        #expect(RadialLayoutConstants.subOptionSize > 0)
    }

    @Test("sub option arc spread is reasonable")
    func subOptionArcSpread() {
        #expect(RadialLayoutConstants.subOptionArcSpread > 0)
        #expect(RadialLayoutConstants.subOptionArcSpread <= 360)
    }

    @Test("center button size is positive")
    func centerButtonSize() {
        #expect(RadialLayoutConstants.centerButtonSize > 0)
    }

    @Test("main segment is larger than sub options")
    func sizingHierarchy() {
        #expect(RadialLayoutConstants.mainSegmentSize > RadialLayoutConstants.subOptionSize)
    }
}
