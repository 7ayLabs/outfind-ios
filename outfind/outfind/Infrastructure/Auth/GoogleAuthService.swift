import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Google Auth Service Protocol

/// Protocol for Google Sign-In operations
protocol GoogleAuthServiceProtocol: Sendable {
    /// Sign in with Google
    /// - Returns: Google authentication details
    func signIn() async throws -> GoogleAuth

    /// Sign out from Google
    func signOut() async throws

    /// Refresh tokens if needed
    func refreshTokensIfNeeded() async throws -> GoogleAuth?

    /// Get current signed in user
    var currentAuth: GoogleAuth? { get async }
}

// MARK: - Google Auth Service Implementation

/// Service for handling Google Sign-In
/// Note: This implementation uses ASWebAuthenticationSession for OAuth flow.
/// In production, consider using Google Sign-In SDK for better UX.
actor GoogleAuthService: GoogleAuthServiceProtocol {
    private let configuration: ConfigurationProtocol
    private var _currentAuth: GoogleAuth?

    // OAuth endpoints
    private let authorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    private let tokenEndpoint = "https://oauth2.googleapis.com/token"
    private let userInfoEndpoint = "https://www.googleapis.com/oauth2/v3/userinfo"

    // Required scopes
    private let scopes = ["openid", "email", "profile"]

    init(configuration: ConfigurationProtocol) {
        self.configuration = configuration
    }

    var currentAuth: GoogleAuth? {
        _currentAuth
    }

    // MARK: - Sign In

    func signIn() async throws -> GoogleAuth {
        // Generate PKCE challenge
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        // Build authorization URL
        let authURL = buildAuthorizationURL(codeChallenge: codeChallenge)

        // Perform OAuth flow
        let callbackURL = try await performOAuthFlow(authURL: authURL)

        // Extract authorization code from callback
        guard let code = extractAuthorizationCode(from: callbackURL) else {
            throw AuthenticationError.googleSignInFailed("Failed to get authorization code")
        }

        // Exchange code for tokens
        let tokens = try await exchangeCodeForTokens(code: code, codeVerifier: codeVerifier)

        // Get user info
        let userInfo = try await fetchUserInfo(accessToken: tokens.accessToken)

        // Create embedded wallet address for blockchain operations
        // This derives a deterministic address from the Google user ID
        let embeddedAddress = deriveEmbeddedWalletAddress(userId: userInfo.userId)

        let auth = GoogleAuth(
            userId: userInfo.userId,
            email: userInfo.email,
            displayName: userInfo.name,
            avatarURL: userInfo.pictureURL,
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
            tokenExpiresAt: Date().addingTimeInterval(TimeInterval(tokens.expiresIn)),
            embeddedWalletAddress: embeddedAddress,
            authenticatedAt: Date()
        )

        _currentAuth = auth
        return auth
    }

    func signOut() async throws {
        _currentAuth = nil
    }

    func refreshTokensIfNeeded() async throws -> GoogleAuth? {
        guard let auth = _currentAuth else { return nil }

        // Check if tokens are about to expire (within 5 minutes)
        let expirationBuffer: TimeInterval = 300
        guard Date().addingTimeInterval(expirationBuffer) >= auth.tokenExpiresAt else {
            return auth // Tokens still valid
        }

        // TODO: Implement token refresh using refresh token
        // For now, return nil to trigger re-authentication
        return nil
    }

    // MARK: - OAuth Flow

    @MainActor
    private func performOAuthFlow(authURL: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "outfind"
            ) { callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthenticationError.userCancelled)
                    } else {
                        continuation.resume(throwing: AuthenticationError.googleSignInFailed(error.localizedDescription))
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthenticationError.googleSignInFailed("No callback URL"))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            // Configure and start session
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = WebAuthPresentationContextProvider.shared

            if !session.start() {
                continuation.resume(throwing: AuthenticationError.googleSignInFailed("Failed to start auth session"))
            }
        }
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> TokenResponse {
        var components = URLComponents(string: tokenEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: configuration.googleClientId),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: "outfind://oauth/callback")
        ]

        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthenticationError.googleSignInFailed("Token exchange failed")
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse
    }

    private func fetchUserInfo(accessToken: String) async throws -> UserInfoResponse {
        var request = URLRequest(url: URL(string: userInfoEndpoint)!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthenticationError.googleSignInFailed("Failed to fetch user info")
        }

        let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
        return userInfo
    }

    // MARK: - URL Building

    private func buildAuthorizationURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.googleClientId),
            URLQueryItem(name: "redirect_uri", value: "outfind://oauth/callback"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components.url!
    }

    private func extractAuthorizationCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        return code
    }

    // MARK: - PKCE

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Embedded Wallet

    /// Derives a deterministic Ethereum address from the Google user ID
    /// This allows Google-authenticated users to participate in blockchain operations
    /// In production, this should use proper key derivation (MPC, AA, etc.)
    private func deriveEmbeddedWalletAddress(userId: String) -> Address? {
        // Derive address using SHA256 hash of user ID
        // Note: This is a simplified implementation. Production should use:
        // - Account Abstraction (ERC-4337)
        // - MPC (Multi-Party Computation)
        // - Secure Enclave key derivation
        let data = Data("outfind:embedded:\(userId)".utf8)
        let hash = SHA256.hash(data: data)
        let addressBytes = Array(hash.suffix(20))
        let addressHex = "0x" + addressBytes.map { String(format: "%02x", $0) }.joined()
        return Address(rawValue: addressHex)
    }
}

// MARK: - Response Types

private struct TokenResponse: Codable {
    let accessToken: String
    let idToken: String
    let expiresIn: Int
    let tokenType: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
    }
}

private struct UserInfoResponse: Codable {
    let userId: String
    let email: String
    let name: String?
    let pictureURL: URL?

    enum CodingKeys: String, CodingKey {
        case userId = "sub"
        case email
        case name
        case pictureURL = "picture"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        if let pictureString = try container.decodeIfPresent(String.self, forKey: .pictureURL) {
            pictureURL = URL(string: pictureString)
        } else {
            pictureURL = nil
        }
    }
}

// MARK: - Presentation Context Provider

@MainActor
private final class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

