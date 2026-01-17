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
            RootView(coordinator: coordinator)
                .environment(\.dependencies, dependencies)
                .environment(\.coordinator, coordinator)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    let coordinator: AppCoordinator

    var body: some View {
        Group {
            if coordinator.isLoading {
                LaunchScreen()
            } else {
                coordinator.destinationView(for: coordinator.currentDestination)
            }
        }
        .task {
            await coordinator.performInitialSetup()
        }
    }
}

// MARK: - Launch Screen

private struct LaunchScreen: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                // Animated logo
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.5 : 1.0)

                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)

                    IconView(.locationCircle, size: .xxl, color: Theme.Colors.primaryFallback)
                }
                .animation(
                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: isAnimating
                )

                Text("Outfind")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                ProgressView()
                    .tint(Theme.Colors.primaryFallback)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview

#Preview {
    RootView(coordinator: AppCoordinator(dependencies: .shared))
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
