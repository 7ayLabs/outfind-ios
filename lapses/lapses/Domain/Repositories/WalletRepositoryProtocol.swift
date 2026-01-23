import Foundation

/// Repository protocol for wallet operations
protocol WalletRepositoryProtocol: Sendable {
    /// Current connected wallet (if any)
    var currentWallet: Wallet? { get async }

    /// Connect wallet via WalletConnect
    /// - Returns: Connected wallet
    func connect() async throws -> Wallet

    /// Disconnect current wallet
    func disconnect() async throws

    /// Sign a message with the connected wallet
    /// - Parameter message: Message to sign (as UTF-8 string)
    /// - Returns: ECDSA signature (65 bytes)
    func signMessage(_ message: String) async throws -> Data

    /// Sign typed data (EIP-712)
    /// - Parameter typedData: Typed data structure
    /// - Returns: ECDSA signature (65 bytes)
    func signTypedData(_ typedData: TypedData) async throws -> Data

    /// Observe wallet connection state changes
    func observeWalletState() -> AsyncStream<WalletConnectionState>
}

// MARK: - EIP-712 Types

/// EIP-712 typed data structure for signing
/// Simplified for MVP - will be expanded for actual EIP-712 signing
struct TypedData {
    let domain: EIP712Domain
    let types: [String: [EIP712Type]]
    let primaryType: String
    let messageJSON: Data

    init(domain: EIP712Domain, types: [String: [EIP712Type]], primaryType: String, messageJSON: Data) {
        self.domain = domain
        self.types = types
        self.primaryType = primaryType
        self.messageJSON = messageJSON
    }
}

/// EIP-712 domain separator
struct EIP712Domain {
    let name: String
    let version: String
    let chainId: UInt64
    let verifyingContract: String
}

/// EIP-712 type definition
struct EIP712Type {
    let name: String
    let type: String
}
