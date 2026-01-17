import Foundation
import SwiftUI

// MARK: - Navigation Destination

enum AppDestination: Hashable, Identifiable {
    case onboarding
    case explore
    case epochDetail(epochId: UInt64)
    case activeEpoch(epochId: UInt64)

    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .explore: return "explore"
        case .epochDetail(let epochId): return "epochDetail:\(epochId)"
        case .activeEpoch(let epochId): return "activeEpoch:\(epochId)"
        }
    }
}

// MARK: - App Coordinator

/// Root coordinator managing app-level navigation and lifecycle
/// Uses @Observable for modern SwiftUI reactive state management
@Observable
@MainActor
final class AppCoordinator {

    // MARK: - Navigation State

    var navigationPath = NavigationPath()
    private(set) var currentDestination: AppDestination = .onboarding
    private(set) var isLoading = true
    private(set) var hasCompletedOnboarding = false

    // MARK: - Dependencies

    private let dependencies: DependencyContainer

    // MARK: - Tasks

    private var walletObservationTask: Task<Void, Never>?

    // MARK: - Initialization

    init(dependencies: DependencyContainer) {
        self.dependencies = dependencies
    }

    deinit {
        walletObservationTask?.cancel()
    }

    // MARK: - Navigation

    func push(_ destination: AppDestination) {
        currentDestination = destination
        navigationPath.append(destination)
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
        updateCurrentDestination()
    }

    func popToRoot() {
        navigationPath = NavigationPath()
        currentDestination = hasCompletedOnboarding ? .explore : .onboarding
    }

    // MARK: - Lifecycle

    func performInitialSetup() async {
        isLoading = true

        await dependencies.epochLifecycleManager.performStartupCleanup()

        let wallet = await dependencies.walletRepository.currentWallet

        if wallet != nil {
            hasCompletedOnboarding = true
            currentDestination = .explore
        } else {
            hasCompletedOnboarding = false
            currentDestination = .onboarding
        }

        setupWalletObservation()
        setupNotificationObservers()
        isLoading = false
    }

    // MARK: - Actions

    func completeOnboarding() {
        hasCompletedOnboarding = true
        popToRoot()
        currentDestination = .explore
    }

    func showEpochDetail(epochId: UInt64) {
        push(.epochDetail(epochId: epochId))
    }

    func enterActiveEpoch(epochId: UInt64) {
        push(.activeEpoch(epochId: epochId))
    }

    func handleEpochClosed(epochId: UInt64) {
        if case .activeEpoch(let activeId) = currentDestination, activeId == epochId {
            popToRoot()
        } else if case .epochDetail(let detailId) = currentDestination, detailId == epochId {
            pop()
        }
    }

    func handleWalletDisconnected() {
        hasCompletedOnboarding = false
        popToRoot()
        currentDestination = .onboarding
    }

    // MARK: - Private

    private func setupWalletObservation() {
        walletObservationTask?.cancel()
        walletObservationTask = Task { [weak self] in
            guard let self else { return }
            for await state in dependencies.walletRepository.observeWalletState() {
                switch state {
                case .disconnected:
                    await MainActor.run { self.handleWalletDisconnected() }
                case .connected:
                    if !self.hasCompletedOnboarding {
                        await MainActor.run { self.completeOnboarding() }
                    }
                case .connecting, .error:
                    break
                }
            }
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
            currentDestination = hasCompletedOnboarding ? .explore : .onboarding
        }
    }
}

// MARK: - Epoch Lifecycle Observer

extension AppCoordinator: EpochLifecycleObserver {
    nonisolated func epochDidActivate(_ epochId: UInt64) {}

    nonisolated func epochDidClose(_ epochId: UInt64) {
        Task { @MainActor in handleEpochClosed(epochId: epochId) }
    }

    nonisolated func epochDidFinalize(_ epochId: UInt64) {
        Task { @MainActor in handleEpochClosed(epochId: epochId) }
    }

    nonisolated func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval) {}

    nonisolated func presenceDidUpdate(_ presence: Presence, for epochId: UInt64) {}
}

// MARK: - SwiftUI Environment

extension EnvironmentValues {
    @Entry var coordinator: AppCoordinator = AppCoordinator(dependencies: .shared)
}

// MARK: - View Builder

extension AppCoordinator {
    @ViewBuilder
    func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .onboarding:
            OnboardingView()
        case .explore:
            ExploreView()
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        }
    }
}
