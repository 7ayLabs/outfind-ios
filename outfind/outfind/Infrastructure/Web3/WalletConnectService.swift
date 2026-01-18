import Foundation
import UIKit

// MARK: - WalletConnect Service Protocol

/// Protocol for WalletConnect operations
protocol WalletConnectServiceProtocol: Sendable {
    /// Initialize the WalletConnect client
    func initialize() async throws

    /// Get the WalletConnect pairing URI for QR code
    func getPairingURI() async throws -> String

    /// Connect to a wallet using deep link
    /// - Parameter walletType: The wallet app to connect to
    func connect(walletType: WalletAppType) async throws -> WalletAuth

    /// Connect via QR code flow
    func connectViaQRCode() async throws -> WalletAuth

    /// Disconnect current session
    func disconnect() async throws

    /// Sign a personal message
    func signMessage(_ message: String, address: Address) async throws -> Data

    /// Sign typed data (EIP-712)
    func signTypedData(_ typedData: TypedData, address: Address) async throws -> Data

    /// Observe connection state
    func observeConnectionState() -> AsyncStream<WalletConnectState>
}

// MARK: - WalletConnect State

/// State of the WalletConnect connection
enum WalletConnectState: Equatable, Sendable {
    case disconnected
    case connecting(uri: String)
    case connected(session: WCSession)
    case error(String)
}

/// Represents a WalletConnect session
struct WCSession: Equatable, Sendable {
    let topic: String
    let address: Address
    let chainId: UInt64
    let walletName: String?
    let walletIconURL: URL?
}

// MARK: - WalletConnect Service Implementation

/// Service for handling WalletConnect v2 connections
/// Note: This is a placeholder implementation. In production, integrate with WalletConnectSwift SDK.
actor WalletConnectService: WalletConnectServiceProtocol {
    private let configuration: ConfigurationProtocol
    private var currentSession: WCSession?
    private var stateContinuation: AsyncStream<WalletConnectState>.Continuation?

    init(configuration: ConfigurationProtocol) {
        self.configuration = configuration
    }

    // MARK: - Initialization

    func initialize() async throws {
        // TODO: Initialize WalletConnect v2 client
        // Requires: import WalletConnectSwift
        // let metadata = AppMetadata(
        //     name: "Outfind",
        //     description: "Ephemeral presence protocol",
        //     url: "https://outfind.me",
        //     icons: ["https://outfind.me/icon.png"]
        // )
        // Pair.configure(metadata: metadata)
        // Sign.configure(...)

        print("[WalletConnect] Service initialized with project ID: \(configuration.walletConnectProjectId)")
    }

    // MARK: - Connection

    func getPairingURI() async throws -> String {
        // TODO: Generate actual pairing URI using WalletConnect SDK
        // let uri = try await Pair.instance.create()
        // return uri.absoluteString

        // Placeholder: Return mock URI
        let mockURI = "wc:\(UUID().uuidString)@2?relay-protocol=irn&symKey=\(UUID().uuidString)"
        stateContinuation?.yield(.connecting(uri: mockURI))
        return mockURI
    }

    func connect(walletType: WalletAppType) async throws -> WalletAuth {
        // Get pairing URI
        let uri = try await getPairingURI()

        // Open wallet app with deep link
        await openWalletApp(walletType, uri: uri)

        // Wait for session establishment
        // TODO: Implement actual session waiting with WalletConnect SDK
        // In real implementation:
        // for await session in Sign.instance.sessionsPublisher.values {
        //     // Handle session
        // }

        // Simulate connection delay and return mock session
        try await Task.sleep(nanoseconds: 2_000_000_000)

        let session = WCSession(
            topic: UUID().uuidString,
            address: Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!,
            chainId: configuration.chainId,
            walletName: walletType.rawValue,
            walletIconURL: nil
        )

        currentSession = session
        stateContinuation?.yield(.connected(session: session))

        return WalletAuth(
            address: session.address,
            chainId: session.chainId,
            walletType: walletType,
            displayName: session.walletName,
            iconURL: session.walletIconURL,
            sessionTopic: session.topic,
            authenticatedAt: Date()
        )
    }

    func connectViaQRCode() async throws -> WalletAuth {
        let uri = try await getPairingURI()

        // Emit connecting state with URI for QR code display
        stateContinuation?.yield(.connecting(uri: uri))

        // Wait for wallet to scan QR and connect
        // TODO: Implement actual session waiting

        try await Task.sleep(nanoseconds: 30_000_000_000) // 30 second timeout

        throw AuthenticationError.userCancelled
    }

    func disconnect() async throws {
        guard let session = currentSession else { return }

        // TODO: Disconnect using WalletConnect SDK
        // try await Sign.instance.disconnect(topic: session.topic)

        currentSession = nil
        stateContinuation?.yield(.disconnected)
    }

    // MARK: - Signing

    func signMessage(_ message: String, address: Address) async throws -> Data {
        guard let session = currentSession else {
            throw AuthenticationError.signingFailed("No active session")
        }

        // TODO: Request signature via WalletConnect
        // let params = AnyCodable(["message": message, "address": address.hex])
        // let request = Request(topic: session.topic, method: "personal_sign", params: params)
        // let response = try await Sign.instance.request(request)

        // Simulate signature delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Return mock signature
        return Data(repeating: 0xAB, count: ProtocolConstants.signatureSize)
    }

    func signTypedData(_ typedData: TypedData, address: Address) async throws -> Data {
        guard let session = currentSession else {
            throw AuthenticationError.signingFailed("No active session")
        }

        // TODO: Request EIP-712 signature via WalletConnect
        // Simulate signature delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Return mock signature
        return Data(repeating: 0xCD, count: ProtocolConstants.signatureSize)
    }

    // MARK: - State Observation

    func observeConnectionState() -> AsyncStream<WalletConnectState> {
        AsyncStream { continuation in
            self.stateContinuation = continuation

            if let session = self.currentSession {
                continuation.yield(.connected(session: session))
            } else {
                continuation.yield(.disconnected)
            }

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.clearContinuation()
                }
            }
        }
    }

    private func clearContinuation() {
        stateContinuation = nil
    }

    // MARK: - Private Helpers

    @MainActor
    private func openWalletApp(_ walletType: WalletAppType, uri: String) {
        guard let scheme = walletType.urlScheme else {
            // If no specific scheme, try universal link or system handler
            if let url = URL(string: "wc:\(uri)") {
                UIApplication.shared.open(url)
            }
            return
        }

        // Build deep link URL based on wallet type
        let deepLinkURL: URL?

        switch walletType {
        case .metamask:
            // MetaMask uses: metamask://wc?uri=<encoded_uri>
            let encodedURI = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri
            deepLinkURL = URL(string: "metamask://wc?uri=\(encodedURI)")

        case .rainbow:
            // Rainbow uses: rainbow://wc?uri=<encoded_uri>
            let encodedURI = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri
            deepLinkURL = URL(string: "rainbow://wc?uri=\(encodedURI)")

        case .trust:
            // Trust Wallet uses: trust://wc?uri=<encoded_uri>
            let encodedURI = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri
            deepLinkURL = URL(string: "trust://wc?uri=\(encodedURI)")

        case .coinbase:
            // Coinbase Wallet uses: cbwallet://wc?uri=<encoded_uri>
            let encodedURI = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri
            deepLinkURL = URL(string: "cbwallet://wc?uri=\(encodedURI)")

        case .phantom:
            // Phantom uses: phantom://wc?uri=<encoded_uri>
            let encodedURI = uri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri
            deepLinkURL = URL(string: "phantom://wc?uri=\(encodedURI)")

        case .walletConnect, .other:
            // Use universal WalletConnect link
            deepLinkURL = URL(string: "wc:\(uri)")
        }

        if let url = deepLinkURL {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Wallet Detection

extension WalletConnectService {
    /// Check which wallet apps are installed on the device
    @MainActor
    static func detectInstalledWallets() -> [WalletAppType] {
        WalletAppType.installedWallets
    }

    /// Check if any wallet is installed
    @MainActor
    static var hasInstalledWallet: Bool {
        !detectInstalledWallets().isEmpty
    }
}
