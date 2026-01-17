import SwiftUI

/// Main entry point for the Outfind iOS application
/// Initializes dependency injection and app coordination
@main
struct OutfindApp: App {

    // MARK: - Dependencies

    @StateObject private var dependencies = DependencyContainer.shared
    @StateObject private var coordinator: AppCoordinator

    // MARK: - Initialization

    init() {
        // Initialize coordinator with shared dependencies
        let container = DependencyContainer.shared
        _coordinator = StateObject(wrappedValue: AppCoordinator(dependencies: container))

        // Register coordinator as epoch lifecycle observer
        container.epochLifecycleManager.addObserver(coordinator.wrappedValue)

        configureAppearance()
    }

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
                .environmentObject(dependencies)
                .environmentObject(coordinator)
                .withDependencies(dependencies)
                .task {
                    await coordinator.performInitialSetup()
                }
        }
    }

    // MARK: - Private Methods

    private func configureAppearance() {
        // Configure global UI appearance
        // Placeholder for theme configuration
    }
}

// MARK: - Root View

/// Root view that handles loading state and navigation
private struct RootView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            if coordinator.isLoading {
                LoadingView()
            } else {
                coordinator.destinationView(for: coordinator.currentDestination)
            }
        }
        .animation(.easeInOut, value: coordinator.isLoading)
        .animation(.easeInOut, value: coordinator.currentDestination.id)
    }
}

// MARK: - Loading View

/// Initial loading view shown during app startup
private struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text("Outfind")
                .font(.largeTitle)
                .fontWeight(.bold)

            ProgressView()
                .progressViewStyle(.circular)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
