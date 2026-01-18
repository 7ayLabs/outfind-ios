import Foundation

// MARK: - Authentication Repository Protocol

/// Repository protocol for authentication operations
/// Supports both wallet and Google authentication methods
protocol AuthenticationRepositoryProtocol: Sendable {
    /// Current authenticated user (if any)
    var currentUser: User? { get async }

    /// Whether a user is currently authenticated
    var isAuthenticated: Bool { get async }

    // MARK: - Wallet Authentication

    /// Get list of installed wallet apps
    func getInstalledWallets() async -> [WalletAppType]

    /// Connect using a specific wallet app
    /// - Parameter walletType: The wallet app to use for connection
    /// - Returns: Authenticated user
    func connectWallet(_ walletType: WalletAppType) async throws -> User

    /// Connect using WalletConnect QR code flow
    /// - Returns: Authenticated user
    func connectWithQRCode() async throws -> User

    // MARK: - Google Authentication

    /// Sign in with Google
    /// - Returns: Authenticated user
    func signInWithGoogle() async throws -> User

    // MARK: - Session Management

    /// Disconnect and clear session
    func disconnect() async throws

    /// Observe authentication state changes
    func observeAuthState() -> AsyncStream<AuthenticationState>

    /// Refresh authentication (for Google token refresh)
    func refreshAuthentication() async throws -> User

    // MARK: - Signing

    /// Sign a message with the current authentication method
    /// - Parameter message: Message to sign
    /// - Returns: ECDSA signature (65 bytes)
    func signMessage(_ message: String) async throws -> Data

    /// Sign typed data (EIP-712) - only available for wallet auth
    /// - Parameter typedData: Typed data structure
    /// - Returns: ECDSA signature (65 bytes)
    func signTypedData(_ typedData: TypedData) async throws -> Data
}

// MARK: - Authentication State

/// Represents the current authentication state
enum AuthenticationState: Equatable, Sendable {
    /// Not authenticated
    case unauthenticated

    /// Authentication in progress
    case authenticating(method: AuthenticatingMethod)

    /// Successfully authenticated
    case authenticated(User)

    /// Authentication failed
    case error(AuthenticationError)

    /// Check if authenticated
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }

    /// Get current user if authenticated
    var user: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

/// Method being used for authentication
enum AuthenticatingMethod: Equatable, Sendable {
    case wallet(WalletAppType)
    case walletConnectQR(uri: String)
    case google
}

// MARK: - Authentication Errors

/// Authentication-related errors
enum AuthenticationError: Error, Equatable, Sendable {
    /// User cancelled the authentication
    case userCancelled

    /// Wallet connection failed
    case walletConnectionFailed(String)

    /// Google sign-in failed
    case googleSignInFailed(String)

    /// Wrong network
    case wrongNetwork(expected: UInt64, actual: UInt64)

    /// Session expired
    case sessionExpired

    /// Token refresh failed
    case tokenRefreshFailed

    /// No wallet installed
    case noWalletInstalled

    /// Signing failed
    case signingFailed(String)

    /// Embedded wallet creation failed (for Google auth)
    case embeddedWalletFailed(String)

    /// Unknown error
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .userCancelled:
            return "Authentication was cancelled"
        case .walletConnectionFailed(let message):
            return "Wallet connection failed: \(message)"
        case .googleSignInFailed(let message):
            return "Google sign-in failed: \(message)"
        case .wrongNetwork(let expected, let actual):
            return "Wrong network. Expected chain \(expected), got \(actual)"
        case .sessionExpired:
            return "Session expired. Please sign in again"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication"
        case .noWalletInstalled:
            return "No compatible wallet app installed"
        case .signingFailed(let message):
            return "Signing failed: \(message)"
        case .embeddedWalletFailed(let message):
            return "Failed to create embedded wallet: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Equatable for User in AuthenticationState

extension AuthenticationState {
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating(let lMethod), .authenticating(let rMethod)):
            return lMethod == rMethod
        case (.authenticated(let lUser), .authenticated(let rUser)):
            return lUser == rUser
        case (.error(let lError), .error(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}
