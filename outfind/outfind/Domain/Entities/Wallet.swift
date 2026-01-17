import Foundation

/// Represents a connected wallet
struct Wallet: Equatable, Hashable, Sendable {
    /// The wallet's Ethereum address
    let address: Address

    /// Connected chain ID
    let chainId: UInt64

    /// Whether the wallet is currently connected
    let isConnected: Bool

    /// Type of wallet connection
    let walletType: WalletType

    /// Display name from wallet metadata (if available)
    let displayName: String?

    /// Wallet icon URL (if available)
    let iconURL: URL?

    /// WalletConnect session topic (if using WalletConnect)
    let sessionTopic: String?

    /// When the wallet was connected
    let connectedAt: Date?

    // MARK: - Validation

    /// Whether the wallet is on the correct network
    var isOnCorrectNetwork: Bool {
        chainId == ProtocolConstants.chainId
    }

    /// Whether the wallet can perform protocol operations
    var canPerformProtocolOperations: Bool {
        isConnected && isOnCorrectNetwork
    }
}

/// Type of wallet connection
enum WalletType: String, Codable, Sendable {
    /// Connected via WalletConnect v2
    case walletConnect

    /// Injected wallet (e.g., browser extension)
    case injected

    /// Mock wallet for testing
    case mock
}

// MARK: - Factory Methods

extension Wallet {
    /// Create a disconnected wallet state
    static var disconnected: Wallet {
        Wallet(
            address: .zero,
            chainId: 0,
            isConnected: false,
            walletType: .walletConnect,
            displayName: nil,
            iconURL: nil,
            sessionTopic: nil,
            connectedAt: nil
        )
    }

    /// Create a mock wallet for previews and testing
    static func mock(
        address: Address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!,
        isConnected: Bool = true
    ) -> Wallet {
        Wallet(
            address: address,
            chainId: ProtocolConstants.chainId,
            isConnected: isConnected,
            walletType: .mock,
            displayName: "Test Wallet",
            iconURL: nil,
            sessionTopic: nil,
            connectedAt: isConnected ? Date() : nil
        )
    }
}

// MARK: - Connection State

/// Wallet connection state for observing connection flow
enum WalletConnectionState: Equatable, Sendable {
    /// Not connected
    case disconnected

    /// Connecting, showing QR code or deep link
    case connecting(uri: String)

    /// Successfully connected
    case connected(Wallet)

    /// Connection failed
    case error(WalletError)
}

/// Wallet-related errors
enum WalletError: Error, Equatable, Sendable {
    /// Connection to wallet failed
    case connectionFailed(String)

    /// User rejected the connection request
    case userRejected

    /// Session expired
    case sessionExpired

    /// Wrong network connected
    case wrongNetwork(expected: UInt64, actual: UInt64)

    /// Signature request failed
    case signatureFailed(String)

    /// Transaction failed
    case transactionFailed(String)

    /// Unknown error
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .connectionFailed(let message):
            return "Connection failed: \(message)"
        case .userRejected:
            return "Connection rejected by user"
        case .sessionExpired:
            return "Session expired, please reconnect"
        case .wrongNetwork(let expected, let actual):
            return "Wrong network. Expected chain \(expected), got \(actual)"
        case .signatureFailed(let message):
            return "Signature failed: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
