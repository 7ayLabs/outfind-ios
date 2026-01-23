import Foundation

/// Immutable constants from 7ay-presence protocol v0.4
/// These values are defined by the protocol specification and do not change per environment
enum ProtocolConstants {
    /// Protocol version
    static let version = "0.4"

    // MARK: - Chain Configuration

    /// Sepolia testnet chain ID (protocol testnet)
    static let chainId: UInt64 = 11155111

    // MARK: - Validator Configuration

    /// Default quorum threshold percentage (67% supermajority)
    static let defaultQuorumThreshold: UInt64 = 67

    /// Minimum number of validators required for system operation
    static let minimumValidators: UInt64 = 3

    // MARK: - Timing Constants

    /// Default dispute window in seconds (1 day)
    static let defaultDisputeWindow: UInt64 = 86400

    /// Minimum epoch duration in seconds (1 hour)
    static let minEpochDuration: UInt64 = 3600

    /// Maximum epoch duration in seconds (24 hours)
    static let maxEpochDuration: UInt64 = 86400

    /// Finalization delay after epoch close in seconds (30 minutes)
    static let finalizationDelay: UInt64 = 1800

    // MARK: - Message Constants

    /// Nonce size in bytes for replay protection
    static let nonceSize = 32

    /// ECDSA signature size in bytes (r: 32, s: 32, v: 1)
    static let signatureSize = 65
}
