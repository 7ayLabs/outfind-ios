import SwiftUI

// MARK: - Login View

/// Minimal Instagram-style login view
struct LoginView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var isConnecting = false
    @State private var isGoogleSigningIn = false
    @State private var connectionError: String?
    @State private var showError = false

    var body: some View {
        ZStack {
            // Blur background
            Theme.Colors.background
                .ignoresSafeArea()

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
                Text("outfind.me")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                // Auth buttons
                VStack(spacing: Theme.Spacing.md) {
                    // Primary: Connect Wallet
                    Button {
                        connectWallet()
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.8)
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
                    .disabled(isConnecting)

                    // Secondary: Google Sign In
                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            if isGoogleSigningIn {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            }
                            Text("Continue with Google")
                                .font(Typography.titleSmall)
                        }
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                    .disabled(isGoogleSigningIn)
                    .padding(.top, Theme.Spacing.xs)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()
                    .frame(height: Theme.Spacing.xxxl)

                // Bottom bar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: Theme.Spacing.xxs) {
                        Text("Network:")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("Sepolia Testnet")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.vertical, Theme.Spacing.md)
                }
            }
        }
        .alert("Connection Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(connectionError ?? "Failed to connect wallet")
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

        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                isGoogleSigningIn = false
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
