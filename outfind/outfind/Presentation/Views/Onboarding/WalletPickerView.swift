import SwiftUI

// MARK: - Wallet Picker View

/// Sheet view for selecting a wallet to connect
struct WalletPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies

    @State private var installedWallets: [WalletAppType] = []
    @State private var isLoading = true
    @State private var connectingWallet: WalletAppType?
    @State private var showQRCode = false
    @State private var qrCodeURI: String?
    @State private var connectionError: String?

    let onConnect: (User) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Connect Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .alert("Connection Error", isPresented: .init(
                get: { connectionError != nil },
                set: { if !$0 { connectionError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(connectionError ?? "")
            }
            .sheet(isPresented: $showQRCode) {
                if let uri = qrCodeURI {
                    QRCodeView(uri: uri) {
                        showQRCode = false
                    }
                }
            }
        }
        .task {
            await loadInstalledWallets()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Theme.Colors.primaryFallback)
            Text("Detecting wallets...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Installed wallets section
                if !installedWallets.isEmpty {
                    installedWalletsSection
                }

                // Other options section
                otherOptionsSection

                // Info text
                infoText
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Installed Wallets Section

    private var installedWalletsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Installed Wallets")
                .font(Typography.labelLarge)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, Theme.Spacing.xxs)

            VStack(spacing: Theme.Spacing.xs) {
                ForEach(installedWallets, id: \.self) { wallet in
                    WalletButton(
                        wallet: wallet,
                        isConnecting: connectingWallet == wallet,
                        action: { connectWallet(wallet) }
                    )
                }
            }
        }
    }

    // MARK: - Other Options Section

    private var otherOptionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Other Options")
                .font(Typography.labelLarge)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, Theme.Spacing.xxs)

            VStack(spacing: Theme.Spacing.xs) {
                // WalletConnect QR option
                WalletOptionButton(
                    icon: .qrCode,
                    title: "Scan QR Code",
                    subtitle: "Connect any WalletConnect wallet",
                    action: { showQRCodeFlow() }
                )

                // WalletConnect link (for other wallets)
                if installedWallets.isEmpty {
                    WalletOptionButton(
                        icon: .walletConnect,
                        title: "WalletConnect",
                        subtitle: "Open in external wallet",
                        action: { connectWallet(.walletConnect) }
                    )
                }
            }
        }
    }

    // MARK: - Info Text

    private var infoText: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xxs) {
                IconView(.shield, size: .sm, color: Theme.Colors.textTertiary)
                Text("Secure Connection")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Text("Your wallet will ask you to approve the connection. We never have access to your private keys.")
                .font(Typography.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.md)
    }

    // MARK: - Actions

    private func loadInstalledWallets() async {
        isLoading = true

        // Get installed wallets from auth repository
        installedWallets = await dependencies.authenticationRepository.getInstalledWallets()

        isLoading = false
    }

    private func connectWallet(_ walletType: WalletAppType) {
        guard connectingWallet == nil else { return }

        connectingWallet = walletType

        Task {
            do {
                let user = try await dependencies.authenticationRepository.connectWallet(walletType)
                await MainActor.run {
                    connectingWallet = nil
                    dismiss()
                    onConnect(user)
                }
            } catch let error as AuthenticationError {
                await MainActor.run {
                    connectingWallet = nil
                    connectionError = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    connectingWallet = nil
                    connectionError = error.localizedDescription
                }
            }
        }
    }

    private func showQRCodeFlow() {
        Task {
            do {
                // This will emit connecting state with URI
                _ = try await dependencies.authenticationRepository.connectWithQRCode()
            } catch let error as AuthenticationError {
                if case .userCancelled = error {
                    // User cancelled, don't show error
                } else {
                    await MainActor.run {
                        connectionError = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    connectionError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Wallet Button

private struct WalletButton: View {
    let wallet: WalletAppType
    let isConnecting: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Wallet icon
                WalletIcon(wallet: wallet)

                // Wallet name
                Text(wallet.rawValue)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer()

                // Loading or arrow
                if isConnecting {
                    ProgressView()
                        .tint(Theme.Colors.primaryFallback)
                } else {
                    IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.surface)
            }
        }
        .disabled(isConnecting)
    }
}

// MARK: - Wallet Option Button

private struct WalletOptionButton: View {
    let icon: AppIcon
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.1))
                        .frame(width: 44, height: 44)

                    IconView(icon, size: .md, color: Theme.Colors.primaryFallback)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.titleSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.surface)
            }
        }
    }
}

// MARK: - Wallet Icon

private struct WalletIcon: View {
    let wallet: WalletAppType

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .fill(backgroundColor)
                .frame(width: 44, height: 44)

            // Use SF Symbol as placeholder, in production use actual wallet icons
            IconView(sfSymbol, size: .md, color: iconColor)
        }
    }

    private var sfSymbol: AppIcon {
        switch wallet {
        case .metamask: return .wallet
        case .rainbow: return .wallet
        case .trust: return .shield
        case .coinbase: return .wallet
        case .phantom: return .sparkle
        case .walletConnect: return .walletConnect
        case .other: return .wallet
        }
    }

    private var backgroundColor: Color {
        switch wallet {
        case .metamask: return Color(hex: "F6851B").opacity(0.15)
        case .rainbow: return Color(hex: "FF6B6B").opacity(0.15)
        case .trust: return Color(hex: "0500FF").opacity(0.15)
        case .coinbase: return Color(hex: "0052FF").opacity(0.15)
        case .phantom: return Color(hex: "AB9FF2").opacity(0.15)
        case .walletConnect: return Color(hex: "3B99FC").opacity(0.15)
        case .other: return Theme.Colors.textTertiary.opacity(0.15)
        }
    }

    private var iconColor: Color {
        switch wallet {
        case .metamask: return Color(hex: "F6851B")
        case .rainbow: return Color(hex: "FF6B6B")
        case .trust: return Color(hex: "0500FF")
        case .coinbase: return Color(hex: "0052FF")
        case .phantom: return Color(hex: "AB9FF2")
        case .walletConnect: return Color(hex: "3B99FC")
        case .other: return Theme.Colors.textTertiary
        }
    }
}

// MARK: - QR Code View

private struct QRCodeView: View {
    let uri: String
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // QR Code placeholder
                // In production, use a QR code generator library
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .fill(Color.white)
                        .frame(width: 250, height: 250)

                    VStack(spacing: Theme.Spacing.sm) {
                        IconView(.qrCode, size: .xxl, color: Theme.Colors.textPrimary)
                        Text("QR Code")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                VStack(spacing: Theme.Spacing.xs) {
                    Text("Scan with your wallet")
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Open your mobile wallet and scan this QR code to connect")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Theme.Spacing.xl)

                Spacer()

                // Copy URI button
                Button {
                    UIPasteboard.general.string = uri
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        IconView(.copy, size: .sm, color: Theme.Colors.primaryFallback)
                        Text("Copy Link")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                }
                .padding(.bottom, Theme.Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
            .navigationTitle("Connect Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WalletPickerView { user in
        print("Connected: \(user)")
    }
    .environment(\.dependencies, .shared)
}
