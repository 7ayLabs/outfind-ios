import SwiftUI

// MARK: - Login View

/// Compact login view with wallet and Google sign-in options
struct LoginView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var isConnecting = false
    @State private var isGoogleSigningIn = false
    @State private var connectionError: String?
    @State private var showError = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LoginBackground()

                // Content
                VStack(spacing: 0) {
                    // Header with back button
                    headerView
                        .padding(.top, Theme.Spacing.sm)

                    Spacer()
                        .frame(height: geometry.size.height * 0.08)

                    // Logo section
                    logoSection

                    Spacer()
                        .frame(minHeight: Theme.Spacing.lg)

                    // Feature highlights
                    featureSection
                        .padding(.horizontal, Theme.Spacing.md)

                    Spacer()
                        .frame(minHeight: Theme.Spacing.lg)

                    // Auth buttons
                    authButtonsSection
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectionError ?? "Failed to connect wallet")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button {
                coordinator.handleWalletDisconnected()
            } label: {
                HStack(spacing: Theme.Spacing.xxs) {
                    IconView(.back, size: .sm, color: Theme.Colors.textSecondary)
                    Text("Back")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                LiquidGlassOrb(size: 80, color: Theme.Colors.primaryFallback)
                IconView(.locationCircle, size: .xl, color: Theme.Colors.primaryFallback)
            }

            VStack(spacing: Theme.Spacing.xxs) {
                Text("outfind")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Proof of Presence")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Feature Section

    private var featureSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            CompactFeatureRow(
                icon: .shield,
                title: "Privacy First",
                subtitle: "Data vanishes when epochs end"
            )

            CompactFeatureRow(
                icon: .epoch,
                title: "Time-Bound",
                subtitle: "Communities exist in the moment"
            )

            CompactFeatureRow(
                icon: .chain,
                title: "On-Chain Proof",
                subtitle: "Cryptographic verification"
            )
        }
    }

    // MARK: - Auth Buttons Section

    private var authButtonsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Primary: Connect Wallet
            PrimaryButton(
                "Connect Wallet",
                icon: .wallet,
                isLoading: isConnecting
            ) {
                connectWallet()
            }

            // Secondary: Google Sign In
            GoogleSignInButton(isLoading: isGoogleSigningIn) {
                signInWithGoogle()
            }

            // Network badge
            HStack(spacing: Theme.Spacing.xxs) {
                IconView(.globe, size: .xs, color: Theme.Colors.textTertiary)
                Text("Sepolia Testnet")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    // MARK: - Actions

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

    private func signInWithGoogle() {
        isGoogleSigningIn = true

        // TODO: Implement Google Sign-In
        // For now, simulate connection
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                isGoogleSigningIn = false
                // coordinator.completeOnboarding()
            }
        }
    }
}

// MARK: - Compact Feature Row

private struct CompactFeatureRow: View {
    let icon: AppIcon
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.12))
                    .frame(width: 36, height: 36)

                IconView(icon, size: .sm, color: Theme.Colors.primaryFallback)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
    }
}

// MARK: - Google Sign In Button

private struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else {
                    // Google "G" logo
                    Text("G")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "4285F4"),
                                    Color(hex: "EA4335"),
                                    Color(hex: "FBBC05"),
                                    Color(hex: "34A853")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Continue with Google")
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                Capsule()
                    .strokeBorder(Theme.Colors.glassBorder, lineWidth: 1)
            }
        }
        .disabled(isLoading)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(orbColor(for: index).opacity(0.08))
                            .blur(radius: 50 + CGFloat(index * 10))
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
            Theme.Colors.primaryVariantFallback
        ]
        return colors[index % colors.count]
    }

    private func orbSize(for index: Int) -> CGFloat {
        [160, 200, 140, 180][index % 4]
    }

    private func orbOffset(for index: Int, in size: CGSize) -> CGSize {
        let baseOffsets: [(CGFloat, CGFloat)] = [
            (size.width * 0.1, size.height * 0.2),
            (size.width * 0.8, size.height * 0.7),
            (size.width * 0.5, size.height * 0.4),
            (size.width * 0.2, size.height * 0.8)
        ]
        let base = baseOffsets[index % 4]
        let animOffset = CGFloat(index + 1) * 0.3

        return CGSize(
            width: base.0 + sin(phase * animOffset) * 25,
            height: base.1 + cos(phase * animOffset) * 20
        )
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
