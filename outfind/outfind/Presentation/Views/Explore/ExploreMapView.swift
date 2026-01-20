import SwiftUI
import MapKit

// MARK: - Explore Map View

/// Full-screen interactive map displaying epochs as actionable markers
struct ExploreMapView: View {
    @Environment(\.coordinator) private var coordinator

    let epochs: [Epoch]
    var onViewModeToggle: (() -> Void)?

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedEpoch: Epoch?
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var selectedFilter: ExploreMapFilter = .all
    @State private var mapHasAppeared = false

    // San Francisco default location
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base map
                mapContent

                // Overlay UI
                VStack(spacing: 0) {
                    // Search bar + icons (positioned below status bar/dynamic island)
                    ExploreSearchBar(
                        searchText: $searchText,
                        onFilterTap: { showFilterSheet = true },
                        onLocationTap: { centerOnUserLocation() },
                        onViewModeTap: onViewModeToggle,
                        isMapMode: true
                    )
                    .padding(.top, geometry.safeAreaInsets.top + 4)

                    Spacer()

                    // Selected epoch callout
                    if let epoch = selectedEpoch {
                        EpochMapCallout(
                            epoch: epoch,
                            onJoin: {
                                coordinator.showEpochDetail(epochId: epoch.id)
                            },
                            onDismiss: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedEpoch = nil
                                }
                            },
                            bottomSafeArea: geometry.safeAreaInsets.bottom
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Filter chips (when no epoch selected)
                if selectedEpoch == nil {
                    VStack {
                        Spacer()
                        filterChipsRow
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 90) // Above tab bar
                    }
                }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilterSheet) {
            ExploreFilterSheet(selectedFilter: $selectedFilter)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                mapHasAppeared = true
            }
        }
        .onChange(of: selectedEpoch) { _, newValue in
            if let epoch = newValue, let coordinate = epoch.coordinate {
                withAnimation(.easeInOut(duration: 0.5)) {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            // User location with custom styling
            UserAnnotation()

            // Epoch markers
            ForEach(filteredEpochs) { epoch in
                if let coordinate = epoch.coordinate {
                    Annotation(epoch.title, coordinate: coordinate) {
                        EpochMapMarker(
                            epoch: epoch,
                            isSelected: selectedEpoch?.id == epoch.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if selectedEpoch?.id == epoch.id {
                                    selectedEpoch = nil
                                } else {
                                    selectedEpoch = epoch
                                }
                            }
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        }
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(
            elevation: .flat,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        ))
        .mapControls { }
        .onTapGesture {
            // Deselect when tapping on map
            if selectedEpoch != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedEpoch = nil
                }
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(ExploreMapFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    // MARK: - Computed Properties

    private var filteredEpochs: [Epoch] {
        var result = epochs.filter { $0.hasLocation }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.location?.name?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply state filter
        switch selectedFilter {
        case .all:
            break
        case .live:
            result = result.filter { $0.state == .active }
        case .upcoming:
            result = result.filter { $0.state == .scheduled }
        case .media:
            result = result.filter { $0.capability == .presenceWithEphemeralData }
        }

        return result
    }

    private func countForFilter(_ filter: ExploreMapFilter) -> Int {
        let base = epochs.filter { $0.hasLocation }
        switch filter {
        case .all:
            return base.count
        case .live:
            return base.filter { $0.state == .active }.count
        case .upcoming:
            return base.filter { $0.state == .scheduled }.count
        case .media:
            return base.filter { $0.capability == .presenceWithEphemeralData }.count
        }
    }

    // MARK: - Actions

    private func centerOnUserLocation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .userLocation(fallback: .region(defaultRegion))
        }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Explore Map Filter

enum ExploreMapFilter: String, CaseIterable {
    case all = "All"
    case live = "Live"
    case upcoming = "Upcoming"
    case media = "Media"

    var icon: String {
        switch self {
        case .all: return "circle.grid.3x3"
        case .live: return "dot.radiowaves.left.and.right"
        case .upcoming: return "clock"
        case .media: return "camera"
        }
    }

    var color: Color {
        switch self {
        case .all: return Theme.Colors.primaryFallback
        case .live: return Theme.Colors.epochActive
        case .upcoming: return Theme.Colors.epochScheduled
        case .media: return Theme.Colors.warning
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let filter: ExploreMapFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 12, weight: .medium))

                Text(filter.rawValue)
                    .font(.system(size: 13, weight: .medium))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : filter.color)
                }
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(filter.color)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .strokeBorder(filter.color.opacity(0.3), lineWidth: 1)
                        }
                }
            }
            .shadow(color: isSelected ? filter.color.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Explore Filter Sheet

private struct ExploreFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilter: ExploreMapFilter

    var body: some View {
        NavigationStack {
            List {
                Section("Filter by Status") {
                    ForEach(ExploreMapFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: filter.icon)
                                    .foregroundStyle(filter.color)
                                    .frame(width: 24)

                                Text(filter.rawValue)
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Spacer()

                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Theme.Colors.primaryFallback)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExploreMapView(epochs: Epoch.mockWithLocations())
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
