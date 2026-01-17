import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var dependencies: DependencyContainer

    @State private var currentPage = 0
    @State private var isConnecting = false
    @State private var connectionError: String?
    @State private var showError = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: .locationCircle,
            title: "Proof of Presence",
            subtitle: "Cryptographically prove you were somewhere, without revealing where.",
            color: Theme.Colors.primaryFallback
        ),
        OnboardingPage(
            icon: .epoch,
            title: "Time-Bound Epochs",
            subtitle: "Join ephemeral communities that exist only for a moment in time.",
            color: Theme.Colors.epochActive
        ),
        OnboardingPage(
            icon: .shield,
            title: "Privacy First",
            subtitle: "Your data disappears when the epoch ends. No traces left behind.",
            color: Theme.Colors.epochFinalized
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated background
                AnimatedBackground()

                VStack(spacing: 0) {
                    // Skip button
                    HStack {
                        Spacer()
                        if currentPage < pages.count - 1 {
                            Button("Skip") {
                                withAnimation(Theme.Animation.smooth) {
                                    currentPage = pages.count - 1
                                }
                            }
                            .font(Typography.labelLarge)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding()
                        }
                    }

                    Spacer()

                    // Page content
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.5)

                    // Page indicator
                    PageIndicator(currentPage: currentPage, pageCount: pages.count)
                        .padding(.vertical, Theme.Spacing.lg)

                    Spacer()

                    // Bottom section
                    VStack(spacing: Theme.Spacing.md) {
                        if currentPage == pages.count - 1 {
                            // Connect wallet button
                            PrimaryButton(
                                "Connect Wallet",
                                icon: .wallet,
                                isLoading: isConnecting
                            ) {
                                connectWallet()
                            }

                            // Network info
                            HStack(spacing: Theme.Spacing.xs) {
                                IconView(.globe, size: .sm, color: Theme.Colors.textTertiary)
                                Text("Sepolia Testnet")
                                    .font(Typography.caption)
                                    .foregroundStyle(Theme.Colors.textTertiary)
                            }
                        } else {
                            // Next button
                            PrimaryButton("Continue") {
                                withAnimation(Theme.Animation.smooth) {
                                    currentPage += 1
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectionError ?? "Failed to connect wallet")
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

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: AppIcon
    let title: String
    let subtitle: String
    let color: Color
}

// MARK: - Onboarding Page View

private struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Animated orb with icon
            ZStack {
                LiquidGlassOrb(size: 120, color: page.color)

                IconView(page.icon, size: .xxl, color: page.color)
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0)

            VStack(spacing: Theme.Spacing.sm) {
                Text(page.title)
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .offset(y: isVisible ? 0 : 20)
            .opacity(isVisible ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(Theme.Animation.smooth.delay(0.1)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - Page Indicator

private struct PageIndicator: View {
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.Colors.primaryFallback : Theme.Colors.textTertiary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(Theme.Animation.smooth, value: currentPage)
            }
        }
    }
}

// MARK: - Animated Background

private struct AnimatedBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            // Gradient orbs
            GeometryReader { geometry in
                ZStack {
                    // Top-left orb
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.15))
                        .blur(radius: 60)
                        .frame(width: 200, height: 200)
                        .offset(
                            x: -50 + sin(phase) * 20,
                            y: -100 + cos(phase) * 15
                        )

                    // Bottom-right orb
                    Circle()
                        .fill(Theme.Colors.epochActive.opacity(0.1))
                        .blur(radius: 80)
                        .frame(width: 300, height: 300)
                        .offset(
                            x: geometry.size.width - 150 + cos(phase) * 25,
                            y: geometry.size.height - 200 + sin(phase) * 20
                        )

                    // Center orb
                    Circle()
                        .fill(Theme.Colors.epochFinalized.opacity(0.08))
                        .blur(radius: 100)
                        .frame(width: 250, height: 250)
                        .offset(
                            x: geometry.size.width / 2 - 125 + sin(phase * 0.7) * 30,
                            y: geometry.size.height / 2 - 125 + cos(phase * 0.7) * 25
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(DependencyContainer.shared)
        .environmentObject(AppCoordinator(dependencies: DependencyContainer.shared))
}
