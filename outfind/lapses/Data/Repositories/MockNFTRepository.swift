import Foundation

// MARK: - Mock NFT Repository

/// Mock implementation of NFTRepositoryProtocol for development and testing
final class MockNFTRepository: NFTRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var mintedNFTs: [UInt64: EpochNFT] = [:] // epochId -> NFT
    private var ownerNFTs: [String: [EpochNFT]] = [:] // ownerAddress -> [NFT]
    private var nextTokenId: UInt64 = 1

    // MARK: - NFTRepositoryProtocol

    let contractAddress: Address = Address(rawValue: "0x7aE1a83D4B1a7ac97a6e49F1E4D3dFFC2A4f9E90")!

    func isEpochMinted(epochId: UInt64) async throws -> Bool {
        lock.lock()
        let isMinted = mintedNFTs[epochId] != nil
        lock.unlock()
        return isMinted
    }

    func getNFTForEpoch(epochId: UInt64) async throws -> EpochNFT? {
        lock.lock()
        let nft = mintedNFTs[epochId]
        lock.unlock()
        return nft
    }

    func getNFTsForOwner(owner: Address) async throws -> [EpochNFT] {
        lock.lock()
        let nfts = ownerNFTs[owner.hex] ?? []
        lock.unlock()
        return nfts
    }

    func mintEpochNFT(epoch: Epoch, owner: Address) -> AsyncStream<NFTMintingState> {
        AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.yield(.failed(.unknown("Repository deallocated")))
                continuation.finish()
                return
            }

            Task {
                // Check if already minted
                if try await self.isEpochMinted(epochId: epoch.id) {
                    continuation.yield(.failed(.alreadyMinted))
                    continuation.finish()
                    return
                }

                // Check if epoch is finalized
                guard epoch.state == .finalized || epoch.state == .closed else {
                    continuation.yield(.failed(.epochNotFinalized))
                    continuation.finish()
                    return
                }

                // Step 1: Preparing metadata
                continuation.yield(.preparingMetadata)
                try? await Task.sleep(nanoseconds: 800_000_000)

                // Step 2: Awaiting signature
                continuation.yield(.awaitingSignature)
                try? await Task.sleep(nanoseconds: 1_200_000_000)

                // Step 3: Transaction pending
                let mockTxHash = "0x\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
                continuation.yield(.pending(transactionHash: mockTxHash))
                try? await Task.sleep(nanoseconds: 2_000_000_000)

                // Step 4: Create the NFT
                self.lock.lock()
                let tokenId = self.nextTokenId
                self.nextTokenId += 1
                self.lock.unlock()

                let nft = EpochNFT(
                    id: tokenId,
                    epochId: epoch.id,
                    contractAddress: self.contractAddress,
                    chainId: ProtocolConstants.chainId,
                    owner: owner,
                    tokenURI: "ipfs://Qm\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))",
                    mintTransactionHash: mockTxHash,
                    mintBlockNumber: UInt64.random(in: 5_000_000...6_000_000),
                    mintedAt: Date(),
                    epochTitle: epoch.title,
                    duration: epoch.duration,
                    participantCount: epoch.participantCount,
                    capability: epoch.capability,
                    creator: owner,
                    epochStartTime: epoch.startTime,
                    epochEndTime: epoch.endTime
                )

                // Store the NFT
                self.lock.lock()
                self.mintedNFTs[epoch.id] = nft
                var ownerList = self.ownerNFTs[owner.hex] ?? []
                ownerList.append(nft)
                self.ownerNFTs[owner.hex] = ownerList
                self.lock.unlock()

                // Step 5: Success
                continuation.yield(.success(nft))
                continuation.finish()
            }
        }
    }

    func estimateGasCost(epoch: Epoch) async throws -> UInt64 {
        // Simulate gas estimation delay
        try await Task.sleep(nanoseconds: 300_000_000)

        // Return mock gas estimate (~0.001 ETH in Wei at 20 gwei)
        // 50,000 gas * 20 gwei = 1,000,000,000,000,000 wei = 0.001 ETH
        return 1_000_000_000_000_000
    }

    // MARK: - Test Helpers

    /// Add a pre-minted NFT for testing
    func addMintedNFT(_ nft: EpochNFT) {
        lock.lock()
        mintedNFTs[nft.epochId] = nft
        var ownerList = ownerNFTs[nft.owner.hex] ?? []
        ownerList.append(nft)
        ownerNFTs[nft.owner.hex] = ownerList
        lock.unlock()
    }

    /// Clear all minted NFTs
    func clearAllNFTs() {
        lock.lock()
        mintedNFTs.removeAll()
        ownerNFTs.removeAll()
        nextTokenId = 1
        lock.unlock()
    }
}
