import SwiftUI

// MARK: - Lapses App

@main
struct LapsesApp: App {

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
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    LiquidGlassOrb(size: 80, color: Theme.Colors.primaryFallback)
                    IconView(.locationCircle, size: .xl, color: Theme.Colors.primaryFallback)
                }

                Text("Lapses")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                scale = 1.0
                opacity = 1.0
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
