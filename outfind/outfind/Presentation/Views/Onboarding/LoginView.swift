import SwiftUI

// MARK: - Login View

/// Minimal Instagram-style login view with wallet and Google authentication
struct LoginView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var isConnecting = false
    @State private var isGoogleSigningIn = false
    @State private var connectionError: String?
    @State private var showError = false
    @State private var showWalletPicker = false
    @State private var authenticatedUser: User?

    var body: some View {
        ZStack {
            // Blur background
            LoginBackground()

            // Content
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button {
                        coordinator.handleWalletDisconnected()
                    } label: {
                        IconView(.back, size: .md, color: Theme.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.top, Theme.Spacing.xs)

                Spacer()

                // Logo / Title
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primaryFallback.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)

                        IconView(.locationCircle, size: .xl, color: Theme.Colors.primaryFallback)
                    }

                    Text("Lapses")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                // Auth buttons
                VStack(spacing: Theme.Spacing.md) {
                    // Primary: Connect Wallet
                    Button {
                        showWalletPicker = true
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                IconView(.wallet, size: .sm, color: .white)
                            }
                            Text("Connect Wallet")
                                .font(Typography.titleSmall)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .fill(Theme.Colors.primaryFallback)
                        }
                    }
                    .disabled(isConnecting || isGoogleSigningIn)

                    // Divider with "or"
                    HStack(spacing: Theme.Spacing.sm) {
                        Rectangle()
                            .fill(Theme.Colors.textTertiary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Rectangle()
                            .fill(Theme.Colors.textTertiary.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Secondary: Google Sign In
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            if isGoogleSigningIn {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(Theme.Colors.textPrimary)
                                    .scaleEffect(0.8)
                            } else {
                                IconView(.google, size: .sm, color: Theme.Colors.textPrimary)
                            }
                            Text("Continue with Google")
                                .font(Typography.titleSmall)
                        }
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                                .stroke(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                        }
                    }
                    .disabled(isConnecting || isGoogleSigningIn)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()
                    .frame(height: Theme.Spacing.xxxl)

                // Bottom bar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: Theme.Spacing.xxs) {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 6, height: 6)
                        Text("Sepolia Testnet")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.vertical, Theme.Spacing.md)
                }
            }
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectionError ?? "Failed to connect")
        }
        .sheet(isPresented: $showWalletPicker) {
            WalletPickerView { user in
                handleAuthentication(user)
            }
        }
    }

    // MARK: - Actions

    private func signInWithGoogle() {
        isGoogleSigningIn = true
        connectionError = nil

        Task {
            do {
                let user = try await dependencies.authenticationRepository.signInWithGoogle()
                await MainActor.run {
                    isGoogleSigningIn = false
                    handleAuthentication(user)
                }
            } catch let error as AuthenticationError {
                await MainActor.run {
                    isGoogleSigningIn = false
                    if case .userCancelled = error {
                        // User cancelled, don't show error
                    } else {
                        connectionError = error.localizedDescription
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isGoogleSigningIn = false
                    connectionError = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func handleAuthentication(_ user: User) {
        authenticatedUser = user
        coordinator.completeOnboarding()
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
                    // Subtle animated orb
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(
                            x: geometry.size.width * 0.3 + sin(phase) * 20,
                            y: geometry.size.height * 0.2 + cos(phase) * 15
                        )
                }
            }
            .ignoresSafeArea()

            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.5))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
