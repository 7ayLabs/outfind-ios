import SwiftUI

// MARK: - Animated Emoji Button

/// A single animated emoji button that morphs between states.
/// The icon itself animates with bounce, wiggle, and scale effects.
struct AnimatedEmojiButton: View {
    let hasReacted: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isAnimating = false
    @State private var wobble: Double = 0
    @State private var bounce: CGFloat = 1.0
    @State private var rotation: Double = 0

    private let emojis = ["😊", "🔥", "❤️", "😂", "🙌", "✨"]
    @State private var currentEmojiIndex = 0

    var body: some View {
        Button {
            triggerReaction()
        } label: {
            ZStack {
                // Ambient glow when active
                if hasReacted {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.orange.opacity(0.4),
                                    Color.orange.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                }

                // Main emoji
                Text(hasReacted ? emojis[currentEmojiIndex] : "☺️")
                    .font(.system(size: 24))
                    .scaleEffect(bounce)
                    .rotationEffect(.degrees(wobble))
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    onLongPress()
                }
        )
        .onAppear {
            if hasReacted {
                startIdleAnimation()
            }
        }
        .onChange(of: hasReacted) { _, newValue in
            if newValue {
                startIdleAnimation()
            }
        }
    }

    private func triggerReaction() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Bounce animation
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            bounce = 1.4
        }

        // Spin effect
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            rotation += 360
        }

        // Wobble
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            wobble = 15
        }

        // Reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bounce = 1.0
                wobble = 0
            }
        }

        // Cycle emoji if already reacted
        if hasReacted {
            currentEmojiIndex = (currentEmojiIndex + 1) % emojis.count
        }

        onTap()
    }

    private func startIdleAnimation() {
        // Subtle breathing animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// MARK: - Emoji Picker Overlay

/// Full-screen emoji picker that appears on long press
struct EmojiPickerOverlay: View {
    @Binding var isPresented: Bool
    let onSelect: (String) -> Void

    @State private var appeared = false

    private let emojis = ["❤️", "🔥", "😂", "😮", "😢", "🙌", "✨", "🎉", "💯", "👏"]

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(appeared ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Emoji grid
            VStack(spacing: 16) {
                // Row 1
                HStack(spacing: 20) {
                    ForEach(emojis.prefix(5), id: \.self) { emoji in
                        emojiButton(emoji)
                    }
                }

                // Row 2
                HStack(spacing: 20) {
                    ForEach(emojis.suffix(5), id: \.self) { emoji in
                        emojiButton(emoji)
                    }
                }
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private func emojiButton(_ emoji: String) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onSelect(emoji)
            dismiss()
        } label: {
            Text(emoji)
                .font(.system(size: 36))
        }
        .buttonStyle(EmojiTapStyle())
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
        }
    }
}

// MARK: - Emoji Tap Style

struct EmojiTapStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.5 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Time Branch Button (Simplified)

/// Simple button for viewing time branches
struct TimeBranchButton: View {
    let branchCount: Int
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 16, weight: .medium))
                    .scaleEffect(pulse ? 1.1 : 1.0)

                if branchCount > 0 {
                    Text("\(branchCount)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
            .foregroundStyle(branchCount > 0 ? Theme.Colors.primaryFallback : Theme.Colors.textTertiary)
        }
        .buttonStyle(.plain)
        .onAppear {
            if branchCount > 0 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("Emoji Button") {
    VStack(spacing: 40) {
        AnimatedEmojiButton(
            hasReacted: false,
            onTap: { print("Tapped") },
            onLongPress: { print("Long pressed") }
        )

        AnimatedEmojiButton(
            hasReacted: true,
            onTap: { print("Tapped") },
            onLongPress: { print("Long pressed") }
        )

        TimeBranchButton(branchCount: 5, onTap: {})

        TimeBranchButton(branchCount: 0, onTap: {})
    }
    .padding()
    .background(Theme.Colors.background)
}

#Preview("Emoji Picker") {
    ZStack {
        Theme.Colors.background.ignoresSafeArea()

        EmojiPickerOverlay(
            isPresented: .constant(true),
            onSelect: { emoji in print("Selected: \(emoji)") }
        )
    }
}
