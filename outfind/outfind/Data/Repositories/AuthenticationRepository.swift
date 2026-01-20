import Foundation
import UIKit

// MARK: - Authentication Repository

/// Implementation of AuthenticationRepositoryProtocol
/// Manages both wallet and Google authentication
final class AuthenticationRepository: AuthenticationRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _currentUser: User?
    private var stateContinuation: AsyncStream<AuthenticationState>.Continuation?

    private let walletConnectService: WalletConnectServiceProtocol
    private let googleAuthService: GoogleAuthServiceProtocol
    private let configuration: ConfigurationProtocol

    init(
        walletConnectService: WalletConnectServiceProtocol,
        googleAuthService: GoogleAuthServiceProtocol,
        configuration: ConfigurationProtocol
    ) {
        self.walletConnectService = walletConnectService
        self.googleAuthService = googleAuthService
        self.configuration = configuration
    }

    // MARK: - Current State

    var currentUser: User? {
        get async {
            lock.lock()
            defer { lock.unlock() }
            return _currentUser
        }
    }

    var isAuthenticated: Bool {
        get async {
            await currentUser != nil
        }
    }

    // MARK: - Wallet Authentication

    func getInstalledWallets() async -> [WalletAppType] {
        await MainActor.run {
            WalletConnectService.detectInstalledWallets()
        }
    }

    func connectWallet(_ walletType: WalletAppType) async throws -> User {
        emitState(.authenticating(method: .wallet(walletType)))

        do {
            let walletAuth = try await walletConnectService.connect(walletType: walletType)

            // Validate chain ID
            guard walletAuth.chainId == configuration.chainId else {
                throw AuthenticationError.wrongNetwork(
                    expected: configuration.chainId,
                    actual: walletAuth.chainId
                )
            }

            let user = User.fromWallet(walletAuth)

            lock.lock()
            _currentUser = user
            lock.unlock()

            emitState(.authenticated(user))
            return user

        } catch let error as AuthenticationError {
            emitState(.error(error))
            throw error
        } catch {
            let authError = AuthenticationError.walletConnectionFailed(error.localizedDescription)
            emitState(.error(authError))
            throw authError
        }
    }

    func connectWithQRCode() async throws -> User {
        do {
            // Get URI for QR code
            let uri = try await walletConnectService.getPairingURI()
            emitState(.authenticating(method: .walletConnectQR(uri: uri)))

            // Wait for connection
            let walletAuth = try await walletConnectService.connectViaQRCode()

            // Validate chain ID
            guard walletAuth.chainId == configuration.chainId else {
                throw AuthenticationError.wrongNetwork(
                    expected: configuration.chainId,
                    actual: walletAuth.chainId
                )
            }

            let user = User.fromWallet(walletAuth)

            lock.lock()
            _currentUser = user
            lock.unlock()

            emitState(.authenticated(user))
            return user

        } catch let error as AuthenticationError {
            emitState(.error(error))
            throw error
        } catch {
            let authError = AuthenticationError.walletConnectionFailed(error.localizedDescription)
            emitState(.error(authError))
            throw authError
        }
    }

    // MARK: - Google Authentication

    func signInWithGoogle() async throws -> User {
        emitState(.authenticating(method: .google))

        do {
            let googleAuth = try await googleAuthService.signIn()
            let user = User.fromGoogle(googleAuth)

            lock.lock()
            _currentUser = user
            lock.unlock()

            emitState(.authenticated(user))
            return user

        } catch let error as AuthenticationError {
            emitState(.error(error))
            throw error
        } catch {
            let authError = AuthenticationError.googleSignInFailed(error.localizedDescription)
            emitState(.error(authError))
            throw authError
        }
    }

    // MARK: - Session Management

    func disconnect() async throws {
        lock.lock()
        let user = _currentUser
        _currentUser = nil
        lock.unlock()

        // Disconnect based on auth method
        if let authMethod = user?.authMethod {
            switch authMethod {
            case .wallet:
                try await walletConnectService.disconnect()
            case .google:
                try await googleAuthService.signOut()
            }
        }

        emitState(.unauthenticated)
    }

    func observeAuthState() -> AsyncStream<AuthenticationState> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }

            self.lock.lock()
            self.stateContinuation = continuation
            let user = self._currentUser
            self.lock.unlock()

            // Emit current state
            if let user = user {
                continuation.yield(.authenticated(user))
            } else {
                continuation.yield(.unauthenticated)
            }

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.stateContinuation = nil
                self?.lock.unlock()
            }
        }
    }

    func refreshAuthentication() async throws -> User {
        lock.lock()
        let currentUser = _currentUser
        lock.unlock()

        guard let user = currentUser else {
            throw AuthenticationError.sessionExpired
        }

        switch user.authMethod {
        case .wallet:
            // Wallet sessions don't need refresh, just verify connection
            return user

        case .google:
            // Refresh Google tokens
            guard let refreshedAuth = try await googleAuthService.refreshTokensIfNeeded() else {
                throw AuthenticationError.tokenRefreshFailed
            }

            let refreshedUser = User.fromGoogle(refreshedAuth)

            lock.lock()
            _currentUser = refreshedUser
            lock.unlock()

            return refreshedUser
        }
    }

    // MARK: - Signing

    func signMessage(_ message: String) async throws -> Data {
        lock.lock()
        let user = _currentUser
        lock.unlock()

        guard let user = user else {
            throw AuthenticationError.signingFailed("Not authenticated")
        }

        guard let address = user.protocolAddress else {
            throw AuthenticationError.signingFailed("No address available for signing")
        }

        switch user.authMethod {
        case .wallet:
            return try await walletConnectService.signMessage(message, address: address)

        case .google:
            // For Google auth with embedded wallet, we would use server-side signing
            // or MPC in production. For now, throw an error.
            throw AuthenticationError.signingFailed("Embedded wallet signing not yet implemented")
        }
    }

    func signTypedData(_ typedData: TypedData) async throws -> Data {
        lock.lock()
        let user = _currentUser
        lock.unlock()

        guard let user = user else {
            throw AuthenticationError.signingFailed("Not authenticated")
        }

        guard let address = user.protocolAddress else {
            throw AuthenticationError.signingFailed("No address available for signing")
        }

        switch user.authMethod {
        case .wallet:
            return try await walletConnectService.signTypedData(typedData, address: address)

        case .google:
            throw AuthenticationError.signingFailed("Embedded wallet signing not yet implemented")
        }
    }

    // MARK: - Private Helpers

    private func emitState(_ state: AuthenticationState) {
        lock.lock()
        let continuation = stateContinuation
        lock.unlock()

        continuation?.yield(state)
    }
}

// MARK: - Mock Authentication Repository

/// Mock implementation for development and testing
final class MockAuthenticationRepository: AuthenticationRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _currentUser: User?
    private var stateContinuation: AsyncStream<AuthenticationState>.Continuation?

    // Persistence key for UserDefaults
    private let authUserKey = "lapses.auth.currentUser"

    init() {
        // Load cached user on init
        loadCachedUser()
    }

    var currentUser: User? {
        get async {
            lock.lock()
            defer { lock.unlock() }
            return _currentUser
        }
    }

    var isAuthenticated: Bool {
        get async {
            await currentUser != nil
        }
    }

    func getInstalledWallets() async -> [WalletAppType] {
        // Actually detect installed wallets on the device
        await MainActor.run {
            WalletAppType.installedWallets
        }
    }

    func connectWallet(_ walletType: WalletAppType) async throws -> User {
        emitState(.authenticating(method: .wallet(walletType)))

        // Actually try to open the wallet app
        await openWalletApp(walletType)

        // Simulate connection delay (waiting for wallet approval)
        try await Task.sleep(nanoseconds: 2_000_000_000)

        // Generate a mock connected wallet (in production, this comes from WalletConnect)
        let auth = WalletAuth(
            address: Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!,
            chainId: ProtocolConstants.chainId,
            walletType: walletType,
            displayName: walletType.rawValue,
            iconURL: nil,
            sessionTopic: UUID().uuidString,
            authenticatedAt: Date()
        )

        let user = User.fromWallet(auth)

        lock.lock()
        _currentUser = user
        lock.unlock()

        // Cache the user
        cacheUser(user)

        emitState(.authenticated(user))
        return user
    }

    func connectWithQRCode() async throws -> User {
        let uri = "wc:\(UUID().uuidString)@2?relay-protocol=irn"
        emitState(.authenticating(method: .walletConnectQR(uri: uri)))

        // Simulate waiting for scan
        try await Task.sleep(nanoseconds: 30_000_000_000) // 30 second timeout

        throw AuthenticationError.userCancelled
    }

    func signInWithGoogle() async throws -> User {
        emitState(.authenticating(method: .google))

        // Actually trigger Google sign-in
        let googleAuth = try await performGoogleSignIn()

        let user = User.fromGoogle(googleAuth)

        lock.lock()
        _currentUser = user
        lock.unlock()

        // Cache the user
        cacheUser(user)

        emitState(.authenticated(user))
        return user
    }

    func disconnect() async throws {
        lock.lock()
        _currentUser = nil
        lock.unlock()

        // Clear cached user
        clearCachedUser()

        emitState(.unauthenticated)
    }

    func observeAuthState() -> AsyncStream<AuthenticationState> {
        AsyncStream { [weak self] continuation in
            guard let self else { return }

            self.lock.lock()
            self.stateContinuation = continuation
            let user = self._currentUser
            self.lock.unlock()

            if let user = user {
                continuation.yield(.authenticated(user))
            } else {
                continuation.yield(.unauthenticated)
            }

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.stateContinuation = nil
                self?.lock.unlock()
            }
        }
    }

    func refreshAuthentication() async throws -> User {
        guard let user = await currentUser else {
            throw AuthenticationError.sessionExpired
        }
        return user
    }

    func signMessage(_ message: String) async throws -> Data {
        guard await isAuthenticated else {
            throw AuthenticationError.signingFailed("Not authenticated")
        }
        return Data(repeating: 0xAB, count: ProtocolConstants.signatureSize)
    }

    func signTypedData(_ typedData: TypedData) async throws -> Data {
        guard await isAuthenticated else {
            throw AuthenticationError.signingFailed("Not authenticated")
        }
        return Data(repeating: 0xCD, count: ProtocolConstants.signatureSize)
    }

    private func emitState(_ state: AuthenticationState) {
        lock.lock()
        let continuation = stateContinuation
        lock.unlock()

        continuation?.yield(state)
    }

    // MARK: - Wallet App Opening

    @MainActor
    private func openWalletApp(_ walletType: WalletAppType) {
        guard let scheme = walletType.urlScheme,
              let url = URL(string: scheme) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Google Sign-In

    private func performGoogleSignIn() async throws -> GoogleAuth {
        // MVP: Simulated Google sign-in flow
        // TODO: Replace with real OAuth when scaling (see Option 1 in docs)

        // Simulate network delay for realistic UX
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

        // Generate a mock Google auth response
        let mockEmails = [
            "alex.developer@gmail.com",
            "sam.designer@gmail.com",
            "jordan.creator@gmail.com"
        ]
        let mockNames = [
            "Alex Developer",
            "Sam Designer",
            "Jordan Creator"
        ]

        let randomIndex = Int.random(in: 0..<mockEmails.count)

        return GoogleAuth(
            userId: UUID().uuidString,
            email: mockEmails[randomIndex],
            displayName: mockNames[randomIndex],
            avatarURL: nil,
            idToken: "mock-id-token-\(UUID().uuidString)",
            accessToken: "mock-access-token-\(UUID().uuidString)",
            tokenExpiresAt: Date().addingTimeInterval(3600),
            embeddedWalletAddress: Address(rawValue: "0x742d35Cc6634C0532925a3b844Bc9e7595f89332"),
            authenticatedAt: Date()
        )
    }

    // MARK: - User Caching

    private func cacheUser(_ user: User) {
        // For security, we only cache minimal info
        let cacheData = AuthCacheData(
            id: user.id,
            displayIdentifier: user.displayIdentifier,
            displayName: user.displayName,
            isWallet: user.authMethod.isWallet,
            protocolAddress: user.protocolAddress?.hex,
            cachedAt: Date()
        )

        if let encoded = try? JSONEncoder().encode(cacheData) {
            UserDefaults.standard.set(encoded, forKey: authUserKey)
        }
    }

    private func loadCachedUser() {
        guard let data = UserDefaults.standard.data(forKey: authUserKey),
              let cacheData = try? JSONDecoder().decode(AuthCacheData.self, from: data) else {
            return
        }

        // Reconstruct a minimal user from cache
        if cacheData.isWallet, let addressHex = cacheData.protocolAddress,
           let address = Address(rawValue: addressHex) {
            let auth = WalletAuth(
                address: address,
                chainId: ProtocolConstants.chainId,
                walletType: .walletConnect,
                displayName: cacheData.displayName,
                iconURL: nil,
                sessionTopic: nil,
                authenticatedAt: cacheData.cachedAt
            )
            _currentUser = User.fromWallet(auth)
        } else {
            let auth = GoogleAuth(
                userId: cacheData.id,
                email: cacheData.displayIdentifier,
                displayName: cacheData.displayName,
                avatarURL: nil,
                idToken: "",
                accessToken: "",
                tokenExpiresAt: Date().addingTimeInterval(3600),
                embeddedWalletAddress: cacheData.protocolAddress.flatMap { Address(rawValue: $0) },
                authenticatedAt: cacheData.cachedAt
            )
            _currentUser = User.fromGoogle(auth)
        }
    }

    private func clearCachedUser() {
        UserDefaults.standard.removeObject(forKey: authUserKey)
    }
}

// MARK: - Continuation Resume Tracker

/// Thread-safe class to track if a continuation has been resumed
/// Used to prevent double-resume in async callbacks
private final class ContinuationResumeTracker: @unchecked Sendable {
    private let lock = NSLock()
    private var hasResumed = false

    /// Marks as resumed and returns true if this was the first call
    /// Returns false if already resumed
    func markAsResumed() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if hasResumed {
            return false
        }
        hasResumed = true
        return true
    }
}

// MARK: - Auth Cache Data

private struct AuthCacheData: Codable {
    let id: String
    let displayIdentifier: String
    let displayName: String?
    let isWallet: Bool
    let protocolAddress: String?
    let cachedAt: Date
}

// MARK: - Web Auth Context Provider

import AuthenticationServices

/// Provides presentation anchor for ASWebAuthenticationSession
/// Note: Not marked @MainActor to avoid sendability issues with ASWebAuthenticationPresentationContextProviding
private final class WebAuthContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
        super.init()
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // ASWebAuthenticationSession always calls this on main thread
        window
    }
}

// MARK: - Auth Session Holder

/// Holds a reference to the auth session to prevent it from being deallocated
@MainActor
private final class AuthSessionHolder {
    static var currentSession: ASWebAuthenticationSession?
    static var contextProvider: WebAuthContextProvider?
}
