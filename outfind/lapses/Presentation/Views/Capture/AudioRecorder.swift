import AVFoundation
import Foundation

// MARK: - Audio Recorder

/// Manages audio recording with level metering for waveform visualization
@Observable
final class AudioRecorder: NSObject {
    // MARK: - State

    var isRecording = false
    var isAuthorized = false
    var currentTime: TimeInterval = 0
    var audioLevel: Float = 0

    /// Array of recent audio levels for waveform visualization
    var audioLevels: [Float] = []

    // MARK: - Error State

    var error: AudioRecorderError?

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var maxDuration: TimeInterval = 60
    private var outputURL: URL?

    private var recordingContinuation: CheckedContinuation<URL, Error>?

    // MARK: - Settings

    private let maxLevelSamples = 50

    // MARK: - Authorization

    func checkAuthorization() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            isAuthorized = true
            return true

        case .undetermined:
            let granted = await AVAudioApplication.requestRecordPermission()
            await MainActor.run {
                isAuthorized = granted
            }
            return granted

        case .denied:
            await MainActor.run {
                isAuthorized = false
                error = .notAuthorized
            }
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Recording

    func startRecording(maxDuration: TimeInterval = 60) async throws -> URL {
        guard await checkAuthorization() else {
            throw AudioRecorderError.notAuthorized
        }

        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        self.maxDuration = maxDuration

        // Setup audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        // Create output URL
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        outputURL = url

        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        return try await withCheckedThrowingContinuation { continuation in
            recordingContinuation = continuation

            do {
                audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                audioRecorder?.delegate = self
                audioRecorder?.isMeteringEnabled = true
                audioRecorder?.record(forDuration: maxDuration)

                DispatchQueue.main.async {
                    self.isRecording = true
                    self.currentTime = 0
                    self.audioLevels = []
                    self.startLevelTimer()
                }
            } catch {
                continuation.resume(throwing: error)
                recordingContinuation = nil
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        stopLevelTimer()

        DispatchQueue.main.async {
            self.isRecording = false
        }

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func cancelRecording() {
        stopRecording()

        // Delete the file
        if let url = outputURL {
            try? FileManager.default.removeItem(at: url)
        }

        recordingContinuation?.resume(throwing: AudioRecorderError.cancelled)
        recordingContinuation = nil
        outputURL = nil
    }

    // MARK: - Level Metering

    private func startLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateLevels()
        }
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        currentTime = recorder.currentTime

        // Get normalized level (0-1)
        let level = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, level / 20) // Convert dB to linear

        audioLevel = normalizedLevel

        // Add to levels array for waveform
        audioLevels.append(normalizedLevel)
        if audioLevels.count > maxLevelSamples {
            audioLevels.removeFirst()
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stopRecording()
        audioRecorder = nil
        recordingContinuation = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopLevelTimer()
        }

        if flag, let url = outputURL {
            recordingContinuation?.resume(returning: url)
        } else {
            recordingContinuation?.resume(throwing: AudioRecorderError.recordingFailed)
        }
        recordingContinuation = nil
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopLevelTimer()
        }

        recordingContinuation?.resume(throwing: error ?? AudioRecorderError.recordingFailed)
        recordingContinuation = nil
    }
}

// MARK: - Audio Recorder Error

enum AudioRecorderError: LocalizedError {
    case notAuthorized
    case alreadyRecording
    case recordingFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Microphone access not authorized"
        case .alreadyRecording:
            return "Already recording"
        case .recordingFailed:
            return "Recording failed"
        case .cancelled:
            return "Recording cancelled"
        }
    }
}
