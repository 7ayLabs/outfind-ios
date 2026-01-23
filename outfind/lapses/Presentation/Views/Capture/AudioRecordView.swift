import SwiftUI

// MARK: - Audio Record View

/// Audio recording UI with waveform visualization
/// Presented as a sheet with adaptive dark/light styling
struct AudioRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var audioRecorder = AudioRecorder()
    @State private var isPulsing = false

    let maxDuration: TimeInterval
    let onCapture: (CapturedMedia) -> Void
    let onCancel: () -> Void

    init(
        maxDuration: TimeInterval = 60,
        onCapture: @escaping (CapturedMedia) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.maxDuration = maxDuration
        self.onCapture = onCapture
        self.onCancel = onCancel
    }

    // MARK: - Adaptive Colors

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(hex: "1C1C1E")
            : Color.white
    }

    private var waveformColor: Color {
        colorScheme == .dark
            ? Theme.Colors.warning
            : Theme.Colors.warning.opacity(0.8)
    }

    private var textPrimary: Color {
        colorScheme == .dark ? .white : Theme.Colors.textPrimary
    }

    private var textSecondary: Color {
        colorScheme == .dark
            ? .white.opacity(0.6)
            : Theme.Colors.textSecondary
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Header
            header

            Spacer()

            // Waveform visualization
            waveformView
                .frame(height: 100)
                .padding(.horizontal, Theme.Spacing.lg)

            // Timer
            timerView

            Spacer()

            // Record button
            recordButton

            // Cancel button
            cancelButton
                .padding(.bottom, Theme.Spacing.lg)
        }
        .padding(.top, Theme.Spacing.lg)
        .background(backgroundColor.ignoresSafeArea())
        .onDisappear {
            audioRecorder.cleanup()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "waveform")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(waveformColor)

            Text("Audio Recording")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(textPrimary)

            Text("Tap to start recording")
                .font(.system(size: 14))
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Waveform View

    private var waveformView: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<50, id: \.self) { index in
                    let level = index < audioRecorder.audioLevels.count
                        ? audioRecorder.audioLevels[index]
                        : 0.1

                    RoundedRectangle(cornerRadius: 2)
                        .fill(waveformColor.opacity(audioRecorder.isRecording ? 1 : 0.3))
                        .frame(width: 4, height: barHeight(for: level, maxHeight: geometry.size.height))
                        .animation(.easeOut(duration: 0.05), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barHeight(for level: Float, maxHeight: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 4
        let scaledLevel = CGFloat(level) * maxHeight * 0.9
        return max(minHeight, scaledLevel)
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(formatTime(audioRecorder.currentTime))
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(textPrimary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(waveformColor)
                        .frame(
                            width: geometry.size.width * CGFloat(audioRecorder.currentTime / maxDuration),
                            height: 4
                        )
                        .animation(.linear(duration: 0.1), value: audioRecorder.currentTime)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, Theme.Spacing.xxl)

            Text("Max \(Int(maxDuration))s")
                .font(.system(size: 12))
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            if audioRecorder.isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(
                        audioRecorder.isRecording ? Color.red : waveformColor,
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)

                // Inner button
                Circle()
                    .fill(audioRecorder.isRecording ? Color.red : waveformColor)
                    .frame(width: 64, height: 64)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)

                // Stop icon when recording
                if audioRecorder.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onChange(of: audioRecorder.isRecording) { _, isRecording in
            if isRecording {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }

    // MARK: - Cancel Button

    private var cancelButton: some View {
        Button {
            RadialHaptics.shared.dismiss()
            if audioRecorder.isRecording {
                audioRecorder.cancelRecording()
            }
            onCancel()
        } label: {
            Text("Cancel")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(textSecondary)
        }
    }

    // MARK: - Actions

    private func startRecording() {
        RadialHaptics.shared.selectionMade()

        Task {
            do {
                let url = try await audioRecorder.startRecording(maxDuration: maxDuration)
                let duration = audioRecorder.currentTime
                RadialHaptics.shared.success()
                onCapture(.audio(url, duration: duration))
            } catch {
                if case AudioRecorderError.cancelled = error {
                    // User cancelled, don't show error
                } else {
                    RadialHaptics.shared.error()
                }
            }
        }
    }

    private func stopRecording() {
        RadialHaptics.shared.selectionMade()
        audioRecorder.stopRecording()
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    AudioRecordView(
        maxDuration: 30,
        onCapture: { _ in },
        onCancel: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AudioRecordView(
        maxDuration: 30,
        onCapture: { _ in },
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
