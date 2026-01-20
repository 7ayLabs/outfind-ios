import SwiftUI
import AVFoundation

// MARK: - Camera Capture View

/// Full-screen camera UI for capturing photos and videos
/// Adaptive for dark/light mode with intuitive gestures
struct CameraCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var cameraManager = CameraManager()
    @State private var captureMode: CaptureMode = .photo
    @State private var isCapturing = false
    @State private var showFlash = false

    let captureType: CaptureType
    let onCapture: (CapturedMedia) -> Void
    let onCancel: () -> Void

    // MARK: - Adaptive Colors

    private var controlBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.black.opacity(0.4)
    }

    private var controlForeground: Color {
        .white
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Camera preview
            cameraPreview
                .ignoresSafeArea()

            // Controls overlay
            VStack {
                // Top controls
                topControls
                    .padding(.top, 60)
                    .padding(.horizontal, Theme.Spacing.md)

                Spacer()

                // Mode selector (photo/video)
                if captureType != .selfie {
                    modeSelector
                        .padding(.bottom, Theme.Spacing.lg)
                }

                // Capture button
                captureButton
                    .padding(.bottom, Theme.Spacing.xxl)
            }

            // Recording indicator
            if cameraManager.isRecording {
                recordingIndicator
            }
        }
        .task {
            await setupCamera()
        }
        .onDisappear {
            cameraManager.cleanup()
        }
        .gesture(
            DragGesture(minimumDistance: 100)
                .onEnded { value in
                    if value.translation.height > 100 {
                        onCancel()
                    }
                }
        )
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    Task {
                        try? await cameraManager.switchCamera()
                        RadialHaptics.shared.selectionMade()
                    }
                }
        )
    }

    // MARK: - Camera Preview

    private var cameraPreview: some View {
        ZStack {
            Color.black

            if cameraManager.isSessionRunning {
                CameraPreviewView(captureSession: cameraManager.captureSession)
            } else if !cameraManager.isCameraAuthorized {
                notAuthorizedView
            } else {
                ProgressView()
                    .tint(.white)
            }

            // Flash overlay
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Top Controls

    private var topControls: some View {
        HStack {
            // Close button
            Button {
                RadialHaptics.shared.dismiss()
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(controlForeground)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(controlBackground))
            }

            Spacer()

            // Flash toggle
            Button {
                cameraManager.toggleFlash()
                RadialHaptics.shared.selectionMade()
            } label: {
                Image(systemName: cameraManager.flashMode == .on ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(cameraManager.flashMode == .on ? .yellow : controlForeground)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(controlBackground))
            }

            // Camera flip
            Button {
                Task {
                    try? await cameraManager.switchCamera()
                    RadialHaptics.shared.selectionMade()
                }
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(controlForeground)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(controlBackground))
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: Theme.Spacing.lg) {
            ForEach(CaptureMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        captureMode = mode
                    }
                    RadialHaptics.shared.selectionMade()
                } label: {
                    Text(mode.displayName)
                        .font(.system(size: 14, weight: captureMode == mode ? .bold : .medium))
                        .foregroundStyle(captureMode == mode ? .white : .white.opacity(0.6))
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background {
                            if captureMode == mode {
                                Capsule()
                                    .fill(controlBackground)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Capture Button

    private var captureButton: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(.white, lineWidth: 4)
                .frame(width: 80, height: 80)

            // Inner button
            Circle()
                .fill(captureMode == .video && cameraManager.isRecording ? Color.red : .white)
                .frame(width: 64, height: 64)
                .scaleEffect(isCapturing ? 0.9 : 1.0)

            // Recording progress
            if cameraManager.isRecording {
                Circle()
                    .trim(from: 0, to: cameraManager.recordingDuration / 15)
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: cameraManager.recordingDuration)
            }
        }
        .gesture(
            captureMode == .photo
                ? nil
                : LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in
                        startVideoRecording()
                    }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    if captureMode == .photo {
                        capturePhoto()
                    } else if cameraManager.isRecording {
                        stopVideoRecording()
                    } else {
                        startVideoRecording()
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isCapturing)
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        VStack {
            HStack(spacing: Theme.Spacing.xs) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)

                Text(formatDuration(cameraManager.recordingDuration))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Capsule().fill(Color.black.opacity(0.6)))
            .padding(.top, 120)

            Spacer()
        }
    }

    // MARK: - Not Authorized View

    private var notAuthorizedView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))

            Text("Camera Access Required")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Text("Enable camera access in Settings to capture photos and videos")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Capsule().fill(.white))
            }
        }
    }

    // MARK: - Setup

    private func setupCamera() async {
        // Set front camera for selfie mode
        if captureType == .selfie {
            cameraManager.currentCameraPosition = .front
        }

        do {
            try await cameraManager.setupSession()
            cameraManager.startSession()
        } catch {
            // Handle error
        }
    }

    // MARK: - Capture Actions

    private func capturePhoto() {
        isCapturing = true
        RadialHaptics.shared.selectionMade()

        Task {
            do {
                // Show flash effect
                withAnimation(.easeOut(duration: 0.1)) {
                    showFlash = true
                }

                let data = try await cameraManager.capturePhoto()

                withAnimation(.easeIn(duration: 0.1)) {
                    showFlash = false
                }

                RadialHaptics.shared.success()
                onCapture(.photo(data))
            } catch {
                RadialHaptics.shared.error()
            }

            isCapturing = false
        }
    }

    private func startVideoRecording() {
        guard !cameraManager.isRecording else { return }

        RadialHaptics.shared.selectionMade()

        Task {
            do {
                let url = try await cameraManager.startRecording(maxDuration: 15)
                RadialHaptics.shared.success()
                onCapture(.video(url))
            } catch {
                RadialHaptics.shared.error()
            }
        }
    }

    private func stopVideoRecording() {
        cameraManager.stopRecording()
        RadialHaptics.shared.selectionMade()
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Capture Mode

private enum CaptureMode: CaseIterable {
    case photo
    case video

    var displayName: String {
        switch self {
        case .photo: return "Photo"
        case .video: return "Video"
        }
    }
}

// MARK: - Preview

#Preview {
    CameraCaptureView(
        captureType: .photo,
        onCapture: { _ in },
        onCancel: {}
    )
}
