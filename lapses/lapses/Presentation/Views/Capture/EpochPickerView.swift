import SwiftUI

// MARK: - Epoch Picker View

/// Clean modal for selecting an epoch
/// Native iOS list style with search
struct EpochPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var appeared = false
    @State private var selectedId: UInt64?

    let mode: PickerMode
    let onSelect: (UInt64) -> Void
    let onCreateNew: () -> Void
    let onCancel: () -> Void

    enum PickerMode {
        case enterEpoch
        case sendEphemeral

        var title: String {
            switch self {
            case .enterEpoch: return "Select Epoch"
            case .sendEphemeral: return "Send To"
            }
        }
    }

    private var filteredEpochs: [Epoch] {
        if searchText.isEmpty { return epochs }
        return epochs.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if epochs.isEmpty {
                    emptyView
                } else {
                    epochList
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        RadialHaptics.shared.dismiss()
                        onCancel()
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search epochs"
            )
            .accessibilityIdentifier("EpochPickerView")
        }
        .task {
            await loadEpochs()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading epochs...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Epochs", systemImage: "mappin.circle")
        } description: {
            Text("No active epochs nearby")
        } actions: {
            Button {
                RadialHaptics.shared.selectionMade()
                onCreateNew()
            } label: {
                Label("Create New", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.primaryFallback)
        }
    }

    // MARK: - List

    private var epochList: some View {
        List {
            // Create New section
            Section {
                Button {
                    RadialHaptics.shared.selectionMade()
                    onCreateNew()
                } label: {
                    Label {
                        Text("Create New Epoch")
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                }
                .accessibilityIdentifier("EpochPicker_CreateNew")
            }

            // Epochs section
            Section {
                ForEach(filteredEpochs) { epoch in
                    epochRow(epoch)
                }
            } header: {
                if !filteredEpochs.isEmpty {
                    Text("Nearby")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Epoch Row

    private func epochRow(_ epoch: Epoch) -> some View {
        Button {
            RadialHaptics.shared.selectionMade()
            withAnimation(.easeOut(duration: 0.1)) {
                selectedId = epoch.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onSelect(epoch.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(stateColor(epoch.state).opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(stateColor(epoch.state))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(epoch.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if epoch.state == .active {
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.Colors.textOnAccent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.epochActive, in: Capsule())
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(epoch.participantCount) participants")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedId == epoch.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedId == epoch.id ? Color.gray.opacity(0.1) : nil)
    }

    private func stateColor(_ state: EpochState) -> Color {
        switch state {
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        default: return Theme.Colors.textSecondary
        }
    }

    // MARK: - Load

    private func loadEpochs() async {
        do {
            let all = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            let active = all.filter { $0.state == .active || $0.state == .scheduled }

            await MainActor.run {
                epochs = active.sorted { lhs, rhs in
                    if lhs.state == .active && rhs.state != .active { return true }
                    if rhs.state == .active && lhs.state != .active { return false }
                    return lhs.startTime < rhs.startTime
                }
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Preview

#Preview {
    EpochPickerView(
        mode: .enterEpoch,
        onSelect: { _ in },
        onCreateNew: {},
        onCancel: {}
    )
    .environment(\.dependencies, .shared)
}
