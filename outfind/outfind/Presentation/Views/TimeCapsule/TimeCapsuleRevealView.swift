import SwiftUI

// MARK: - Time Capsule Reveal View

/// Dramatic reveal animation for unlocking a time capsule
struct TimeCapsuleRevealView: View {
    let capsule: TimeCapsule
    let onDismiss: () -> Void

    @State private var phase: RevealPhase = .sealed
    @State private var envelopeScale: CGFloat = 1.0
    @State private var envelopeRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var particleOpacity: Double = 0

    enum RevealPhase {
        case sealed, opening, revealed
    }

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()

            // Glow effect
            RadialGradient(
                colors: [
                    Theme.Colors.primaryFallback.opacity(0.3),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .opacity(glowOpacity)
            .ignoresSafeArea()

            // Particles
            particlesView
                .opacity(particleOpacity)

            // Content
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Envelope / Message
                if phase == .revealed {
                    revealedContent
                        .opacity(contentOpacity)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    sealedEnvelope
                }

                Spacer()

                // Action button
                actionButton
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding()
        }
    }

    // MARK: - Sealed Envelope

    private var sealedEnvelope: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                // Envelope
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback,
                                Theme.Colors.primaryFallback.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 140)
                    .overlay {
                        // Seal
                        Circle()
                            .fill(Theme.Colors.warning)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                            }
                            .offset(y: 45)
                    }
                    .shadow(color: Theme.Colors.primaryFallback.opacity(0.3), radius: 20, y: 10)
            }
            .scaleEffect(envelopeScale)
            .rotationEffect(.degrees(envelopeRotation))

            VStack(spacing: Theme.Spacing.xs) {
                Text("Message from the Past")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(formatDate(capsule.createdAt))
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Revealed Content

    private var revealedContent: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.Colors.primaryFallback)

                if let title = capsule.title {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text("Written \(formatDate(capsule.createdAt))")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            // Message content
            ScrollView {
                Text(capsule.content)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .frame(maxHeight: 300)
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Colors.backgroundSecondary)
            }
        }
    }

    // MARK: - Particles

    private var particlesView: some View {
        GeometryReader { geo in
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Theme.Colors.primaryFallback)
                    .frame(width: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                    .blur(radius: 1)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            if phase == .revealed {
                onDismiss()
            } else {
                startRevealAnimation()
            }
        } label: {
            Text(phase == .revealed ? "Close" : "Open Message")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.Colors.primaryGradient)
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Animation

    private func startRevealAnimation() {
        // Phase 1: Shake and glow
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            envelopeRotation = -5
        }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3).delay(0.1)) {
            envelopeRotation = 5
        }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3).delay(0.2)) {
            envelopeRotation = 0
        }
        withAnimation(.easeInOut(duration: 0.5)) {
            glowOpacity = 0.8
        }

        // Phase 2: Scale up and explode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                envelopeScale = 1.3
                particleOpacity = 1
            }
        }

        // Phase 3: Reveal content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                phase = .revealed
                contentOpacity = 1
                particleOpacity = 0
                glowOpacity = 0.3
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    TimeCapsuleRevealView(
        capsule: TimeCapsule.mock(isUnlocked: true),
        onDismiss: {}
    )
}
