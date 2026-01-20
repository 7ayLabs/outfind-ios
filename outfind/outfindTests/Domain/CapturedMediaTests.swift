import Testing
import Foundation
@testable import outfind

/// Tests for CapturedMedia entity
struct CapturedMediaTests {

    // MARK: - Type Check Tests

    @Test("photo returns true for isPhoto")
    func photoTypeCheck() {
        let media = CapturedMedia.photo(Data([0x01, 0x02, 0x03]))
        #expect(media.isPhoto == true)
        #expect(media.isVideo == false)
        #expect(media.isAudio == false)
    }

    @Test("video returns true for isVideo")
    func videoTypeCheck() {
        let url = URL(fileURLWithPath: "/tmp/video.mp4")
        let media = CapturedMedia.video(url)
        #expect(media.isPhoto == false)
        #expect(media.isVideo == true)
        #expect(media.isAudio == false)
    }

    @Test("audio returns true for isAudio")
    func audioTypeCheck() {
        let url = URL(fileURLWithPath: "/tmp/audio.m4a")
        let media = CapturedMedia.audio(url, duration: 15.0)
        #expect(media.isPhoto == false)
        #expect(media.isVideo == false)
        #expect(media.isAudio == true)
    }

    // MARK: - Accessor Tests

    @Test("photoData returns data for photo media")
    func photoDataAccessor() {
        let data = Data([0x01, 0x02, 0x03])
        let media = CapturedMedia.photo(data)
        #expect(media.photoData == data)
        #expect(media.videoURL == nil)
        #expect(media.audioURL == nil)
        #expect(media.audioDuration == nil)
    }

    @Test("videoURL returns URL for video media")
    func videoURLAccessor() {
        let url = URL(fileURLWithPath: "/tmp/video.mp4")
        let media = CapturedMedia.video(url)
        #expect(media.photoData == nil)
        #expect(media.videoURL == url)
        #expect(media.audioURL == nil)
        #expect(media.audioDuration == nil)
    }

    @Test("audioURL and audioDuration return values for audio media")
    func audioAccessors() {
        let url = URL(fileURLWithPath: "/tmp/audio.m4a")
        let duration: TimeInterval = 30.0
        let media = CapturedMedia.audio(url, duration: duration)
        #expect(media.photoData == nil)
        #expect(media.videoURL == nil)
        #expect(media.audioURL == url)
        #expect(media.audioDuration == duration)
    }

    // MARK: - Display Tests

    @Test("typeDescription returns correct strings")
    func typeDescriptions() {
        #expect(CapturedMedia.photo(Data()).typeDescription == "Photo")
        #expect(CapturedMedia.video(URL(fileURLWithPath: "/tmp/v.mp4")).typeDescription == "Video")
        #expect(CapturedMedia.audio(URL(fileURLWithPath: "/tmp/a.m4a"), duration: 10).typeDescription == "Audio")
    }

    @Test("iconName returns correct SF Symbols")
    func iconNames() {
        #expect(CapturedMedia.photo(Data()).iconName == "photo.fill")
        #expect(CapturedMedia.video(URL(fileURLWithPath: "/tmp/v.mp4")).iconName == "video.fill")
        #expect(CapturedMedia.audio(URL(fileURLWithPath: "/tmp/a.m4a"), duration: 10).iconName == "waveform")
    }

    // MARK: - Equatable Tests

    @Test("photos with same data are equal")
    func photoEquality() {
        let data = Data([0x01, 0x02, 0x03])
        let media1 = CapturedMedia.photo(data)
        let media2 = CapturedMedia.photo(data)
        #expect(media1 == media2)
    }

    @Test("photos with different data are not equal")
    func photoInequality() {
        let media1 = CapturedMedia.photo(Data([0x01]))
        let media2 = CapturedMedia.photo(Data([0x02]))
        #expect(media1 != media2)
    }

    @Test("videos with same URL are equal")
    func videoEquality() {
        let url = URL(fileURLWithPath: "/tmp/video.mp4")
        let media1 = CapturedMedia.video(url)
        let media2 = CapturedMedia.video(url)
        #expect(media1 == media2)
    }

    @Test("videos with different URLs are not equal")
    func videoInequality() {
        let media1 = CapturedMedia.video(URL(fileURLWithPath: "/tmp/video1.mp4"))
        let media2 = CapturedMedia.video(URL(fileURLWithPath: "/tmp/video2.mp4"))
        #expect(media1 != media2)
    }

    @Test("audio with same URL and duration are equal")
    func audioEquality() {
        let url = URL(fileURLWithPath: "/tmp/audio.m4a")
        let media1 = CapturedMedia.audio(url, duration: 15.0)
        let media2 = CapturedMedia.audio(url, duration: 15.0)
        #expect(media1 == media2)
    }

    @Test("audio with different durations are not equal")
    func audioDurationInequality() {
        let url = URL(fileURLWithPath: "/tmp/audio.m4a")
        let media1 = CapturedMedia.audio(url, duration: 15.0)
        let media2 = CapturedMedia.audio(url, duration: 30.0)
        #expect(media1 != media2)
    }

    @Test("different media types are not equal")
    func crossTypeInequality() {
        let photoMedia = CapturedMedia.photo(Data())
        let videoMedia = CapturedMedia.video(URL(fileURLWithPath: "/tmp/v.mp4"))
        let audioMedia = CapturedMedia.audio(URL(fileURLWithPath: "/tmp/a.m4a"), duration: 10)

        #expect(photoMedia != videoMedia)
        #expect(videoMedia != audioMedia)
        #expect(audioMedia != photoMedia)
    }
}

// MARK: - CapturedMediaDestination Tests

struct CapturedMediaDestinationTests {

    @Test("enterEpoch destinations with same epochId are equal")
    func enterEpochEquality() {
        let dest1 = CapturedMediaDestination.enterEpoch(epochId: 123)
        let dest2 = CapturedMediaDestination.enterEpoch(epochId: 123)
        #expect(dest1 == dest2)
    }

    @Test("enterEpoch destinations with different epochIds are not equal")
    func enterEpochInequality() {
        let dest1 = CapturedMediaDestination.enterEpoch(epochId: 123)
        let dest2 = CapturedMediaDestination.enterEpoch(epochId: 456)
        #expect(dest1 != dest2)
    }

    @Test("ephemeralMessage destinations with same epochId are equal")
    func ephemeralMessageEquality() {
        let dest1 = CapturedMediaDestination.ephemeralMessage(epochId: 789)
        let dest2 = CapturedMediaDestination.ephemeralMessage(epochId: 789)
        #expect(dest1 == dest2)
    }

    @Test("createEpoch destinations are equal")
    func createEpochEquality() {
        let dest1 = CapturedMediaDestination.createEpoch
        let dest2 = CapturedMediaDestination.createEpoch
        #expect(dest1 == dest2)
    }

    @Test("different destination types are not equal")
    func crossTypeDestinationInequality() {
        let enter = CapturedMediaDestination.enterEpoch(epochId: 123)
        let ephemeral = CapturedMediaDestination.ephemeralMessage(epochId: 123)
        let create = CapturedMediaDestination.createEpoch

        #expect(enter != ephemeral)
        #expect(ephemeral != create)
        #expect(create != enter)
    }
}

// MARK: - CaptureSettings Tests

struct CaptureSettingsTests {

    @Test("default settings have expected values")
    func defaultSettings() {
        let settings = CaptureSettings()
        #expect(settings.flashEnabled == false)
        #expect(settings.useFrontCamera == false)
        #expect(settings.maxDuration == 15)
        #expect(settings.videoQuality == .medium)
        #expect(settings.audioQuality == .high)
    }

    @Test("settings can be customized")
    func customSettings() {
        var settings = CaptureSettings()
        settings.flashEnabled = true
        settings.useFrontCamera = true
        settings.maxDuration = 30
        settings.videoQuality = .high
        settings.audioQuality = .low

        #expect(settings.flashEnabled == true)
        #expect(settings.useFrontCamera == true)
        #expect(settings.maxDuration == 30)
        #expect(settings.videoQuality == .high)
        #expect(settings.audioQuality == .low)
    }

    @Test("settings are equatable")
    func settingsEquality() {
        let settings1 = CaptureSettings()
        let settings2 = CaptureSettings()
        #expect(settings1 == settings2)

        var settings3 = CaptureSettings()
        settings3.flashEnabled = true
        #expect(settings1 != settings3)
    }
}

// MARK: - VideoQuality Tests

struct VideoQualityTests {

    @Test("all video quality cases exist")
    func allCases() {
        let cases = VideoQuality.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.low))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.high))
    }

    @Test("displayName returns capitalized raw value")
    func displayNames() {
        #expect(VideoQuality.low.displayName == "Low")
        #expect(VideoQuality.medium.displayName == "Medium")
        #expect(VideoQuality.high.displayName == "High")
    }
}

// MARK: - AudioQuality Tests

struct AudioQualityTests {

    @Test("all audio quality cases exist")
    func allCases() {
        let cases = AudioQuality.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.low))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.high))
    }

    @Test("displayName returns capitalized raw value")
    func displayNames() {
        #expect(AudioQuality.low.displayName == "Low")
        #expect(AudioQuality.medium.displayName == "Medium")
        #expect(AudioQuality.high.displayName == "High")
    }

    @Test("sampleRate returns correct values")
    func sampleRates() {
        #expect(AudioQuality.low.sampleRate == 22050)
        #expect(AudioQuality.medium.sampleRate == 44100)
        #expect(AudioQuality.high.sampleRate == 48000)
    }

    @Test("higher quality has higher sample rate")
    func sampleRateOrdering() {
        #expect(AudioQuality.low.sampleRate < AudioQuality.medium.sampleRate)
        #expect(AudioQuality.medium.sampleRate < AudioQuality.high.sampleRate)
    }
}
