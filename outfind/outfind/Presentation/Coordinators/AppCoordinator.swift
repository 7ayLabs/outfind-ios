import Foundation
import SwiftUI

// MARK: - Navigation Destination

/// Represents all possible navigation destinations in the app.
/// Conforms to `Hashable` for NavigationPath and `Identifiable` for list diffing.
enum AppDestination: Hashable, Identifiable {
    case onboarding
    case login
    case main
    case explore
    case epochDetail(epochId: UInt64)
    case activeEpoch(epochId: UInt64)

    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .login: return "login"
        case .main: return "main"
        case .explore: return "explore"
        case .epochDetail(let epochId): return "epochDetail:\(epochId)"
        case .activeEpoch(let epochId): return "activeEpoch:\(epochId)"
        }
    }
}

// MARK: - App Coordinator

/// Root coordinator managing app-level navigation and lifecycle.
///
/// ## Architecture
/// Uses the Coordinator pattern with `@Observable` for modern SwiftUI reactive state management.
/// All navigation state changes automatically trigger view updates.
///
/// ## Thread Safety
/// Marked as `@MainActor` to ensure all UI state mutations happen on the main thread.
/// The `shared` singleton uses `nonisolated(unsafe)` which is safe because:
/// - The instance is created once at app launch
/// - All mutable state access goes through @MainActor methods
@Observable
@MainActor
final class AppCoordinator {

    // MARK: - Navigation State

    /// Navigation path for programmatic navigation. Bind to NavigationStack.
    var navigationPath = NavigationPath()

    /// Current visible destination.
    private(set) var currentDestination: AppDestination = .onboarding

    /// Whether the app is performing initial setup.
    private(set) var isLoading = true

    /// Whether the user has completed onboarding (wallet connected).
    private(set) var hasCompletedOnboarding = false

    // MARK: - Shared Instance

    /// Global singleton for Environment injection.
    /// - Note: Uses `nonisolated(unsafe)` for @Entry compatibility. Safe because
    ///   initialization is deterministic and all state mutations are @MainActor isolated.
    nonisolated(unsafe) static let shared = AppCoordinator(dependencies: .shared)

    // MARK: - Dependencies

    @ObservationIgnored
    private let dependencies: DependencyContainer

    // MARK: - Background Tasks

    /// Wallet observation task. Using @ObservationIgnored since we manage lifecycle manually.
    @ObservationIgnored
    private var walletObservationTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Creates a new app coordinator.
    /// - Note: Marked `nonisolated` to allow initialization from static `shared` property.
    nonisolated init(dependencies: DependencyContainer) {
        self.dependencies = dependencies
    }

    deinit {
        walletObservationTask?.cancel()
    }

    // MARK: - Navigation

    /// Push a new destination onto the navigation stack.
    func push(_ destination: AppDestination) {
        currentDestination = destination
        navigationPath.append(destination)
    }

    /// Pop the top destination from the navigation stack.
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
        updateCurrentDestination()
    }

    /// Pop to the root of the navigation stack.
    func popToRoot() {
        navigationPath = NavigationPath()
        currentDestination = hasCompletedOnboarding ? .main : .onboarding
    }

    // MARK: - Lifecycle

    /// Performs initial app setup including cleanup and auth state check.
    func performInitialSetup() async {
        isLoading = true

        // Cleanup any stale epoch data from previous sessions
        await dependencies.epochLifecycleManager.performStartupCleanup()

        // Check authentication status (supports both wallet and Google)
        let isAuthenticated = await dependencies.authenticationRepository.isAuthenticated

        if isAuthenticated {
            hasCompletedOnboarding = true
            currentDestination = .main
        } else {
            hasCompletedOnboarding = false
            currentDestination = .onboarding
        }

        setupAuthObservation()
        setupNotificationObservers()
        isLoading = false
    }

    // MARK: - Navigation Actions

    /// Called when onboarding is completed (wallet connected).
    func completeOnboarding() {
        hasCompletedOnboarding = true
        popToRoot()
        currentDestination = .main
    }

    /// Navigate to epoch detail view.
    func showEpochDetail(epochId: UInt64) {
        push(.epochDetail(epochId: epochId))
    }

    /// Navigate to active epoch view.
    func enterActiveEpoch(epochId: UInt64) {
        push(.activeEpoch(epochId: epochId))
    }

    /// Navigate to login view from onboarding.
    func showLogin() {
        currentDestination = .login
    }

    /// Handle epoch closure by navigating away if currently viewing it.
    func handleEpochClosed(epochId: UInt64) {
        if case .activeEpoch(let activeId) = currentDestination, activeId == epochId {
            popToRoot()
        } else if case .epochDetail(let detailId) = currentDestination, detailId == epochId {
            pop()
        }
    }

    /// Handle wallet disconnection by returning to onboarding.
    func handleWalletDisconnected() {
        hasCompletedOnboarding = false
        navigationPath = NavigationPath()
        currentDestination = .onboarding
    }

    // MARK: - Private Setup

    private func setupAuthObservation() {
        walletObservationTask?.cancel()
        walletObservationTask = Task { [weak self] in
            guard let self else { return }
            for await state in dependencies.authenticationRepository.observeAuthState() {
                guard !Task.isCancelled else { break }
                await handleAuthStateChange(state)
            }
        }
    }

    /// Handles authentication state changes on the main actor.
    private func handleAuthStateChange(_ state: AuthenticationState) async {
        switch state {
        case .unauthenticated:
            handleWalletDisconnected()
        case .authenticated:
            if !hasCompletedOnboarding {
                completeOnboarding()
            }
        case .authenticating, .error:
            break
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .epochClosed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let epochId = notification.object as? UInt64 else { return }
            self?.handleEpochClosed(epochId: epochId)
        }
    }

    private func updateCurrentDestination() {
        if navigationPath.isEmpty {
            currentDestination = hasCompletedOnboarding ? .main : .onboarding
        }
    }
}

// MARK: - Epoch Lifecycle Observer

extension AppCoordinator: EpochLifecycleObserver {
    /// Called when an epoch becomes active. No action needed.
    nonisolated func epochDidActivate(_ epochId: UInt64) {}

    /// Called when an epoch closes. Navigate away if viewing this epoch.
    nonisolated func epochDidClose(_ epochId: UInt64) {
        Task { @MainActor in
            handleEpochClosed(epochId: epochId)
        }
    }

    /// Called when an epoch is finalized. Navigate away if viewing this epoch.
    nonisolated func epochDidFinalize(_ epochId: UInt64) {
        Task { @MainActor in
            handleEpochClosed(epochId: epochId)
        }
    }

    /// Called on timer tick. No action needed at coordinator level.
    nonisolated func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval) {}

    /// Called when presence updates. No action needed at coordinator level.
    nonisolated func presenceDidUpdate(_ presence: Presence, for epochId: UInt64) {}
}

// MARK: - SwiftUI Environment

extension EnvironmentValues {
    /// App coordinator for navigation and lifecycle management.
    @Entry var coordinator: AppCoordinator = .shared
}

// MARK: - View Builder

extension AppCoordinator {
    /// Creates the appropriate view for a given destination.
    @ViewBuilder
    func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .onboarding:
            OnboardingView()
        case .login:
            LoginView()
        case .main:
            MainTabView()
        case .explore:
            ExploreSection()
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        }
    }
}
