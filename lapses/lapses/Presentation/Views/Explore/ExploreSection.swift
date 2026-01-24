import SwiftUI

// MARK: - Explore Section

/// Explore view with category tabs for NFTs and Predictions
struct ExploreSection: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // UI state
    @State private var searchText = ""
    @State private var tilesAppeared = false

    // Category selection
    @State private var selectedCategory: ExploreCategory = .lapsers

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar as header
                    searchBar
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.xl)

                    // Category tabs
                    ExploreCategoryTabs(selectedCategory: $selectedCategory)
                        .padding(.top, Theme.Spacing.md)

                    // Content based on selected category
                    switch selectedCategory {
                    case .lapsers:
                        LapsersExploreSection()
                    case .predictions:
                        PredictionsExploreSection()
                    case .journeys:
                        JourneysExploreSection()
                    case .nfts:
                        NFTsExploreSection()
                    case .leaderboard:
                        LeaderboardExploreSection()
                    }

                    Spacer(minLength: 120)
                }
            }
            .background(Theme.Colors.background)
            .scrollIndicators(.hidden)
            .navigationBarHidden(true)
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .onAppear {
                if reduceMotion {
                    tilesAppeared = true
                } else {
                    withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                        tilesAppeared = true
                    }
                }
            }
        }
    }
}


// MARK: - Search Bar

extension ExploreSection {
    fileprivate var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("Search NFTs, predictions, journeys...", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.textPrimary)

            if !searchText.isEmpty {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.backgroundSecondary)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 8, y: 4)
        }
    }
}


// MARK: - Navigation

extension ExploreSection {
    @ViewBuilder
    fileprivate func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        default:
            EmptyView()
        }
    }
}


// MARK: - Custom Button Styles

struct ExploreCardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive && !reduceMotion {
                    LinearGradient(
                        colors: [
                            .clear,
                            Theme.Colors.textTertiary.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase)
                    .onAppear {
                        guard !reduceMotion else { return }
                        isAnimating = true
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 200
                        }
                    }
                    .onDisappear {
                        isAnimating = false
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

extension View {
    func shimmer(isActive: Bool) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Preview

#Preview {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}

#Preview("Dark Mode") {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
        .preferredColorScheme(.dark)
}
