import Foundation

/// Application environment
enum AppEnvironment: String, CaseIterable {
    case development
    case staging
    case production

    /// Current environment based on build configuration
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        if let envString = Bundle.main.infoDictionary?["APP_ENVIRONMENT"] as? String,
           let env = AppEnvironment(rawValue: envString.lowercased()) {
            return env
        }
        return .production
        #endif
    }

    var isDebug: Bool {
        self == .development
    }
}

/// Configuration protocol for dependency injection and testing
protocol ConfigurationProtocol: Sendable {
    var environment: AppEnvironment { get }

    // MARK: - Network
    var apiBaseURL: URL { get }
    var wsBaseURL: URL { get }
    var ipfsGatewayURL: URL { get }
    var rpcURL: URL { get }

    // MARK: - WalletConnect
    var walletConnectProjectId: String { get }
    var walletConnectRelayURL: String { get }

    // MARK: - Google OAuth
    var googleClientId: String { get }
    var googleRedirectScheme: String { get }

    // MARK: - Blockchain
    var chainId: UInt64 { get }
    var epochRegistryAddress: String { get }
    var presenceRegistryAddress: String { get }
    var validatorRegistryAddress: String { get }

    // MARK: - Timeouts
    var httpTimeout: TimeInterval { get }
    var wsConnectionTimeout: TimeInterval { get }
}

/// Configuration loader that reads from environment and Info.plist
final class Configuration: ConfigurationProtocol, @unchecked Sendable {
    static let shared = Configuration()

    let environment: AppEnvironment

    private let bundle: Bundle
    private let processInfo: ProcessInfo

    init(
        environment: AppEnvironment = .current,
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) {
        self.environment = environment
        self.bundle = bundle
        self.processInfo = processInfo
    }

    // MARK: - Network URLs

    var apiBaseURL: URL {
        url(forKey: "API_BASE_URL", default: environmentDefault(
            dev: "https://api.dev.lapses.me",
            staging: "https://api.staging.lapses.me",
            prod: "https://api.lapses.me"
        ))
    }

    var wsBaseURL: URL {
        url(forKey: "WS_BASE_URL", default: environmentDefault(
            dev: "wss://ws.dev.lapses.me",
            staging: "wss://ws.staging.lapses.me",
            prod: "wss://ws.lapses.me"
        ))
    }

    var ipfsGatewayURL: URL {
        url(forKey: "IPFS_GATEWAY_URL", default: "https://ipfs.lapses.me")
    }

    var rpcURL: URL {
        url(forKey: "RPC_URL", default: "https://sepolia.infura.io/v3/")
    }

    // MARK: - WalletConnect

    var walletConnectProjectId: String {
        // Use placeholder for development - replace with real project ID for production
        string(forKey: "WALLET_CONNECT_PROJECT_ID", default: developmentDefault("dev-wallet-connect-project-id"))
    }

    var walletConnectRelayURL: String {
        string(forKey: "WALLET_CONNECT_RELAY_URL", default: "wss://relay.walletconnect.com")
    }

    // MARK: - Google OAuth

    var googleClientId: String {
        // Use placeholder for development - replace with real client ID for production
        string(forKey: "GOOGLE_CLIENT_ID", default: developmentDefault("000000000000-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com"))
    }

    var googleRedirectScheme: String {
        string(forKey: "GOOGLE_REDIRECT_SCHEME", default: "lapses")
    }

    // MARK: - Blockchain

    var chainId: UInt64 {
        uint64(forKey: "CHAIN_ID", default: ProtocolConstants.chainId)
    }

    var epochRegistryAddress: String {
        // Use placeholder for development - replace with real address for production
        string(forKey: "EPOCH_REGISTRY_ADDRESS", default: developmentDefault("0x1111111111111111111111111111111111111111"))
    }

    var presenceRegistryAddress: String {
        // Use placeholder for development - replace with real address for production
        string(forKey: "PRESENCE_REGISTRY_ADDRESS", default: developmentDefault("0x2222222222222222222222222222222222222222"))
    }

    var validatorRegistryAddress: String {
        // Use placeholder for development - replace with real address for production
        string(forKey: "VALIDATOR_REGISTRY_ADDRESS", default: developmentDefault("0x3333333333333333333333333333333333333333"))
    }

    // MARK: - Timeouts

    var httpTimeout: TimeInterval {
        TimeInterval(uint64(forKey: "HTTP_TIMEOUT", default: 30))
    }

    var wsConnectionTimeout: TimeInterval {
        TimeInterval(uint64(forKey: "WS_CONNECTION_TIMEOUT", default: 15))
    }

    // MARK: - Private Helpers

    private func string(forKey key: String, default defaultValue: String = "") -> String {
        processInfo.environment[key]
            ?? bundle.infoDictionary?[key] as? String
            ?? defaultValue
    }

    private func string(forKey key: String, required: Bool) -> String {
        let value = string(forKey: key)
        if required && value.isEmpty {
            assertionFailure("Missing required configuration: \(key)")
        }
        return value
    }

    private func uint64(forKey key: String, default defaultValue: UInt64) -> UInt64 {
        if let stringValue = processInfo.environment[key] ?? bundle.infoDictionary?[key] as? String,
           let value = UInt64(stringValue) {
            return value
        }
        return defaultValue
    }

    private func url(forKey key: String, default defaultValue: String) -> URL {
        let urlString = string(forKey: key, default: defaultValue)
        guard let url = URL(string: urlString) else {
            assertionFailure("Invalid URL for \(key): \(urlString)")
            return URL(string: defaultValue)!
        }
        return url
    }

    private func environmentDefault(dev: String, staging: String, prod: String) -> String {
        switch environment {
        case .development: return dev
        case .staging: return staging
        case .production: return prod
        }
    }

    /// Returns the default value only in development, otherwise returns empty string
    /// This allows the app to run in development without real configuration
    private func developmentDefault(_ value: String) -> String {
        #if DEBUG
        return value
        #else
        return ""
        #endif
    }
}

// MARK: - Mock Configuration for Testing

final class MockConfiguration: ConfigurationProtocol, @unchecked Sendable {
    let environment: AppEnvironment = .development
    var apiBaseURL: URL = URL(string: "https://api.mock.lapses.me")!
    var wsBaseURL: URL = URL(string: "wss://ws.mock.lapses.me")!
    var ipfsGatewayURL: URL = URL(string: "https://ipfs.mock.lapses.me")!
    var rpcURL: URL = URL(string: "https://mock.rpc.url")!
    var walletConnectProjectId: String = "mock-project-id"
    var walletConnectRelayURL: String = "wss://relay.mock.walletconnect.com"
    var googleClientId: String = "mock-google-client-id.apps.googleusercontent.com"
    var googleRedirectScheme: String = "lapses"
    var chainId: UInt64 = 11155111
    var epochRegistryAddress: String = "0x1111111111111111111111111111111111111111"
    var presenceRegistryAddress: String = "0x2222222222222222222222222222222222222222"
    var validatorRegistryAddress: String = "0x3333333333333333333333333333333333333333"
    var httpTimeout: TimeInterval = 30
    var wsConnectionTimeout: TimeInterval = 15
}
