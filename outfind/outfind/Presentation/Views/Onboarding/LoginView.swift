import SwiftUI

// MARK: - Login View

/// Login view with animated intro text that fades into the connect wallet UI
struct LoginView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var introPhase: IntroPhase = .typing
    @State private var isConnecting = false
    @State private var connectionError: String?
    @State private var showError = false

    // Intro text animation states
    @State private var typedText = ""
    @State private var currentLineIndex = 0
    @State private var showCursor = true
    @State private var introOpacity: Double = 1.0

    private let introLines = [
        "presence is proof.",
        "time is the boundary.",
        "privacy is the default.",
        "welcome to outfind."
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                LoginBackground()

                // Content
                VStack {
                    Spacer()

                    if introPhase == .typing || introPhase == .fadingOut {
                        // Intro animation
                        introTextView
                            .opacity(introOpacity)
                    } else {
                        // Login UI
                        loginContentView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }

                    Spacer()
                }
            }
        }
        .onAppear {
            startIntroAnimation()
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectionError ?? "Failed to connect wallet")
        }
    }

    // MARK: - Intro Text View

    private var introTextView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // App icon
            ZStack {
                LiquidGlassOrb(size: 100, color: Theme.Colors.primaryFallback)
                IconView(.locationCircle, size: .xxl, color: Theme.Colors.primaryFallback)
            }
            .opacity(introPhase == .typing ? 1 : 0)
            .scaleEffect(introPhase == .typing ? 1 : 0.8)
            .animation(Theme.Animation.smooth, value: introPhase)

            // Typewriter text
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(0..<introLines.count, id: \.self) { index in
                    HStack(spacing: 0) {
                        if index < currentLineIndex {
                            // Completed line
                            Text(introLines[index])
                                .font(Typography.headlineMedium)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        } else if index == currentLineIndex {
                            // Currently typing line
                            Text(typedText)
                                .font(Typography.headlineMedium)
                                .foregroundStyle(index == introLines.count - 1
                                    ? Theme.Colors.primaryFallback
                                    : Theme.Colors.textPrimary)

                            // Cursor
                            if showCursor {
                                Rectangle()
                                    .fill(Theme.Colors.primaryFallback)
                                    .frame(width: 2, height: 24)
                                    .padding(.leading, 2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(index <= currentLineIndex ? 1 : 0)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    // MARK: - Login Content View

    private var loginContentView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Logo and title
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    LiquidGlassOrb(size: 120, color: Theme.Colors.primaryFallback)
                    IconView(.locationCircle, size: .xxl, color: Theme.Colors.primaryFallback)
                }

                VStack(spacing: Theme.Spacing.xs) {
                    Text("outfind")
                        .font(Typography.displaySmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Proof of Presence")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()
                .frame(height: Theme.Spacing.xxl)

            // Feature highlights
            VStack(spacing: Theme.Spacing.md) {
                FeatureRow(
                    icon: .shield,
                    title: "Privacy First",
                    subtitle: "Your data vanishes when epochs end"
                )

                FeatureRow(
                    icon: .epoch,
                    title: "Time-Bound",
                    subtitle: "Communities exist only in the moment"
                )

                FeatureRow(
                    icon: .chain,
                    title: "On-Chain Proof",
                    subtitle: "Cryptographic presence verification"
                )
            }
            .padding(.horizontal, Theme.Spacing.md)

            Spacer()

            // Connect button
            VStack(spacing: Theme.Spacing.md) {
                PrimaryButton(
                    "Connect Wallet",
                    icon: .wallet,
                    isLoading: isConnecting
                ) {
                    connectWallet()
                }

                HStack(spacing: Theme.Spacing.xs) {
                    IconView(.globe, size: .sm, color: Theme.Colors.textTertiary)
                    Text("Sepolia Testnet")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    // MARK: - Animation Logic

    private func startIntroAnimation() {
        // Start cursor blinking
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if introPhase != .typing {
                timer.invalidate()
                return
            }
            showCursor.toggle()
        }

        // Start typing animation
        typeNextLine()
    }

    private func typeNextLine() {
        guard currentLineIndex < introLines.count else {
            // All lines typed, start fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                fadeOutIntro()
            }
            return
        }

        let line = introLines[currentLineIndex]
        typedText = ""

        // Type each character
        for (index, char) in line.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                if introPhase == .typing {
                    typedText += String(char)
                }
            }
        }

        // Move to next line after typing completes
        let lineDelay = Double(line.count) * 0.05 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + lineDelay) {
            if introPhase == .typing {
                currentLineIndex += 1
                typedText = ""
                typeNextLine()
            }
        }
    }

    private func fadeOutIntro() {
        introPhase = .fadingOut

        withAnimation(.easeInOut(duration: 0.8)) {
            introOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(Theme.Animation.smooth) {
                introPhase = .complete
            }
        }
    }

    private func connectWallet() {
        isConnecting = true
        connectionError = nil

        Task {
            do {
                _ = try await dependencies.walletRepository.connect()
                await MainActor.run {
                    isConnecting = false
                    coordinator.completeOnboarding()
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    connectionError = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Intro Phase

private enum IntroPhase {
    case typing
    case fadingOut
    case complete
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: AppIcon
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 48, height: 48)

                IconView(icon, size: .lg, color: Theme.Colors.primaryFallback)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
    }
}

// MARK: - Login Background

private struct LoginBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    // Floating orbs with subtle movement
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(orbColor(for: index).opacity(0.1))
                            .blur(radius: 60 + CGFloat(index * 10))
                            .frame(width: orbSize(for: index), height: orbSize(for: index))
                            .offset(orbOffset(for: index, in: geometry.size))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }

    private func orbColor(for index: Int) -> Color {
        let colors: [Color] = [
            Theme.Colors.primaryFallback,
            Theme.Colors.epochActive,
            Theme.Colors.epochFinalized,
            Theme.Colors.primaryVariantFallback,
            Theme.Colors.epochScheduled
        ]
        return colors[index % colors.count]
    }

    private func orbSize(for index: Int) -> CGFloat {
        [200, 300, 180, 250, 220][index % 5]
    }

    private func orbOffset(for index: Int, in size: CGSize) -> CGSize {
        let baseOffsets: [(CGFloat, CGFloat)] = [
            (-50, -100),
            (size.width - 100, size.height - 200),
            (size.width / 2, size.height / 3),
            (-100, size.height - 300),
            (size.width - 50, 100)
        ]
        let base = baseOffsets[index % 5]
        let animOffset = CGFloat(index + 1) * 0.3

        return CGSize(
            width: base.0 + sin(phase * animOffset) * 30,
            height: base.1 + cos(phase * animOffset) * 25
        )
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
