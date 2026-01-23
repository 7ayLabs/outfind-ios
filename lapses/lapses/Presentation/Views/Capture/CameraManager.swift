import AVFoundation
import UIKit
import SwiftUI

// MARK: - Camera Manager

/// Manages camera capture for photos and videos
/// Uses AVFoundation with async/await interface
@Observable
final class CameraManager: NSObject {
    // MARK: - State

    var isSessionRunning = false
    var isCameraAuthorized = false
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var flashMode: AVCaptureDevice.FlashMode = .off
    var currentCameraPosition: AVCaptureDevice.Position = .back

    // MARK: - Error State

    var error: CameraError?

    // MARK: - Session

    let captureSession = AVCaptureSession()

    // MARK: - Private Properties
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var photoContinuation: CheckedContinuation<Data, Error>?
    private var videoContinuation: CheckedContinuation<URL, Error>?

    private var recordingTimer: Timer?
    private var maxRecordingDuration: TimeInterval = 15

    // MARK: - Session Queue

    private let captureSessionQueue = DispatchQueue(label: "camera.captureSession.queue")

    // MARK: - Preview Layer

    var previewLayer: AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // MARK: - Authorization

    func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                isCameraAuthorized = granted
            }
            return granted

        case .denied, .restricted:
            await MainActor.run {
                isCameraAuthorized = false
                error = .notAuthorized
            }
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Session Setup

    func setupSession() async throws {
        guard await checkAuthorization() else {
            throw CameraError.notAuthorized
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            captureSessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.captureSessionSetupFailed)
                    return
                }

                do {
                    self.captureSession.beginConfiguration()
                    self.captureSession.sessionPreset = .high

                    // Add video input
                    try self.addVideoInput()

                    // Add audio input for video recording
                    try self.addAudioInput()

                    // Add photo output
                    if self.captureSession.canAddOutput(self.photoOutput) {
                        self.captureSession.addOutput(self.photoOutput)
                        self.photoOutput.isHighResolutionCaptureEnabled = true
                    }

                    // Add movie output
                    if self.captureSession.canAddOutput(self.movieOutput) {
                        self.captureSession.addOutput(self.movieOutput)
                        self.movieOutput.maxRecordedDuration = CMTime(seconds: self.maxRecordingDuration, preferredTimescale: 600)
                    }

                    self.captureSession.commitConfiguration()
                    continuation.resume()
                } catch {
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func addVideoInput() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition) else {
            throw CameraError.cameraUnavailable
        }

        let input = try AVCaptureDeviceInput(device: device)

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            videoDeviceInput = input
        } else {
            throw CameraError.captureSessionSetupFailed
        }
    }

    private func addAudioInput() throws {
        guard let device = AVCaptureDevice.default(for: .audio) else {
            return // Audio not required, continue without
        }

        let input = try AVCaptureDeviceInput(device: device)

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
    }

    // MARK: - Session Control

    func startSession() {
        captureSessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        captureSessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }

    // MARK: - Camera Switching

    func switchCamera() async throws {
        let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            captureSessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.captureSessionSetupFailed)
                    return
                }

                self.captureSession.beginConfiguration()

                // Remove current input
                if let currentInput = self.videoDeviceInput {
                    self.captureSession.removeInput(currentInput)
                }

                // Add new input
                guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.cameraUnavailable)
                    return
                }

                do {
                    let newInput = try AVCaptureDeviceInput(device: newDevice)
                    if self.captureSession.canAddInput(newInput) {
                        self.captureSession.addInput(newInput)
                        self.videoDeviceInput = newInput
                        DispatchQueue.main.async {
                            self.currentCameraPosition = newPosition
                        }
                    }
                    self.captureSession.commitConfiguration()
                    continuation.resume()
                } catch {
                    self.captureSession.commitConfiguration()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Flash Control

    func toggleFlash() {
        flashMode = flashMode == .off ? .on : .off
    }

    // MARK: - Photo Capture

    func capturePhoto() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()

            // Configure flash
            if photoOutput.supportedFlashModes.contains(flashMode) {
                settings.flashMode = flashMode
            }

            // High quality
            settings.isHighResolutionPhotoEnabled = true

            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Video Recording

    func startRecording(maxDuration: TimeInterval = 15) async throws -> URL {
        guard !isRecording else {
            throw CameraError.alreadyRecording
        }

        maxRecordingDuration = maxDuration
        movieOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        return try await withCheckedThrowingContinuation { continuation in
            self.videoContinuation = continuation

            captureSessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CameraError.captureSessionSetupFailed)
                    return
                }

                // Configure flash for video (torch)
                if let device = self.videoDeviceInput?.device,
                   device.hasTorch {
                    try? device.lockForConfiguration()
                    device.torchMode = self.flashMode == .on ? .on : .off
                    device.unlockForConfiguration()
                }

                self.movieOutput.startRecording(to: tempURL, recordingDelegate: self)

                DispatchQueue.main.async {
                    self.isRecording = true
                    self.recordingDuration = 0
                    self.startRecordingTimer()
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        captureSessionQueue.async { [weak self] in
            self?.movieOutput.stopRecording()
        }
    }

    private func startRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.recordingDuration += 0.1

            if self.recordingDuration >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Cleanup

    func cleanup() {
        stopSession()
        stopRecordingTimer()
        photoContinuation = nil
        videoContinuation = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            photoContinuation?.resume(throwing: CameraError.captureProcessingFailed)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: data)
        photoContinuation = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopRecordingTimer()

            // Turn off torch
            if let device = self?.videoDeviceInput?.device,
               device.hasTorch {
                try? device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            }
        }

        if let error {
            // Check if it's just hitting max duration (not an error)
            let nsError = error as NSError
            if nsError.domain == AVFoundationErrorDomain &&
               nsError.code == AVError.maximumDurationReached.rawValue {
                videoContinuation?.resume(returning: outputFileURL)
            } else {
                videoContinuation?.resume(throwing: error)
            }
        } else {
            videoContinuation?.resume(returning: outputFileURL)
        }

        videoContinuation = nil
    }
}

// MARK: - Camera Error

enum CameraError: LocalizedError {
    case notAuthorized
    case cameraUnavailable
    case captureSessionSetupFailed
    case captureProcessingFailed
    case alreadyRecording

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized"
        case .cameraUnavailable:
            return "Camera is unavailable"
        case .captureSessionSetupFailed:
            return "Failed to setup camera captureSession"
        case .captureProcessingFailed:
            return "Failed to process capture"
        case .alreadyRecording:
            return "Already recording"
        }
    }
}

// MARK: - Camera Preview View

/// SwiftUI wrapper for AVCaptureVideoPreviewLayer
struct CameraPreviewView: UIViewRepresentable {
    let captureSession: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.captureSession = captureSession
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.captureSession = captureSession
    }
}

class CameraPreviewUIView: UIView {
    var captureSession: AVCaptureSession? {
        didSet {
            (layer as? AVCaptureVideoPreviewLayer)?.session = captureSession
        }
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        (layer as? AVCaptureVideoPreviewLayer)?.videoGravity = .resizeAspectFill
    }
}
