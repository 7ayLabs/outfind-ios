import SwiftUI

// MARK: - User Status

enum UserStatus: String, CaseIterable {
    case online = "Online"
    case around = "Around"
    case offline = "Offline"

    var color: Color {
        switch self {
        case .online: return Theme.Colors.success
        case .around: return Theme.Colors.warning
        case .offline: return Theme.Colors.textTertiary
        }
    }

    var icon: String {
        switch self {
        case .online: return "circle.fill"
        case .around: return "circle.dashed"
        case .offline: return "circle"
        }
    }
}

// MARK: - Mock User

struct MockUser: Identifiable {
    let id = UUID()
    let name: String
    let avatarURL: URL?
    let status: UserStatus

    static let mockUsers: [MockUser] = [
        MockUser(
            name: "Alex Chen",
            avatarURL: URL(string: "https://i.pravatar.cc/100?img=11"),
            status: .online
        ),
        MockUser(
            name: "Sarah Miller",
            avatarURL: URL(string: "https://i.pravatar.cc/100?img=12"),
            status: .online
        ),
        MockUser(
            name: "James Wilson",
            avatarURL: URL(string: "https://i.pravatar.cc/100?img=13"),
            status: .around
        ),
        MockUser(
            name: "Emily Davis",
            avatarURL: URL(string: "https://i.pravatar.cc/100?img=14"),
            status: .around
        ),
        MockUser(
            name: "Michael Brown",
            avatarURL: URL(string: "https://i.pravatar.cc/100?img=15"),
            status: .offline
        )
    ]
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(color)
            }
    }
}

// MARK: - Epoch List Row

struct EpochListRow: View {
    let epoch: Epoch
    let onJoin: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Epoch icon/avatar
            ZStack {
                Circle()
                    .fill(epochColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: epochIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(epochColor)
            }

            // Info section
            VStack(alignment: .leading, spacing: 4) {
                // Status badge
                StatusBadge(
                    text: epoch.state == .active ? "LIVE" : epoch.state.displayName,
                    color: epochColor
                )

                // Title
                Text(epoch.title)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                // Participant count
                Text("\(epoch.participantCount) participants")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            // Join button
            Button(action: onJoin) {
                Text("JOIN")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.primaryFallback)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }

    private var epochColor: Color {
        switch epoch.state {
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        case .none: return Theme.Colors.textTertiary
        }
    }

    private var epochIcon: String {
        switch epoch.state {
        case .active: return "dot.radiowaves.left.and.right"
        case .scheduled: return "clock"
        case .closed: return "xmark.circle"
        case .finalized: return "checkmark.seal"
        case .none: return "circle.dashed"
        }
    }
}

// MARK: - User List Row

struct UserListRow: View {
    let user: MockUser
    var onHere: (() -> Void)? = nil
    var onCall: (() -> Void)? = nil
    var onWave: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Avatar
            AsyncImage(url: user.avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Circle()
                        .fill(Theme.Colors.backgroundTertiary)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(user.status.color, lineWidth: 2)
            }

            // Info section
            VStack(alignment: .leading, spacing: 4) {
                // Status indicator
                HStack(spacing: 4) {
                    Image(systemName: user.status.icon)
                        .font(.system(size: 8))
                        .foregroundStyle(user.status.color)

                    Text(user.status.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(user.status.color)
                }

                // Name
                Text(user.name)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)
            }

            Spacer()

            // Action buttons
            HStack(spacing: Theme.Spacing.xs) {
                if user.status == .online, let onHere = onHere {
                    Button(action: onHere) {
                        Text("HERE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(Theme.Colors.success)
                            }
                    }
                    .buttonStyle(.plain)
                } else {
                    // Call button
                    if let onCall = onCall {
                        Button(action: onCall) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.Colors.primaryFallback)
                                .frame(width: 36, height: 36)
                                .background {
                                    Circle()
                                        .fill(Theme.Colors.primaryFallback.opacity(0.15))
                                }
                        }
                        .buttonStyle(.plain)
                    }

                    // Wave button
                    if let onWave = onWave {
                        Button(action: onWave) {
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.Colors.warning)
                                .frame(width: 36, height: 36)
                                .background {
                                    Circle()
                                        .fill(Theme.Colors.warning.opacity(0.15))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.backgroundSecondary)
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(1)

            Spacer()

            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            SectionHeader(title: "Epochs", actionTitle: "See All") {}

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Epoch.mockWithLocations().prefix(2)) { epoch in
                    EpochListRow(epoch: epoch) {}
                }
            }
            .padding(.horizontal, Theme.Spacing.md)

            SectionHeader(title: "People Nearby")

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(MockUser.mockUsers) { user in
                    UserListRow(
                        user: user,
                        onHere: user.status == .online ? {} : nil,
                        onCall: user.status != .online ? {} : nil,
                        onWave: user.status != .online ? {} : nil
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.md)
    }
    .background(Theme.Colors.background)
}
