import SwiftUI

// MARK: - All Epochs List Section

/// Vertical list section showing all nearby epochs with Join buttons.
/// Design inspired by "All group near you" list in reference images.
struct AllEpochsListSection: View {
    let epochs: [Epoch]
    let joinedEpochIds: Set<UInt64>
    let onEpochTap: (UInt64) -> Void
    let onJoin: (UInt64) -> Void
    let onFilter: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with filter
            SectionHeader.withFilter("All epochs near you") {
                onFilter()
            }

            // Epoch list
            VStack(spacing: 0) {
                ForEach(epochs) { epoch in
                    EpochListRow(
                        epoch: epoch,
                        isJoined: joinedEpochIds.contains(epoch.id),
                        onTap: { onEpochTap(epoch.id) },
                        onJoin: { onJoin(epoch.id) }
                    )

                    // Divider (except for last item)
                    if epoch.id != epochs.last?.id {
                        Divider()
                            .padding(.leading, 72) // Align with text, not avatar
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}

// MARK: - Epoch List Row

/// Single row in the epochs list with avatar, info, and Join button.
struct EpochListRow: View {
    let epoch: Epoch
    let isJoined: Bool
    let onTap: () -> Void
    let onJoin: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Avatar/Icon
                epochAvatar

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(epoch.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.xxs) {
                        Text("\(epoch.participantCount) Members")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Text("·")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.textTertiary)

                        if let locationName = epoch.location?.name {
                            Text(locationName)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .lineLimit(1)
                        } else {
                            Text("Nearby")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                }

                Spacer()

                // Join Button
                joinButton
            }
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avatar

    private var epochAvatar: some View {
        ZStack {
            Circle()
                .fill(avatarGradient)
                .frame(width: 48, height: 48)

            // First letter of title
            Text(String(epoch.title.prefix(1)).uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.Colors.textOnAccent)
        }
    }

    private var avatarGradient: LinearGradient {
        let colorSets: [[Color]] = [
            [Color(hex: "667eea"), Color(hex: "764ba2")],
            [Color(hex: "f093fb"), Color(hex: "f5576c")],
            [Color(hex: "4facfe"), Color(hex: "00f2fe")],
            [Color(hex: "43e97b"), Color(hex: "38f9d7")],
            [Color(hex: "fa709a"), Color(hex: "fee140")],
        ]
        let colors = colorSets[Int(epoch.id) % colorSets.count]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Join Button

    private var joinButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onJoin()
        } label: {
            Text(isJoined ? "Joined" : "Join")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isJoined ? Theme.Colors.textSecondary : Theme.Colors.textOnAccent)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background {
                    Capsule()
                        .fill(isJoined ? Color.clear : Theme.Colors.info)
                }
                .overlay {
                    if isJoined {
                        Capsule()
                            .strokeBorder(Theme.Colors.textTertiary, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            AllEpochsListSection(
                epochs: Epoch.mockWithLocations(),
                joinedEpochIds: [2, 4],
                onEpochTap: { id in print("Tapped epoch \(id)") },
                onJoin: { id in print("Join epoch \(id)") },
                onFilter: { print("Filter") }
            )
        }
        .padding(.vertical, Theme.Spacing.lg)
    }
    .background(Theme.Colors.background)
}
