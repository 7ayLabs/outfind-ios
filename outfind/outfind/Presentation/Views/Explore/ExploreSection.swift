import SwiftUI

// MARK: - Explore Section

/// Map-based Explore view with interactive epoch markers
struct ExploreSection: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var isLoading = true

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ExploreMapView(epochs: epochs)
                .toolbar(.hidden, for: .navigationBar)
                .navigationBarBackButtonHidden(true)
                .navigationDestination(for: AppDestination.self) { destination in
                    destinationView(for: destination)
                }
                .task {
                    await loadEpochs()
                }
        }
    }

    // MARK: - Load Epochs

    private func loadEpochs() async {
        isLoading = true
        do {
            let fetchedEpochs = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            await MainActor.run {
                // Filter epochs with locations
                let epochsWithLocations = fetchedEpochs.filter { $0.hasLocation }

                // Use fetched epochs if they have locations, otherwise use mock data
                if epochsWithLocations.isEmpty {
                    // Always add mock data to ensure map has epochs to display
                    epochs = Epoch.mockWithLocations()
                } else {
                    // Combine fetched epochs with mock data for testing
                    epochs = epochsWithLocations + Epoch.mockWithLocations()
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                // On error, use mock data for testing
                epochs = Epoch.mockWithLocations()
                isLoading = false
            }
        }
    }

    // MARK: - Destination View

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
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

// MARK: - Preview

#Preview {
    ExploreSection()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
