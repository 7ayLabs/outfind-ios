import SwiftUI

/// Main entry point for the Outfind iOS application
/// Initializes dependency injection and app coordination
@main
struct OutfindApp: App {

    // MARK: - Dependencies

    @StateObject private var dependencies: DependencyContainer
    @StateObject private var coordinator: AppCoordinator

    // MARK: - Initialization

    init() {
        // Initialize dependencies and coordinator
        let container = DependencyContainer.shared
        let appCoordinator = AppCoordinator(dependencies: container)

        _dependencies = StateObject(wrappedValue: container)
        _coordinator = StateObject(wrappedValue: appCoordinator)
    }

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dependencies)
                .environmentObject(coordinator)
                .task {
                    // Register coordinator as lifecycle observer after view appears
                    dependencies.epochLifecycleManager.addObserver(coordinator)
                    await coordinator.performInitialSetup()
                }
        }
    }
}

// MARK: - Root View

/// Root view that handles loading state and navigation
private struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

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
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                LiquidGlassOrb(size: 100, color: Theme.Colors.primaryFallback)
                    .overlay {
                        IconView(.locationCircle, size: .xxl, color: Theme.Colors.primaryFallback)
                    }

                Text("Outfind")
                    .font(Typography.displaySmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Theme.Colors.primaryFallback)
            }
        }
    }
}
