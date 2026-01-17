import SwiftUI

// MARK: - Outfind App

@main
struct OutfindApp: App {

    // MARK: - App-Level State

    @State private var dependencies = DependencyContainer.shared
    @State private var coordinator: AppCoordinator

    // MARK: - Initialization

    init() {
        let deps = DependencyContainer.shared
        _coordinator = State(initialValue: AppCoordinator(dependencies: deps))
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator, dependencies: dependencies)
                .environment(\.dependencies, dependencies)
                .environment(\.coordinator, coordinator)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    let coordinator: AppCoordinator
    let dependencies: DependencyContainer

    var body: some View {
        Group {
            if coordinator.isLoading {
                LaunchScreen()
            } else {
                coordinator.destinationView(for: coordinator.currentDestination)
            }
        }
        .animation(.easeInOut, value: coordinator.isLoading)
        .animation(.easeInOut, value: coordinator.currentDestination.id)
        .task {
            dependencies.epochLifecycleManager.addObserver(coordinator)
            await coordinator.performInitialSetup()
        }
    }
}

// MARK: - Launch Screen

private struct LaunchScreen: View {
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

// MARK: - Preview

#Preview {
    let deps = DependencyContainer.shared
    RootView(coordinator: AppCoordinator(dependencies: deps), dependencies: deps)
        .environment(\.dependencies, deps)
        .environment(\.coordinator, AppCoordinator(dependencies: deps))
}
