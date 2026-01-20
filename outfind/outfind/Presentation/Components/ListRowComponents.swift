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

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(MockUser.mockUsers) { user in
                HStack {
                    AsyncImage(url: user.avatarURL) { image in
                        image.resizable()
                    } placeholder: {
                        Circle().fill(Theme.Colors.backgroundTertiary)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(user.name)
                        Text(user.status.rawValue)
                            .foregroundStyle(user.status.color)
                    }
                }
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
