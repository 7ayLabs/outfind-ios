import Foundation
import SwiftUI

// MARK: - Dependency Container

/// Central dependency injection container using modern @Observable pattern
/// Provides lazy initialization and factory pattern for dependency creation
@Observable
@MainActor
final class DependencyContainer {

    // MARK: - Shared Instance

    static let shared = DependencyContainer()

    // MARK: - Configuration

    let configuration: ConfigurationProtocol

    // MARK: - Repository Storage

    private var _walletRepository: (any WalletRepositoryProtocol)?
    private var _epochRepository: (any EpochRepositoryProtocol)?
    private var _presenceRepository: (any PresenceRepositoryProtocol)?
    private var _ephemeralCacheRepository: (any EphemeralCacheRepositoryProtocol)?

    // MARK: - Manager Storage

    private var _epochLifecycleManager: EpochLifecycleManager?

    // MARK: - Factories

    private let repositoryFactory: RepositoryFactory

    // MARK: - Initialization

    init(
        configuration: ConfigurationProtocol = Configuration.shared,
        repositoryFactory: RepositoryFactory? = nil
    ) {
        self.configuration = configuration
        self.repositoryFactory = repositoryFactory ?? DefaultRepositoryFactory(configuration: configuration)
    }

    // MARK: - Repository Access

    var walletRepository: any WalletRepositoryProtocol {
        if let repo = _walletRepository { return repo }
        let repo = repositoryFactory.makeWalletRepository()
        _walletRepository = repo
        return repo
    }

    var epochRepository: any EpochRepositoryProtocol {
        if let repo = _epochRepository { return repo }
        let repo = repositoryFactory.makeEpochRepository()
        _epochRepository = repo
        return repo
    }

    var presenceRepository: any PresenceRepositoryProtocol {
        if let repo = _presenceRepository { return repo }
        let repo = repositoryFactory.makePresenceRepository()
        _presenceRepository = repo
        return repo
    }

    var ephemeralCacheRepository: any EphemeralCacheRepositoryProtocol {
        if let repo = _ephemeralCacheRepository { return repo }
        let repo = repositoryFactory.makeEphemeralCacheRepository()
        _ephemeralCacheRepository = repo
        return repo
    }

    // MARK: - Manager Access

    var epochLifecycleManager: EpochLifecycleManager {
        if let manager = _epochLifecycleManager { return manager }
        let manager = EpochLifecycleManager(
            epochRepository: epochRepository,
            presenceRepository: presenceRepository,
            ephemeralCacheRepository: ephemeralCacheRepository
        )
        _epochLifecycleManager = manager
        return manager
    }

    // MARK: - Reset (for testing)

    func reset() {
        _walletRepository = nil
        _epochRepository = nil
        _presenceRepository = nil
        _ephemeralCacheRepository = nil
        _epochLifecycleManager = nil
    }

    // MARK: - Register Custom Implementations (for testing)

    func register(walletRepository: any WalletRepositoryProtocol) {
        _walletRepository = walletRepository
    }

    func register(epochRepository: any EpochRepositoryProtocol) {
        _epochRepository = epochRepository
    }

    func register(presenceRepository: any PresenceRepositoryProtocol) {
        _presenceRepository = presenceRepository
    }

    func register(ephemeralCacheRepository: any EphemeralCacheRepositoryProtocol) {
        _ephemeralCacheRepository = ephemeralCacheRepository
    }
}

// MARK: - Repository Factory Protocol

protocol RepositoryFactory: Sendable {
    func makeWalletRepository() -> any WalletRepositoryProtocol
    func makeEpochRepository() -> any EpochRepositoryProtocol
    func makePresenceRepository() -> any PresenceRepositoryProtocol
    func makeEphemeralCacheRepository() -> any EphemeralCacheRepositoryProtocol
}

// MARK: - Default Repository Factory

final class DefaultRepositoryFactory: RepositoryFactory, @unchecked Sendable {
    private let configuration: ConfigurationProtocol

    init(configuration: ConfigurationProtocol) {
        self.configuration = configuration
    }

    func makeWalletRepository() -> any WalletRepositoryProtocol {
        MockWalletRepository()
    }

    func makeEpochRepository() -> any EpochRepositoryProtocol {
        MockEpochRepository()
    }

    func makePresenceRepository() -> any PresenceRepositoryProtocol {
        MockPresenceRepository()
    }

    func makeEphemeralCacheRepository() -> any EphemeralCacheRepositoryProtocol {
        InMemoryEphemeralCacheRepository()
    }
}

// MARK: - Mock Repository Factory (for testing)

final class MockRepositoryFactory: RepositoryFactory, @unchecked Sendable {
    var walletRepository: (any WalletRepositoryProtocol)?
    var epochRepository: (any EpochRepositoryProtocol)?
    var presenceRepository: (any PresenceRepositoryProtocol)?
    var ephemeralCacheRepository: (any EphemeralCacheRepositoryProtocol)?

    func makeWalletRepository() -> any WalletRepositoryProtocol {
        walletRepository ?? MockWalletRepository()
    }

    func makeEpochRepository() -> any EpochRepositoryProtocol {
        epochRepository ?? MockEpochRepository()
    }

    func makePresenceRepository() -> any PresenceRepositoryProtocol {
        presenceRepository ?? MockPresenceRepository()
    }

    func makeEphemeralCacheRepository() -> any EphemeralCacheRepositoryProtocol {
        ephemeralCacheRepository ?? InMemoryEphemeralCacheRepository()
    }
}

// MARK: - SwiftUI Environment

extension EnvironmentValues {
    @Entry var dependencies: DependencyContainer = .shared
}
