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

/// EIP-712 typed data structure
struct TypedData: Sendable {
    let domain: EIP712Domain
    let types: [String: [EIP712Type]]
    let primaryType: String
    let message: [String: AnyEncodable]
}

/// EIP-712 domain separator
struct EIP712Domain: Codable, Sendable {
    let name: String
    let version: String
    let chainId: UInt64
    let verifyingContract: String
}

/// EIP-712 type definition
struct EIP712Type: Codable, Sendable {
    let name: String
    let type: String
}

/// Type-erased Encodable wrapper
struct AnyEncodable: Encodable, Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
