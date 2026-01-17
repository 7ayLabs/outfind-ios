import Foundation
import SwiftUI

// MARK: - Dependency Container

/// Central dependency injection container using modern @Observable pattern.
/// Provides lazy initialization and factory pattern for dependency creation.
///
/// ## Thread Safety
/// This class is `@MainActor` isolated, ensuring all UI-related access is thread-safe.
/// The `shared` singleton uses `nonisolated(unsafe)` which is safe because:
/// - The instance is created once at app launch
/// - All mutable state access goes through @MainActor methods
/// - Repository factories are Sendable
@Observable
@MainActor
final class DependencyContainer {

    // MARK: - Shared Instance

    /// Global singleton instance for dependency injection.
    /// - Note: Uses `nonisolated(unsafe)` for @Entry compatibility. Safe because
    ///   initialization is deterministic and all state mutations are @MainActor isolated.
    nonisolated(unsafe) static let shared = DependencyContainer()

    // MARK: - Configuration

    let configuration: ConfigurationProtocol

    // MARK: - Repository Storage (Lazy)

    @ObservationIgnored
    private var _walletRepository: (any WalletRepositoryProtocol)?

    @ObservationIgnored
    private var _epochRepository: (any EpochRepositoryProtocol)?

    @ObservationIgnored
    private var _presenceRepository: (any PresenceRepositoryProtocol)?

    @ObservationIgnored
    private var _ephemeralCacheRepository: (any EphemeralCacheRepositoryProtocol)?

    // MARK: - Manager Storage (Lazy)

    @ObservationIgnored
    private var _epochLifecycleManager: EpochLifecycleManager?

    // MARK: - Factories

    @ObservationIgnored
    private let repositoryFactory: RepositoryFactory

    // MARK: - Initialization

    init(
        configuration: ConfigurationProtocol = Configuration.shared,
        repositoryFactory: RepositoryFactory? = nil
    ) {
        self.configuration = configuration
        self.repositoryFactory = repositoryFactory ?? DefaultRepositoryFactory(configuration: configuration)
    }

    // MARK: - Repository Access (Lazy Initialization)

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

    // MARK: - Manager Access (Lazy Initialization)

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

    // MARK: - Testing Support

    /// Resets all cached repositories and managers. For testing only.
    func reset() {
        _walletRepository = nil
        _epochRepository = nil
        _presenceRepository = nil
        _ephemeralCacheRepository = nil
        _epochLifecycleManager = nil
    }

    /// Registers a custom wallet repository. For testing only.
    func register(walletRepository: any WalletRepositoryProtocol) {
        _walletRepository = walletRepository
    }

    /// Registers a custom epoch repository. For testing only.
    func register(epochRepository: any EpochRepositoryProtocol) {
        _epochRepository = epochRepository
    }

    /// Registers a custom presence repository. For testing only.
    func register(presenceRepository: any PresenceRepositoryProtocol) {
        _presenceRepository = presenceRepository
    }

    /// Registers a custom ephemeral cache repository. For testing only.
    func register(ephemeralCacheRepository: any EphemeralCacheRepositoryProtocol) {
        _ephemeralCacheRepository = ephemeralCacheRepository
    }
}

// MARK: - Repository Factory Protocol

/// Factory protocol for creating repository instances.
/// Marked as `Sendable` for Swift 6 concurrency safety.
protocol RepositoryFactory: Sendable {
    func makeWalletRepository() -> any WalletRepositoryProtocol
    func makeEpochRepository() -> any EpochRepositoryProtocol
    func makePresenceRepository() -> any PresenceRepositoryProtocol
    func makeEphemeralCacheRepository() -> any EphemeralCacheRepositoryProtocol
}

// MARK: - Default Repository Factory

/// Production repository factory using mock implementations for MVP.
/// - Note: `@unchecked Sendable` is safe because configuration is immutable after init.
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

// MARK: - Mock Repository Factory

/// Test repository factory for unit testing.
/// - Note: `@unchecked Sendable` is safe because this is only used in single-threaded test contexts.
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
    /// Dependency container for accessing app-wide services.
    @Entry var dependencies: DependencyContainer = .shared
}
