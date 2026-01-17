import Foundation
import SwiftUI
import Combine

// MARK: - Navigation Destination

/// Top-level navigation destinations in the app
enum AppDestination: Hashable, Identifiable {
    case onboarding
    case explore
    case epochDetail(epochId: UInt64)
    case activeEpoch(epochId: UInt64)

    var id: String {
        switch self {
        case .onboarding:
            return "onboarding"
        case .explore:
            return "explore"
        case .epochDetail(let epochId):
            return "epochDetail:\(epochId)"
        case .activeEpoch(let epochId):
            return "activeEpoch:\(epochId)"
        }
    }
}

// MARK: - Coordinator Protocol

/// Base coordinator protocol for navigation management
protocol Coordinator: AnyObject {
    associatedtype Destination: Hashable

    var navigationPath: NavigationPath { get set }

    func push(_ destination: Destination)
    func pop()
    func popToRoot()
}

// MARK: - App Coordinator

/// Root coordinator managing app-level navigation and lifecycle
/// Implements the Coordinator pattern for decoupled navigation
@MainActor
final class AppCoordinator: ObservableObject, Coordinator {
    typealias Destination = AppDestination

    // MARK: - Published State

    @Published var navigationPath = NavigationPath()
    @Published private(set) var currentDestination: AppDestination = .onboarding
    @Published private(set) var isLoading = true
    @Published private(set) var hasCompletedOnboarding = false

    // MARK: - Dependencies

    private let dependencies: DependencyContainer
    private let lifecycleManager: EpochLifecycleManager

    // MARK: - Observers

    private var cancellables = Set<AnyCancellable>()
    private var walletObservationTask: Task<Void, Never>?

    // MARK: - Initialization

    init(dependencies: DependencyContainer) {
        self.dependencies = dependencies
        self.lifecycleManager = dependencies.epochLifecycleManager

        setupObservers()
    }

    deinit {
        walletObservationTask?.cancel()
    }

    // MARK: - Coordinator Methods

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

    // MARK: - App Lifecycle

    /// Perform initial app setup and determine starting destination
    func performInitialSetup() async {
        isLoading = true

        // Perform epoch lifecycle cleanup (INV14 enforcement)
        await lifecycleManager.performStartupCleanup()

        // Check wallet connection state
        let wallet = await dependencies.walletRepository.currentWallet

        await MainActor.run {
            if wallet != nil {
                hasCompletedOnboarding = true
                currentDestination = .explore
            } else {
                hasCompletedOnboarding = false
                currentDestination = .onboarding
            }
            isLoading = false
        }
    }

    // MARK: - Navigation Actions

    /// Navigate to explore after successful onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        popToRoot()
        currentDestination = .explore
    }

    /// Navigate to epoch detail view
    func showEpochDetail(epochId: UInt64) {
        push(.epochDetail(epochId: epochId))
    }

    /// Navigate to active epoch view (after joining)
    func enterActiveEpoch(epochId: UInt64) {
        push(.activeEpoch(epochId: epochId))
    }

    /// Handle epoch close - return to explore
    func handleEpochClosed(epochId: UInt64) {
        // Pop back to root if we were in the closed epoch
        if case .activeEpoch(let activeId) = currentDestination, activeId == epochId {
            popToRoot()
        } else if case .epochDetail(let detailId) = currentDestination, detailId == epochId {
            pop()
        }
    }

    /// Handle wallet disconnection
    func handleWalletDisconnected() {
        hasCompletedOnboarding = false
        popToRoot()
        currentDestination = .onboarding
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe epoch lifecycle events
        NotificationCenter.default.publisher(for: .epochClosed)
            .compactMap { $0.object as? UInt64 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] epochId in
                self?.handleEpochClosed(epochId: epochId)
            }
            .store(in: &cancellables)

        // Observe wallet state
        walletObservationTask = Task { [weak self] in
            guard let self = self else { return }
            for await state in self.dependencies.walletRepository.observeWalletState() {
                await MainActor.run {
                    switch state {
                    case .disconnected:
                        self.handleWalletDisconnected()
                    case .connected:
                        if !self.hasCompletedOnboarding {
                            self.completeOnboarding()
                        }
                    case .connecting, .error:
                        break
                    }
                }
            }
        }
    }

    private func updateCurrentDestination() {
        // Update current destination based on navigation path
        // For MVP, we just track the root destinations
        if navigationPath.isEmpty {
            currentDestination = hasCompletedOnboarding ? .explore : .onboarding
        }
    }
}

// MARK: - Epoch Lifecycle Observer Conformance

extension AppCoordinator: EpochLifecycleObserver {
    nonisolated func epochDidActivate(_ epochId: UInt64) {
        // Handled via lifecycle manager
    }

    nonisolated func epochDidClose(_ epochId: UInt64) {
        Task { @MainActor in
            handleEpochClosed(epochId: epochId)
        }
    }

    nonisolated func epochDidFinalize(_ epochId: UInt64) {
        Task { @MainActor in
            handleEpochClosed(epochId: epochId)
        }
    }

    nonisolated func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval) {
        // UI handles timer display
    }

    nonisolated func presenceDidUpdate(_ presence: Presence, for epochId: UInt64) {
        // UI handles presence state display
    }
}

// MARK: - Coordinator View Builder

extension AppCoordinator {
    /// Build the destination view for navigation
    @ViewBuilder
    func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .onboarding:
            // Placeholder - will be implemented in Presentation layer
            OnboardingPlaceholderView(coordinator: self)

        case .explore:
            // Placeholder - will be implemented in Presentation layer
            ExplorePlaceholderView(coordinator: self)

        case .epochDetail(let epochId):
            // Placeholder - will be implemented in Presentation layer
            EpochDetailPlaceholderView(epochId: epochId, coordinator: self)

        case .activeEpoch(let epochId):
            // Placeholder - will be implemented in Presentation layer
            ActiveEpochPlaceholderView(epochId: epochId, coordinator: self)
        }
    }
}

// MARK: - Placeholder Views (MVP 1 Scaffolding)

/// Temporary onboarding view - to be replaced with actual implementation
private struct OnboardingPlaceholderView: View {
    let coordinator: AppCoordinator

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Welcome to Outfind")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Connect your wallet to get started")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Connect Wallet") {
                Task {
                    do {
                        _ = try await coordinator.dependencies.walletRepository.connect()
                        coordinator.completeOnboarding()
                    } catch {
                        // Error handling will be improved in MVP 2
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

/// Temporary explore view - to be replaced with actual implementation
private struct ExplorePlaceholderView: View {
    let coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: Binding(
            get: { coordinator.navigationPath },
            set: { coordinator.navigationPath = $0 }
        )) {
            VStack(spacing: 24) {
                Image(systemName: "mappin.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)

                Text("Explore Epochs")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Discover nearby epochs and join communities")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Sample epoch cards
                ForEach([1, 2, 3] as [UInt64], id: \.self) { epochId in
                    Button {
                        coordinator.showEpochDetail(epochId: epochId)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Epoch \(epochId)")
                                    .font(.headline)
                                Text("Active")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Explore")
            .navigationDestination(for: AppDestination.self) { destination in
                coordinator.destinationView(for: destination)
            }
        }
    }
}

/// Temporary epoch detail view - to be replaced with actual implementation
private struct EpochDetailPlaceholderView: View {
    let epochId: UInt64
    let coordinator: AppCoordinator

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.circle")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Epoch \(epochId)")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("View epoch details and join to participate")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Join Epoch") {
                coordinator.enterActiveEpoch(epochId: epochId)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .navigationTitle("Epoch Details")
    }
}

/// Temporary active epoch view - to be replaced with actual implementation
private struct ActiveEpochPlaceholderView: View {
    let epochId: UInt64
    let coordinator: AppCoordinator

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundStyle(.purple)

            Text("Active in Epoch \(epochId)")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You are now participating in this epoch")
                .font(.body)
                .foregroundStyle(.secondary)

            // Placeholder for epoch features
            HStack(spacing: 16) {
                FeatureButton(icon: "person.2", title: "Discover")
                FeatureButton(icon: "bubble.left.and.bubble.right", title: "Chat")
                FeatureButton(icon: "camera", title: "Media")
            }

            Spacer()

            Button("Leave Epoch") {
                coordinator.pop()
            }
            .foregroundStyle(.red)
        }
        .padding()
        .navigationTitle("Active Epoch")
    }
}

/// Simple feature button component
private struct FeatureButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption)
        }
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
