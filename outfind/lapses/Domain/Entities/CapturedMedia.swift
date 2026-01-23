import Foundation

// MARK: - Captured Media

/// Represents media captured through the app's camera or microphone
/// Used for entering epochs with media or sending ephemeral messages
enum CapturedMedia: Sendable, Equatable {
    /// A captured photo as JPEG data
    case photo(Data)

    /// A captured video at a local URL
    case video(URL)

    /// A captured audio recording at a local URL with duration
    case audio(URL, duration: TimeInterval)

    // MARK: - Type Checks

    var isPhoto: Bool {
        if case .photo = self { return true }
        return false
    }

    var isVideo: Bool {
        if case .video = self { return true }
        return false
    }

    var isAudio: Bool {
        if case .audio = self { return true }
        return false
    }

    // MARK: - Accessors

    /// Returns the photo data if this is a photo, nil otherwise
    var photoData: Data? {
        if case .photo(let data) = self { return data }
        return nil
    }

    /// Returns the video URL if this is a video, nil otherwise
    var videoURL: URL? {
        if case .video(let url) = self { return url }
        return nil
    }

    /// Returns the audio URL if this is audio, nil otherwise
    var audioURL: URL? {
        if case .audio(let url, _) = self { return url }
        return nil
    }

    /// Returns the audio duration if this is audio, nil otherwise
    var audioDuration: TimeInterval? {
        if case .audio(_, let duration) = self { return duration }
        return nil
    }

    // MARK: - Display

    /// User-friendly description of the media type
    var typeDescription: String {
        switch self {
        case .photo: return "Photo"
        case .video: return "Video"
        case .audio: return "Audio"
        }
    }

    /// SF Symbol icon for the media type
    var iconName: String {
        switch self {
        case .photo: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "waveform"
        }
    }

    // MARK: - Equatable

    static func == (lhs: CapturedMedia, rhs: CapturedMedia) -> Bool {
        switch (lhs, rhs) {
        case (.photo(let lData), .photo(let rData)):
            return lData == rData
        case (.video(let lURL), .video(let rURL)):
            return lURL == rURL
        case (.audio(let lURL, let lDuration), .audio(let rURL, let rDuration)):
            return lURL == rURL && lDuration == rDuration
        default:
            return false
        }
    }
}

// MARK: - Captured Media Destination

/// Where captured media should be sent
enum CapturedMediaDestination: Equatable {
    /// Enter an epoch with this media attached
    case enterEpoch(epochId: UInt64)

    /// Send as ephemeral message to an epoch
    case ephemeralMessage(epochId: UInt64)

    /// Create a new epoch with this media
    case createEpoch
}

// MARK: - Capture Settings

/// Settings for media capture
struct CaptureSettings: Equatable {
    /// Whether flash is enabled (for camera)
    var flashEnabled: Bool = false

    /// Use front camera (for camera)
    var useFrontCamera: Bool = false

    /// Maximum recording duration (for video/audio)
    var maxDuration: TimeInterval = 15

    /// Video quality
    var videoQuality: VideoQuality = .medium

    /// Audio quality
    var audioQuality: AudioQuality = .high
}

// MARK: - Video Quality

enum VideoQuality: String, CaseIterable {
    case low
    case medium
    case high

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Audio Quality

enum AudioQuality: String, CaseIterable {
    case low
    case medium
    case high

    var displayName: String {
        rawValue.capitalized
    }

    var sampleRate: Double {
        switch self {
        case .low: return 22050
        case .medium: return 44100
        case .high: return 48000
        }
    }
}
