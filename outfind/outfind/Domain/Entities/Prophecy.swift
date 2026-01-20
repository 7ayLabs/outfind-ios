import Foundation

// MARK: - Prophecy

/// Represents a commitment to attend a future epoch
/// Users stake their reputation by making prophecies
struct Prophecy: Identifiable, Codable, Sendable {
    let id: String
    let userId: String
    let epochId: UInt64
    let committedAt: Date
    let stakeAmount: Double
    var status: ProphecyStatus

    /// Display name for the user (populated from user lookup)
    var userDisplayName: String?

    /// Avatar URL for the user (populated from user lookup)
    var userAvatarURL: URL?

    /// The epoch title (populated from epoch lookup)
    var epochTitle: String?
}

// MARK: - Prophecy Status

enum ProphecyStatus: String, Codable, Sendable {
    case pending     // Epoch hasn't started yet
    case fulfilled   // User attended the epoch
    case broken      // User didn't attend

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .fulfilled: return "Fulfilled"
        case .broken: return "Broken"
        }
    }

    var iconName: String {
        switch self {
        case .pending: return "clock.fill"
        case .fulfilled: return "checkmark.seal.fill"
        case .broken: return "xmark.seal.fill"
        }
    }
}

// MARK: - Factory Methods

extension Prophecy {
    static func mock(
        id: String = UUID().uuidString,
        userId: String = "user-1",
        epochId: UInt64 = 1,
        status: ProphecyStatus = .pending,
        stakeAmount: Double = 10.0
    ) -> Prophecy {
        Prophecy(
            id: id,
            userId: userId,
            epochId: epochId,
            committedAt: Date().addingTimeInterval(-86400),
            stakeAmount: stakeAmount,
            status: status,
            userDisplayName: "John Doe",
            userAvatarURL: nil,
            epochTitle: "Tech Meetup 2026"
        )
    }

    static func mockProphecies() -> [Prophecy] {
        [
            Prophecy(
                id: "prophecy-1",
                userId: "user-1",
                epochId: 2,
                committedAt: Date().addingTimeInterval(-86400 * 2),
                stakeAmount: 10.0,
                status: .pending,
                userDisplayName: "Alice",
                userAvatarURL: nil,
                epochTitle: "Web3 Hackathon"
            ),
            Prophecy(
                id: "prophecy-2",
                userId: "user-2",
                epochId: 2,
                committedAt: Date().addingTimeInterval(-86400 * 3),
                stakeAmount: 25.0,
                status: .pending,
                userDisplayName: "Bob",
                userAvatarURL: nil,
                epochTitle: "Web3 Hackathon"
            ),
            Prophecy(
                id: "prophecy-3",
                userId: "user-3",
                epochId: 1,
                committedAt: Date().addingTimeInterval(-86400 * 5),
                stakeAmount: 15.0,
                status: .fulfilled,
                userDisplayName: "Charlie",
                userAvatarURL: nil,
                epochTitle: "Crypto Meetup SF"
            ),
            Prophecy(
                id: "prophecy-4",
                userId: "user-4",
                epochId: 3,
                committedAt: Date().addingTimeInterval(-86400),
                stakeAmount: 5.0,
                status: .pending,
                userDisplayName: "Diana",
                userAvatarURL: nil,
                epochTitle: "ETH Denver Afterparty"
            ),
            Prophecy(
                id: "prophecy-5",
                userId: "user-1",
                epochId: 4,
                committedAt: Date().addingTimeInterval(-86400 * 7),
                stakeAmount: 20.0,
                status: .broken,
                userDisplayName: "Alice",
                userAvatarURL: nil,
                epochTitle: "DeFi Summit"
            )
        ]
    }
}
