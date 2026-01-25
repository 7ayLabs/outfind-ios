import SwiftUI

// MARK: - Mint NFT Sheet

/// Sheet view for minting an epoch as an NFT on Sepolia testnet
struct MintNFTSheet: View {
    let epoch: Epoch

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies

    @State private var mintingState: NFTMintingState = .idle
    @State private var estimatedGas: String = "~0.001 ETH"
    @State private var isLoadingGas = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // NFT Preview Card
                        nftPreviewCard

                        // Epoch Details
                        epochDetailsSection

                        // Network Info
                        networkInfoSection

                        // Minting Status
                        mintingStatusSection

                        // Action Button
                        actionButton
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Mint as NFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .task {
                await loadGasEstimate()
            }
        }
    }

    // MARK: - NFT Preview Card

    private var nftPreviewCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // NFT Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primaryFallback.opacity(0.3),
                                Theme.Colors.liveGreen.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)

                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Colors.liveGreen)

                    Text("7ay Epoch")
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("#\(epoch.id)")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            // Title
            Text(epoch.title)
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            // Collection badge
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.liveGreen)

                Text("7ay Epochs Collection")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.xl)
    }

    // MARK: - Epoch Details Section

    private var epochDetailsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            detailRow(label: "Duration", value: formatDuration(epoch.duration))
            detailRow(label: "Participants", value: "\(epoch.participantCount)")
            detailRow(label: "Capability", value: epoch.capability.displayName)
            detailRow(label: "Created", value: formatDate(epoch.startTime))
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    // MARK: - Network Info Section

    private var networkInfoSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(Theme.Colors.liveGreen)
                        .frame(width: 8, height: 8)
                    Text("Network")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                Text("Sepolia Testnet")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            HStack {
                Text("Estimated Gas")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Spacer()

                if isLoadingGas {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(estimatedGas)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }

            // Free badge
            HStack {
                Spacer()
                Text("FREE on Testnet")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.liveGreen)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.liveGreen.opacity(0.15))
                    }
                Spacer()
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Minting Status Section

    @ViewBuilder
    private var mintingStatusSection: some View {
        switch mintingState {
        case .idle:
            EmptyView()

        case .preparingMetadata:
            statusView(
                icon: "doc.text.fill",
                title: "Preparing Metadata",
                subtitle: "Uploading to IPFS...",
                color: Theme.Colors.info
            )

        case .awaitingSignature:
            statusView(
                icon: "signature",
                title: "Signature Required",
                subtitle: "Please sign the transaction in your wallet",
                color: Theme.Colors.warning
            )

        case .pending(let txHash):
            statusView(
                icon: "clock.fill",
                title: "Transaction Pending",
                subtitle: "Hash: \(String(txHash.prefix(18)))...",
                color: Theme.Colors.primaryFallback
            )

        case .success(let nft):
            successView(nft)

        case .failed(let error):
            errorView(error)
        }
    }

    private func statusView(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            ProgressView()
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    private func successView(_ nft: EpochNFT) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.success.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Colors.success)
            }

            Text("NFT Minted Successfully!")
                .font(Typography.titleMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Token ID: #\(nft.id)")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.md) {
                if let url = nft.openSeaURL {
                    Link(destination: url) {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "arrow.up.right.square")
                            Text("OpenSea")
                        }
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                }

                if let url = nft.transactionURL {
                    Link(destination: url) {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Etherscan")
                        }
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                }
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    private func errorView(_ error: NFTMintingError) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.error.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.error)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Minting Failed")
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(error.localizedDescription)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch mintingState {
        case .idle, .failed:
            Button {
                startMinting()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 18))
                    Text("Mint NFT (Free)")
                        .font(Typography.titleSmall)
                }
                .foregroundStyle(Theme.Colors.textOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.liveGreen, Theme.Colors.primaryFallback],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .buttonStyle(ScaleButtonStyle())

        case .success:
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(Theme.Colors.primaryFallback)
                    }
            }
            .buttonStyle(ScaleButtonStyle())

        default:
            // Minting in progress - disabled button
            HStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                    .tint(Theme.Colors.textOnAccent)
                Text("Minting...")
                    .font(Typography.titleSmall)
            }
            .foregroundStyle(Theme.Colors.textOnAccent.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.textTertiary)
            }
        }
    }

    // MARK: - Methods

    private func loadGasEstimate() async {
        isLoadingGas = true
        do {
            let gasWei = try await dependencies.nftRepository.estimateGasCost(epoch: epoch)
            let ethValue = Double(gasWei) / 1_000_000_000_000_000_000
            await MainActor.run {
                estimatedGas = String(format: "~%.4f ETH", ethValue)
                isLoadingGas = false
            }
        } catch {
            await MainActor.run {
                estimatedGas = "~0.001 ETH"
                isLoadingGas = false
            }
        }
    }

    private func startMinting() {
        Task {
            guard let wallet = await dependencies.walletRepository.currentWallet else {
                mintingState = .failed(.walletNotConnected)
                return
            }

            for await state in dependencies.nftRepository.mintEpochNFT(epoch: epoch, owner: wallet.address) {
                await MainActor.run {
                    mintingState = state
                }
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    MintNFTSheet(epoch: .mock(id: 1, title: "Tech Meetup 2026", state: .finalized))
        .environment(\.dependencies, .shared)
}
