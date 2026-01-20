import Foundation

/// Represents an Epoch minted as an NFT on Sepolia testnet
/// ERC-721 compliant token representing a finalized epoch
struct EpochNFT: Identifiable, Equatable, Hashable, Sendable {
    /// NFT token ID on the contract
    let id: UInt64

    /// Original epoch ID this NFT represents
    let epochId: UInt64

    /// NFT contract address on Sepolia
    let contractAddress: Address

    /// Chain ID (11155111 for Sepolia)
    let chainId: UInt64

    /// Owner's wallet address
    let owner: Address

    /// Token URI pointing to metadata (IPFS or HTTP)
    let tokenURI: String

    /// Transaction hash of the mint transaction
    let mintTransactionHash: String

    /// Block number when minted
    let mintBlockNumber: UInt64

    /// Timestamp when minted
    let mintedAt: Date

    // MARK: - Epoch Metadata (stored on-chain/IPFS)

    /// Original epoch title
    let epochTitle: String

    /// Epoch duration in seconds
    let duration: TimeInterval

    /// Number of participants at epoch close
    let participantCount: UInt64

    /// Epoch capability level
    let capability: EpochCapability

    /// Epoch creator address
    let creator: Address

    /// Original epoch start time
    let epochStartTime: Date

    /// Original epoch end time
    let epochEndTime: Date

    // MARK: - Computed Properties

    /// OpenSea testnet URL for this NFT
    var openSeaURL: URL? {
        URL(string: "https://testnets.opensea.io/assets/sepolia/\(contractAddress.rawValue)/\(id)")
    }

    /// Etherscan transaction URL
    var transactionURL: URL? {
        URL(string: "https://sepolia.etherscan.io/tx/\(mintTransactionHash)")
    }

    /// IPFS gateway URL if tokenURI is IPFS
    var metadataURL: URL? {
        if tokenURI.hasPrefix("ipfs://") {
            let hash = tokenURI.replacingOccurrences(of: "ipfs://", with: "")
            return URL(string: "https://ipfs.io/ipfs/\(hash)")
        }
        return URL(string: tokenURI)
    }
}

// MARK: - NFT Metadata Schema (ERC-721 compliant)

/// Metadata structure for EpochNFT following ERC-721 metadata standard
struct EpochNFTMetadata: Codable, Sendable {
    /// NFT name
    let name: String

    /// NFT description
    let description: String

    /// Image URL (IPFS or HTTP)
    let image: String

    /// External URL to view epoch details
    let externalUrl: String?

    /// NFT attributes array
    let attributes: [NFTAttribute]

    enum CodingKeys: String, CodingKey {
        case name, description, image, attributes
        case externalUrl = "external_url"
    }
}

/// Single attribute for NFT metadata
struct NFTAttribute: Codable, Sendable {
    /// Attribute trait type
    let traitType: String

    /// Attribute value (String or Number)
    let value: AttributeValue

    /// Display type for special formatting
    let displayType: String?

    enum CodingKeys: String, CodingKey {
        case traitType = "trait_type"
        case value
        case displayType = "display_type"
    }
}

/// Attribute value that can be string or number
enum AttributeValue: Codable, Sendable {
    case string(String)
    case number(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .number(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                AttributeValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Minting State

/// State of an NFT minting operation
enum NFTMintingState: Equatable, Sendable {
    /// Idle, no minting in progress
    case idle

    /// Preparing metadata and uploading to IPFS
    case preparingMetadata

    /// Waiting for wallet signature
    case awaitingSignature

    /// Transaction submitted, waiting for confirmation
    case pending(transactionHash: String)

    /// Minting successful
    case success(EpochNFT)

    /// Minting failed
    case failed(NFTMintingError)
}

/// Errors that can occur during NFT minting
enum NFTMintingError: Error, Equatable, Sendable {
    /// Epoch is not finalized (cannot mint active/closed epochs)
    case epochNotFinalized

    /// User is not the epoch creator
    case notEpochCreator

    /// Epoch already minted as NFT
    case alreadyMinted

    /// Wallet not connected
    case walletNotConnected

    /// User rejected signature
    case userRejected

    /// Insufficient funds for gas
    case insufficientFunds

    /// Transaction failed
    case transactionFailed(String)

    /// Metadata upload failed
    case metadataUploadFailed

    /// Network error
    case networkError(String)

    /// Unknown error
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .epochNotFinalized:
            return "Epoch must be finalized before minting"
        case .notEpochCreator:
            return "Only the epoch creator can mint this NFT"
        case .alreadyMinted:
            return "This epoch has already been minted as an NFT"
        case .walletNotConnected:
            return "Please connect your wallet to mint"
        case .userRejected:
            return "Signature request was rejected"
        case .insufficientFunds:
            return "Insufficient ETH for gas fees"
        case .transactionFailed(let reason):
            return "Transaction failed: \(reason)"
        case .metadataUploadFailed:
            return "Failed to upload metadata to IPFS"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Factory Methods

extension EpochNFT {
    /// Create a mock EpochNFT for previews and testing
    static func mock(
        id: UInt64 = 1,
        epochId: UInt64 = 1,
        epochTitle: String = "Tech Meetup 2026"
    ) -> EpochNFT {
        EpochNFT(
            id: id,
            epochId: epochId,
            contractAddress: Address(rawValue: "0x7aE1a83D4B1a7ac97a6e49F1E4D3dFFC2A4f9E90")!,
            chainId: ProtocolConstants.chainId,
            owner: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
            tokenURI: "ipfs://QmTest123456789abcdef",
            mintTransactionHash: "0xabc123def456789",
            mintBlockNumber: 12345678,
            mintedAt: Date(),
            epochTitle: epochTitle,
            duration: 7200,
            participantCount: 42,
            capability: .presenceWithSignals,
            creator: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
            epochStartTime: Date().addingTimeInterval(-7200),
            epochEndTime: Date().addingTimeInterval(-3600)
        )
    }
}

// MARK: - Metadata Builder

extension EpochNFTMetadata {
    /// Create metadata from an Epoch
    static func from(epoch: Epoch, creator: Address, imageURL: String) -> EpochNFTMetadata {
        let attributes: [NFTAttribute] = [
            NFTAttribute(
                traitType: "Duration",
                value: .string(formatDuration(epoch.duration)),
                displayType: nil
            ),
            NFTAttribute(
                traitType: "Participants",
                value: .number(Int(epoch.participantCount)),
                displayType: nil
            ),
            NFTAttribute(
                traitType: "Capability",
                value: .string(epoch.capability.displayName),
                displayType: nil
            ),
            NFTAttribute(
                traitType: "Creator",
                value: .string(creator.abbreviated),
                displayType: nil
            ),
            NFTAttribute(
                traitType: "Created At",
                value: .number(Int(epoch.startTime.timeIntervalSince1970)),
                displayType: "date"
            ),
            NFTAttribute(
                traitType: "Network",
                value: .string("Sepolia"),
                displayType: nil
            ),
            NFTAttribute(
                traitType: "Protocol Version",
                value: .string(ProtocolConstants.version),
                displayType: nil
            )
        ]

        return EpochNFTMetadata(
            name: "7ay Epoch: \(epoch.title)",
            description: "Ephemeral presence epoch on 7ay Network. \(epoch.description ?? "")",
            image: imageURL,
            externalUrl: "https://lapses.me/epoch/\(epoch.id)",
            attributes: attributes
        )
    }

    private static func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
        return "\(minutes) minute\(minutes == 1 ? "" : "s")"
    }
}
