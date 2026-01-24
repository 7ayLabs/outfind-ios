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
    /// Safe for global access because initialization is deterministic
    /// and all state mutations are @MainActor isolated.
    static let shared = DependencyContainer()

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

    @ObservationIgnored
    private var _authenticationRepository: (any AuthenticationRepositoryProtocol)?

    @ObservationIgnored
    private var _messageRepository: (any MessageRepositoryProtocol)?

    @ObservationIgnored
    private var _nftRepository: (any NFTRepositoryProtocol)?

    @ObservationIgnored
    private var _journeyRepository: (any JourneyRepositoryProtocol)?

    @ObservationIgnored
    private var _timeCapsuleRepository: (any TimeCapsuleRepositoryProtocol)?

    @ObservationIgnored
    private var _prophecyRepository: (any ProphecyRepositoryProtocol)?

    @ObservationIgnored
    private var _postRepository: (any PostRepositoryProtocol)?

    @ObservationIgnored
    private var _predictionMarketRepository: (any PredictionMarketRepositoryProtocol)?

    @ObservationIgnored
    private var _nftGalleryRepository: (any NFTGalleryRepositoryProtocol)?

    // MARK: - Service Storage (Lazy)

    @ObservationIgnored
    private var _walletConnectService: WalletConnectServiceProtocol?

    @ObservationIgnored
    private var _googleAuthService: GoogleAuthServiceProtocol?

    // MARK: - Manager Storage (Lazy)

    @ObservationIgnored
    private var _epochLifecycleManager: EpochLifecycleManager?

    // MARK: - Factories

    @ObservationIgnored
    private let repositoryFactory: RepositoryFactory

    // MARK: - Initialization

    /// Creates a new dependency container.
    /// - Note: Marked `nonisolated` to allow initialization from static `shared` property.
    nonisolated init(
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

    var authenticationRepository: any AuthenticationRepositoryProtocol {
        if let repo = _authenticationRepository { return repo }
        let repo = repositoryFactory.makeAuthenticationRepository(
            walletConnectService: walletConnectService,
            googleAuthService: googleAuthService,
            configuration: configuration
        )
        _authenticationRepository = repo
        return repo
    }

    var messageRepository: any MessageRepositoryProtocol {
        if let repo = _messageRepository { return repo }
        let repo = repositoryFactory.makeMessageRepository()
        _messageRepository = repo
        return repo
    }

    var nftRepository: any NFTRepositoryProtocol {
        if let repo = _nftRepository { return repo }
        let repo = repositoryFactory.makeNFTRepository()
        _nftRepository = repo
        return repo
    }

    var journeyRepository: any JourneyRepositoryProtocol {
        if let repo = _journeyRepository { return repo }
        let repo = repositoryFactory.makeJourneyRepository()
        _journeyRepository = repo
        return repo
    }

    var timeCapsuleRepository: any TimeCapsuleRepositoryProtocol {
        if let repo = _timeCapsuleRepository { return repo }
        let repo = repositoryFactory.makeTimeCapsuleRepository()
        _timeCapsuleRepository = repo
        return repo
    }

    var prophecyRepository: any ProphecyRepositoryProtocol {
        if let repo = _prophecyRepository { return repo }
        let repo = repositoryFactory.makeProphecyRepository()
        _prophecyRepository = repo
        return repo
    }

    var postRepository: any PostRepositoryProtocol {
        if let repo = _postRepository { return repo }
        let repo = repositoryFactory.makePostRepository()
        _postRepository = repo
        return repo
    }

    var predictionMarketRepository: any PredictionMarketRepositoryProtocol {
        if let repo = _predictionMarketRepository { return repo }
        let repo = repositoryFactory.makePredictionMarketRepository()
        _predictionMarketRepository = repo
        return repo
    }

    var nftGalleryRepository: any NFTGalleryRepositoryProtocol {
        if let repo = _nftGalleryRepository { return repo }
        let repo = repositoryFactory.makeNFTGalleryRepository()
        _nftGalleryRepository = repo
        return repo
    }

    // MARK: - Service Access (Lazy Initialization)

    var walletConnectService: WalletConnectServiceProtocol {
        if let service = _walletConnectService { return service }
        let service = repositoryFactory.makeWalletConnectService(configuration: configuration)
        _walletConnectService = service
        return service
    }

    var googleAuthService: GoogleAuthServiceProtocol {
        if let service = _googleAuthService { return service }
        let service = repositoryFactory.makeGoogleAuthService(configuration: configuration)
        _googleAuthService = service
        return service
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
        _authenticationRepository = nil
        _messageRepository = nil
        _nftRepository = nil
        _journeyRepository = nil
        _timeCapsuleRepository = nil
        _prophecyRepository = nil
        _postRepository = nil
        _predictionMarketRepository = nil
        _nftGalleryRepository = nil
        _walletConnectService = nil
        _googleAuthService = nil
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

    /// Registers a custom authentication repository. For testing only.
    func register(authenticationRepository: any AuthenticationRepositoryProtocol) {
        _authenticationRepository = authenticationRepository
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
    func makeAuthenticationRepository(
        walletConnectService: WalletConnectServiceProtocol,
        googleAuthService: GoogleAuthServiceProtocol,
        configuration: ConfigurationProtocol
    ) -> any AuthenticationRepositoryProtocol
    func makeMessageRepository() -> any MessageRepositoryProtocol
    func makeNFTRepository() -> any NFTRepositoryProtocol
    func makeJourneyRepository() -> any JourneyRepositoryProtocol
    func makeTimeCapsuleRepository() -> any TimeCapsuleRepositoryProtocol
    func makeProphecyRepository() -> any ProphecyRepositoryProtocol
    func makePostRepository() -> any PostRepositoryProtocol
    func makePredictionMarketRepository() -> any PredictionMarketRepositoryProtocol
    func makeNFTGalleryRepository() -> any NFTGalleryRepositoryProtocol
    func makeWalletConnectService(configuration: ConfigurationProtocol) -> WalletConnectServiceProtocol
    func makeGoogleAuthService(configuration: ConfigurationProtocol) -> GoogleAuthServiceProtocol
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

    func makeAuthenticationRepository(
        walletConnectService: WalletConnectServiceProtocol,
        googleAuthService: GoogleAuthServiceProtocol,
        configuration: ConfigurationProtocol
    ) -> any AuthenticationRepositoryProtocol {
        // Use mock for MVP, swap to real implementation when WalletConnect SDK is integrated
        MockAuthenticationRepository()
    }

    func makeMessageRepository() -> any MessageRepositoryProtocol {
        MockMessageRepository()
    }

    func makeNFTRepository() -> any NFTRepositoryProtocol {
        MockNFTRepository()
    }

    func makeJourneyRepository() -> any JourneyRepositoryProtocol {
        MockJourneyRepository()
    }

    func makeTimeCapsuleRepository() -> any TimeCapsuleRepositoryProtocol {
        MockTimeCapsuleRepository()
    }

    func makeProphecyRepository() -> any ProphecyRepositoryProtocol {
        MockProphecyRepository()
    }

    func makePostRepository() -> any PostRepositoryProtocol {
        MockPostRepository()
    }

    func makePredictionMarketRepository() -> any PredictionMarketRepositoryProtocol {
        MockPredictionMarketRepository()
    }

    func makeNFTGalleryRepository() -> any NFTGalleryRepositoryProtocol {
        MockNFTGalleryRepository()
    }

    func makeWalletConnectService(configuration: ConfigurationProtocol) -> WalletConnectServiceProtocol {
        WalletConnectService(configuration: configuration)
    }

    func makeGoogleAuthService(configuration: ConfigurationProtocol) -> GoogleAuthServiceProtocol {
        GoogleAuthService(configuration: configuration)
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
    var authenticationRepository: (any AuthenticationRepositoryProtocol)?
    var messageRepository: (any MessageRepositoryProtocol)?
    var nftRepository: (any NFTRepositoryProtocol)?
    var journeyRepository: (any JourneyRepositoryProtocol)?
    var timeCapsuleRepository: (any TimeCapsuleRepositoryProtocol)?
    var prophecyRepository: (any ProphecyRepositoryProtocol)?
    var postRepository: (any PostRepositoryProtocol)?
    var predictionMarketRepository: (any PredictionMarketRepositoryProtocol)?
    var nftGalleryRepository: (any NFTGalleryRepositoryProtocol)?

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

    func makeAuthenticationRepository(
        walletConnectService: WalletConnectServiceProtocol,
        googleAuthService: GoogleAuthServiceProtocol,
        configuration: ConfigurationProtocol
    ) -> any AuthenticationRepositoryProtocol {
        authenticationRepository ?? MockAuthenticationRepository()
    }

    func makeMessageRepository() -> any MessageRepositoryProtocol {
        messageRepository ?? MockMessageRepository()
    }

    func makeNFTRepository() -> any NFTRepositoryProtocol {
        nftRepository ?? MockNFTRepository()
    }

    func makeJourneyRepository() -> any JourneyRepositoryProtocol {
        journeyRepository ?? MockJourneyRepository()
    }

    func makeTimeCapsuleRepository() -> any TimeCapsuleRepositoryProtocol {
        timeCapsuleRepository ?? MockTimeCapsuleRepository()
    }

    func makeProphecyRepository() -> any ProphecyRepositoryProtocol {
        prophecyRepository ?? MockProphecyRepository()
    }

    func makePostRepository() -> any PostRepositoryProtocol {
        postRepository ?? MockPostRepository()
    }

    func makePredictionMarketRepository() -> any PredictionMarketRepositoryProtocol {
        predictionMarketRepository ?? MockPredictionMarketRepository()
    }

    func makeNFTGalleryRepository() -> any NFTGalleryRepositoryProtocol {
        nftGalleryRepository ?? MockNFTGalleryRepository()
    }

    func makeWalletConnectService(configuration: ConfigurationProtocol) -> WalletConnectServiceProtocol {
        WalletConnectService(configuration: configuration)
    }

    func makeGoogleAuthService(configuration: ConfigurationProtocol) -> GoogleAuthServiceProtocol {
        GoogleAuthService(configuration: configuration)
    }
}

// MARK: - SwiftUI Environment

extension EnvironmentValues {
    /// Dependency container for accessing app-wide services.
    @Entry var dependencies: DependencyContainer = .shared
}
