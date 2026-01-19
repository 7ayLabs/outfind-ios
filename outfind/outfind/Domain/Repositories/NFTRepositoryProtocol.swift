import Foundation

/// Repository protocol for NFT operations on Sepolia testnet
protocol NFTRepositoryProtocol: Sendable {
    /// Check if an epoch has already been minted as an NFT
    /// - Parameter epochId: The epoch ID to check
    /// - Returns: True if already minted
    func isEpochMinted(epochId: UInt64) async throws -> Bool

    /// Get the NFT for a specific epoch if it exists
    /// - Parameter epochId: The epoch ID
    /// - Returns: The EpochNFT if minted, nil otherwise
    func getNFTForEpoch(epochId: UInt64) async throws -> EpochNFT?

    /// Get all NFTs owned by a specific address
    /// - Parameter owner: The wallet address
    /// - Returns: Array of EpochNFTs owned by the address
    func getNFTsForOwner(owner: Address) async throws -> [EpochNFT]

    /// Mint an epoch as an NFT
    /// - Parameters:
    ///   - epoch: The finalized epoch to mint
    ///   - owner: The wallet address to receive the NFT
    /// - Returns: Async stream of minting state updates
    func mintEpochNFT(epoch: Epoch, owner: Address) -> AsyncStream<NFTMintingState>

    /// Estimate gas cost for minting
    /// - Parameter epoch: The epoch to mint
    /// - Returns: Estimated gas in Wei
    func estimateGasCost(epoch: Epoch) async throws -> UInt64

    /// Get the NFT contract address on Sepolia
    var contractAddress: Address { get }

    /// Get the chain ID (should be 11155111 for Sepolia)
    var chainId: UInt64 { get }
}

// MARK: - Default Implementation

extension NFTRepositoryProtocol {
    /// Default chain ID for Sepolia testnet
    var chainId: UInt64 {
        ProtocolConstants.chainId
    }
}
