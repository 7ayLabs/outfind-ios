import Foundation
import UIKit

// MARK: - Authentication Method

/// Represents the method used to authenticate the user
enum AuthMethod: Equatable, Hashable, Sendable, Codable {
    /// Authenticated via wallet connection (WalletConnect)
    case wallet(WalletAuth)

    /// Authenticated via Google Sign-In
    case google(GoogleAuth)

    /// Display identifier for the auth method
    var displayIdentifier: String {
        switch self {
        case .wallet(let auth):
            return auth.address.abbreviated
        case .google(let auth):
            return auth.email
        }
    }

    /// Display name for the user
    var displayName: String? {
        switch self {
        case .wallet(let auth):
            return auth.displayName ?? auth.address.abbreviated
        case .google(let auth):
            return auth.displayName
        }
    }

    /// Avatar URL if available
    var avatarURL: URL? {
        switch self {
        case .wallet(let auth):
            return auth.iconURL
        case .google(let auth):
            return auth.avatarURL
        }
    }

    /// Whether this is a wallet-based auth
    var isWallet: Bool {
        if case .wallet = self { return true }
        return false
    }

    /// Whether this is a Google-based auth
    var isGoogle: Bool {
        if case .google = self { return true }
        return false
    }

    /// Ethereum address (for wallet) or derived address (for Google via embedded wallet)
    var address: Address? {
        switch self {
        case .wallet(let auth):
            return auth.address
        case .google(let auth):
            return auth.embeddedWalletAddress
        }
    }
}

// MARK: - Wallet Auth

/// Wallet-based authentication details
struct WalletAuth: Equatable, Hashable, Sendable, Codable {
    /// Ethereum address
    let address: Address

    /// Chain ID
    let chainId: UInt64

    /// Wallet type (MetaMask, Rainbow, etc.)
    let walletType: WalletAppType

    /// Display name from wallet metadata
    let displayName: String?

    /// Wallet icon URL
    let iconURL: URL?

    /// WalletConnect session topic
    let sessionTopic: String?

    /// When authenticated
    let authenticatedAt: Date
}

/// Supported wallet apps
enum WalletAppType: String, CaseIterable, Sendable, Codable {
    case metamask = "MetaMask"
    case rainbow = "Rainbow"
    case trust = "Trust Wallet"
    case coinbase = "Coinbase Wallet"
    case phantom = "Phantom"
    case walletConnect = "WalletConnect"
    case other = "Other"

    /// URL scheme for deep linking
    var urlScheme: String? {
        switch self {
        case .metamask: return "metamask://"
        case .rainbow: return "rainbow://"
        case .trust: return "trust://"
        case .coinbase: return "cbwallet://"
        case .phantom: return "phantom://"
        case .walletConnect, .other: return nil
        }
    }

    /// Icon name for the wallet
    var iconName: String {
        switch self {
        case .metamask: return "metamask"
        case .rainbow: return "rainbow"
        case .trust: return "trust"
        case .coinbase: return "coinbase"
        case .phantom: return "phantom"
        case .walletConnect: return "walletconnect"
        case .other: return "wallet"
        }
    }

    /// Whether the wallet app is installed (must be called on main thread)
    @MainActor
    var isInstalled: Bool {
        guard let scheme = urlScheme, let url = URL(string: scheme) else {
            return false
        }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Get all installed wallet apps (must be called on main thread)
    @MainActor
    static var installedWallets: [WalletAppType] {
        allCases.filter { $0.isInstalled && $0 != .other && $0 != .walletConnect }
    }
}

// MARK: - Google Auth

/// Google Sign-In authentication details
struct GoogleAuth: Equatable, Hashable, Sendable, Codable {
    /// Google user ID
    let userId: String

    /// User's email address
    let email: String

    /// User's display name
    let displayName: String?

    /// User's avatar URL
    let avatarURL: URL?

    /// ID token for backend verification
    let idToken: String

    /// Access token for API calls
    let accessToken: String

    /// Token expiration date
    let tokenExpiresAt: Date

    /// Embedded wallet address (derived from Google account for blockchain interactions)
    /// This is generated via account abstraction or MPC when user signs in with Google
    let embeddedWalletAddress: Address?

    /// When authenticated
    let authenticatedAt: Date

    /// Whether the tokens are expired
    var isTokenExpired: Bool {
        Date() >= tokenExpiresAt
    }
}

// MARK: - User

/// Represents the authenticated user in the app
struct User: Equatable, Hashable, Sendable {
    /// Unique user identifier (address for wallet, Google user ID for Google)
    let id: String

    /// Authentication method used
    let authMethod: AuthMethod

    /// When the user first authenticated
    let createdAt: Date

    /// Last authentication time
    let lastAuthenticatedAt: Date

    /// Display identifier for the user
    var displayIdentifier: String {
        authMethod.displayIdentifier
    }

    /// Display name
    var displayName: String? {
        authMethod.displayName
    }

    /// Avatar URL
    var avatarURL: URL? {
        authMethod.avatarURL
    }

    /// Ethereum address for protocol operations
    var protocolAddress: Address? {
        authMethod.address
    }

    /// Whether the user can perform on-chain operations
    var canPerformChainOperations: Bool {
        protocolAddress != nil
    }
}

// MARK: - Factory Methods

extension User {
    /// Create a user from wallet authentication
    static func fromWallet(_ auth: WalletAuth) -> User {
        User(
            id: auth.address.hex,
            authMethod: .wallet(auth),
            createdAt: auth.authenticatedAt,
            lastAuthenticatedAt: auth.authenticatedAt
        )
    }

    /// Create a user from Google authentication
    static func fromGoogle(_ auth: GoogleAuth) -> User {
        User(
            id: auth.userId,
            authMethod: .google(auth),
            createdAt: auth.authenticatedAt,
            lastAuthenticatedAt: auth.authenticatedAt
        )
    }

    /// Mock wallet user for previews
    static var mockWallet: User {
        let auth = WalletAuth(
            address: Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!,
            chainId: ProtocolConstants.chainId,
            walletType: .metamask,
            displayName: "vitalik.eth",
            iconURL: nil,
            sessionTopic: "mock-session",
            authenticatedAt: Date()
        )
        return .fromWallet(auth)
    }

    /// Mock Google user for previews
    static var mockGoogle: User {
        let auth = GoogleAuth(
            userId: "123456789",
            email: "user@example.com",
            displayName: "Test User",
            avatarURL: URL(string: "https://example.com/avatar.jpg"),
            idToken: "mock-id-token",
            accessToken: "mock-access-token",
            tokenExpiresAt: Date().addingTimeInterval(3600),
            embeddedWalletAddress: Address(rawValue: "0x742d35Cc6634C0532925a3b844Bc9e7595f89332"),
            authenticatedAt: Date()
        )
        return .fromGoogle(auth)
    }
}
