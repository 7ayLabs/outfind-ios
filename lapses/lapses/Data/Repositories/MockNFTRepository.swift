import Foundation
import os

// MARK: - Mock NFT Repository

/// Mock implementation of NFTRepositoryProtocol for development and testing
final class MockNFTRepository: NFTRepositoryProtocol, @unchecked Sendable {
    private struct NFTState {
        var mintedNFTs: [UInt64: EpochNFT] = [:] // epochId -> NFT
        var ownerNFTs: [String: [EpochNFT]] = [:] // ownerAddress -> [NFT]
        var nextTokenId: UInt64 = 1
    }

    private let state = OSAllocatedUnfairLock(initialState: NFTState())

    // MARK: - NFTRepositoryProtocol

    let contractAddress: Address = Address(rawValue: "0x7aE1a83D4B1a7ac97a6e49F1E4D3dFFC2A4f9E90")!

    func isEpochMinted(epochId: UInt64) async throws -> Bool {
        state.withLock { $0.mintedNFTs[epochId] != nil }
    }

    func getNFTForEpoch(epochId: UInt64) async throws -> EpochNFT? {
        state.withLock { $0.mintedNFTs[epochId] }
    }

    func getNFTsForOwner(owner: Address) async throws -> [EpochNFT] {
        state.withLock { $0.ownerNFTs[owner.hex] ?? [] }
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
                let tokenId = self.state.withLock { nftState -> UInt64 in
                    let id = nftState.nextTokenId
                    nftState.nextTokenId += 1
                    return id
                }

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
                self.state.withLock { nftState in
                    nftState.mintedNFTs[epoch.id] = nft
                    var ownerList = nftState.ownerNFTs[owner.hex] ?? []
                    ownerList.append(nft)
                    nftState.ownerNFTs[owner.hex] = ownerList
                }

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
        state.withLock { nftState in
            nftState.mintedNFTs[nft.epochId] = nft
            var ownerList = nftState.ownerNFTs[nft.owner.hex] ?? []
            ownerList.append(nft)
            nftState.ownerNFTs[nft.owner.hex] = ownerList
        }
    }

    /// Clear all minted NFTs
    func clearAllNFTs() {
        state.withLock { nftState in
            nftState.mintedNFTs.removeAll()
            nftState.ownerNFTs.removeAll()
            nftState.nextTokenId = 1
        }
    }
}
