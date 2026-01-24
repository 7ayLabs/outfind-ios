
import Foundation

// MARK: - Profile Data

/// Aggregated profile data for display in ProfileSheetView
struct ProfileData: Sendable {
    let user: User
    var followerCount: Int
    var followingCount: Int
    var addressCount: Int
    var isFollowing: Bool
    var epochTags: [EpochTag]
    var mutualFollowers: [MutualFollower]
    var epochs: [EpochNFT]
    var lapses: [LapseItem]
}

// MARK: - Epoch Tag

/// Tag representing a popular/featured epoch the user participated in
struct EpochTag: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let name: String
    let participantCount: Int

    init(id: UUID = UUID(), name: String, participantCount: Int) {
        self.id = id
        self.name = name
        self.participantCount = participantCount
    }
}

// MARK: - Mutual Follower

/// A user who follows both the viewer and the profile owner
struct MutualFollower: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let avatarURL: URL?

    init(id: String = UUID().uuidString, name: String, avatarURL: URL? = nil) {
        self.id = id
        self.name = name
        self.avatarURL = avatarURL
    }
}

// MARK: - Lapse Item

/// A lapse (captured media/post) within an epoch, displayed as NFT-style item
struct LapseItem: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let title: String
    let imageURL: URL?
    let epochId: UInt64
    let createdAt: Date

    init(id: UUID = UUID(), title: String, imageURL: URL? = nil, epochId: UInt64, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.epochId = epochId
        self.createdAt = createdAt
    }
}

// MARK: - Mock Data

extension ProfileData {
    /// Mock profile data for previews and testing
    static func mock(user: User = .mockWallet) -> ProfileData {
        ProfileData(
            user: user,
            followerCount: 1247,
            followingCount: 892,
            addressCount: 3,
            isFollowing: false,
            epochTags: EpochTag.mockTags,
            mutualFollowers: MutualFollower.mockFollowers,
            epochs: [.mock(id: 1, epochTitle: "Tech Meetup 2026"), .mock(id: 2, epochTitle: "Web3 Summit"), .mock(id: 3, epochTitle: "Devcon Bangkok")],
            lapses: LapseItem.mockLapses
        )
    }
}

extension EpochTag {
    static let mockTags: [EpochTag] = [
        EpochTag(name: "Tech Events", participantCount: 234),
        EpochTag(name: "Web3", participantCount: 189),
        EpochTag(name: "Music", participantCount: 156),
        EpochTag(name: "Art", participantCount: 98),
        EpochTag(name: "Gaming", participantCount: 76)
    ]
}

extension MutualFollower {
    static let mockFollowers: [MutualFollower] = [
        MutualFollower(name: "dominic.crypto"),
        MutualFollower(name: "ryan.crypto"),
        MutualFollower(name: "karevych.crypto"),
        MutualFollower(name: "vitalik.eth"),
        MutualFollower(name: "sandy.nft")
    ]
}

extension LapseItem {
    static let mockLapses: [LapseItem] = [
        LapseItem(title: "Opening keynote", epochId: 1),
        LapseItem(title: "Panel discussion", epochId: 1),
        LapseItem(title: "Networking session", epochId: 2),
        LapseItem(title: "Workshop demo", epochId: 2),
        LapseItem(title: "Closing ceremony", epochId: 3)
    ]
}
