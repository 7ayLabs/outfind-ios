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
            dev: "https://api.dev.outfind.me",
            staging: "https://api.staging.outfind.me",
            prod: "https://api.outfind.me"
        ))
    }

    var wsBaseURL: URL {
        url(forKey: "WS_BASE_URL", default: environmentDefault(
            dev: "wss://ws.dev.outfind.me",
            staging: "wss://ws.staging.outfind.me",
            prod: "wss://ws.outfind.me"
        ))
    }

    var ipfsGatewayURL: URL {
        url(forKey: "IPFS_GATEWAY_URL", default: "https://ipfs.outfind.me")
    }

    var rpcURL: URL {
        url(forKey: "RPC_URL", default: "https://sepolia.infura.io/v3/")
    }

    // MARK: - WalletConnect

    var walletConnectProjectId: String {
        string(forKey: "WALLET_CONNECT_PROJECT_ID", required: true)
    }

    var walletConnectRelayURL: String {
        string(forKey: "WALLET_CONNECT_RELAY_URL", default: "wss://relay.walletconnect.com")
    }

    // MARK: - Blockchain

    var chainId: UInt64 {
        uint64(forKey: "CHAIN_ID", default: ProtocolConstants.chainId)
    }

    var epochRegistryAddress: String {
        string(forKey: "EPOCH_REGISTRY_ADDRESS", required: true)
    }

    var presenceRegistryAddress: String {
        string(forKey: "PRESENCE_REGISTRY_ADDRESS", required: true)
    }

    var validatorRegistryAddress: String {
        string(forKey: "VALIDATOR_REGISTRY_ADDRESS", required: true)
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
}

// MARK: - Mock Configuration for Testing

final class MockConfiguration: ConfigurationProtocol, @unchecked Sendable {
    let environment: AppEnvironment = .development
    var apiBaseURL: URL = URL(string: "https://api.mock.outfind.me")!
    var wsBaseURL: URL = URL(string: "wss://ws.mock.outfind.me")!
    var ipfsGatewayURL: URL = URL(string: "https://ipfs.mock.outfind.me")!
    var rpcURL: URL = URL(string: "https://mock.rpc.url")!
    var walletConnectProjectId: String = "mock-project-id"
    var walletConnectRelayURL: String = "wss://relay.mock.walletconnect.com"
    var chainId: UInt64 = 11155111
    var epochRegistryAddress: String = "0x1111111111111111111111111111111111111111"
    var presenceRegistryAddress: String = "0x2222222222222222222222222222222222222222"
    var validatorRegistryAddress: String = "0x3333333333333333333333333333333333333333"
    var httpTimeout: TimeInterval = 30
    var wsConnectionTimeout: TimeInterval = 15
}
