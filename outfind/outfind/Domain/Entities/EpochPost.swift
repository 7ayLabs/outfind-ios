import Foundation

// MARK: - Post Type

/// Type of ephemeral post
enum EpochPostType: String, Sendable, Equatable, Hashable {
    /// Regular post with content
    case post
    /// Lapse invitation - shows epoch info and join button
    case lapse
}

// MARK: - Epoch Post

/// Represents an ephemeral post scoped to an epoch.
/// Posts are automatically purged when the epoch closes (INV14).
/// Requires `presenceWithEphemeralData` capability (INV27).
struct EpochPost: Identifiable, Equatable, Hashable, Sendable {
    /// Unique post identifier
    let id: UUID

    /// The epoch this post belongs to
    let epochId: UInt64

    /// Post author information
    let author: PostAuthor

    /// Text content of the post
    let content: String

    /// Optional attached images
    let imageURLs: [URL]

    /// Optional location information
    let location: EpochLocation?

    /// When the post was created
    let createdAt: Date

    /// Type of post (regular post or lapse invitation)
    let postType: EpochPostType

    /// Epoch name for lapse posts
    let epochName: String?

    /// Participant count for lapse posts
    let participantCount: Int?

    // MARK: - Engagement Metrics

    /// Number of reactions (hearts/likes)
    var reactionCount: Int

    /// Number of comments
    var commentCount: Int

    /// Number of shares
    var shareCount: Int

    /// Whether the current user has liked this post
    var hasLiked: Bool

    // MARK: - Emoji Reactions

    /// Dictionary of emoji reactions with counts (e.g., ["❤️": 5, "🔥": 3])
    var reactions: [String: Int]

    /// The current user's reaction emoji (nil if no reaction)
    var userReaction: String?

    // MARK: - Time Branches

    /// Number of journeys connected to this post
    var journeyCount: Int

    /// Whether this post has future messages (time capsules)
    var hasFutureMessages: Bool

    /// ID of the journey this post belongs to (if any)
    var journeyId: UInt64?

    /// Whether this is a lapse post
    var isLapse: Bool {
        postType == .lapse
    }

    // MARK: - Computed Properties

    /// Formatted time since post creation
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)

        if interval < 60 {
            return "Now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }

    /// Whether post has any images attached
    var hasImages: Bool {
        !imageURLs.isEmpty
    }

    /// Whether post has location info
    var hasLocation: Bool {
        location != nil
    }
}

// MARK: - Post Author

/// Author information for a post
struct PostAuthor: Equatable, Hashable, Sendable {
    /// Unique author identifier
    let id: String

    /// Display name
    let name: String

    /// Avatar image URL
    let avatarURL: URL?

    /// Location name (e.g., "The Bronx", "Manhattan")
    let locationName: String?

    /// Abbreviated display name (first name only)
    var firstName: String {
        name.components(separatedBy: " ").first ?? name
    }
}

// MARK: - Post Visibility

/// Visibility options for creating posts
enum PostVisibility: String, CaseIterable, Sendable {
    case anyone = "Anyone"
    case epochMembers = "Epoch Members"
    case nearby = "Nearby"

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .anyone: return "globe"
        case .epochMembers: return "person.2"
        case .nearby: return "location"
        }
    }
}

// MARK: - Factory Methods

extension EpochPost {
    /// Create a mock post for previews and testing
    static func mock(
        id: UUID = UUID(),
        epochId: UInt64 = 1,
        authorName: String = "Veronica Margareth",
        content: String = "Hello! Does anyone have a recommendation for a skilled woodworker?",
        locationName: String? = "The Bronx",
        postType: EpochPostType = .post,
        epochName: String? = nil,
        participantCount: Int? = nil,
        reactionCount: Int = 2,
        commentCount: Int = 1,
        journeyCount: Int = 0,
        hasFutureMessages: Bool = false,
        minutesAgo: Int = 5
    ) -> EpochPost {
        EpochPost(
            id: id,
            epochId: epochId,
            author: PostAuthor(
                id: UUID().uuidString,
                name: authorName,
                avatarURL: nil,
                locationName: locationName
            ),
            content: content,
            imageURLs: [],
            location: locationName != nil ? EpochLocation(
                latitude: 40.8448,
                longitude: -73.8648,
                radius: 500,
                name: "910 Grand Concourse, Bronx, NY 10451"
            ) : nil,
            createdAt: Date().addingTimeInterval(-Double(minutesAgo * 60)),
            postType: postType,
            epochName: epochName,
            participantCount: participantCount,
            reactionCount: reactionCount,
            commentCount: commentCount,
            shareCount: 0,
            hasLiked: false,
            reactions: reactionCount > 0 ? ["❤️": reactionCount] : [:],
            userReaction: nil,
            journeyCount: journeyCount,
            hasFutureMessages: hasFutureMessages,
            journeyId: nil
        )
    }

    /// Create a lapse invitation post
    static func mockLapse(
        id: UUID = UUID(),
        authorName: String,
        epochName: String,
        participantCount: Int,
        locationName: String? = nil,
        minutesAgo: Int = 5
    ) -> EpochPost {
        EpochPost.mock(
            id: id,
            authorName: authorName,
            content: "Join me in this moment",
            locationName: locationName,
            postType: .lapse,
            epochName: epochName,
            participantCount: participantCount,
            reactionCount: 0,
            commentCount: 0,
            journeyCount: 0,
            hasFutureMessages: false,
            minutesAgo: minutesAgo
        )
    }

    /// Create sample posts for testing (15+ posts)
    static func mockPosts() -> [EpochPost] {
        [
            // Regular posts
            EpochPost.mock(
                authorName: "Veronica Margareth",
                content: "Hello! Does anyone have a recommendation for a skilled woodworker? I'm looking to create a minibar for my house.",
                locationName: "The Bronx",
                reactionCount: 2,
                commentCount: 1,
                minutesAgo: 2
            ),

            // Lapse post
            EpochPost.mockLapse(
                authorName: "Michael Chen",
                epochName: "Sunset Vibes",
                participantCount: 23,
                locationName: "Brooklyn Heights",
                minutesAgo: 3
            ),

            EpochPost.mock(
                authorName: "Sarah Johnson",
                content: "Looking for recommendations for a good Italian restaurant in the area. Family visiting this weekend!",
                locationName: "Manhattan",
                reactionCount: 8,
                commentCount: 12,
                journeyCount: 1,
                minutesAgo: 5
            ),

            EpochPost.mock(
                authorName: "David Kim",
                content: "Free couch! First come first served. DM me for pickup address.",
                locationName: "Queens",
                reactionCount: 3,
                commentCount: 7,
                minutesAgo: 8
            ),

            // Lapse post
            EpochPost.mockLapse(
                authorName: "Emma Wilson",
                epochName: "Morning Coffee Run",
                participantCount: 8,
                locationName: "Williamsburg",
                minutesAgo: 10
            ),

            EpochPost.mock(
                authorName: "James Rodriguez",
                content: "The new art installation at the park is incredible. Definitely worth checking out before it's gone!",
                locationName: "Central Park",
                reactionCount: 45,
                commentCount: 23,
                journeyCount: 2,
                hasFutureMessages: true,
                minutesAgo: 12
            ),

            EpochPost.mock(
                authorName: "Lisa Thompson",
                content: "Anyone up for a spontaneous beach trip tomorrow? Weather looks perfect.",
                locationName: "Coney Island",
                reactionCount: 18,
                commentCount: 9,
                minutesAgo: 15
            ),

            // Lapse post
            EpochPost.mockLapse(
                authorName: "Alex Rivera",
                epochName: "Street Photography Walk",
                participantCount: 12,
                locationName: "SoHo",
                minutesAgo: 18
            ),

            EpochPost.mock(
                authorName: "Nina Patel",
                content: "Just discovered the best ramen spot. Hidden gem in the basement of an old building.",
                locationName: "East Village",
                reactionCount: 67,
                commentCount: 34,
                journeyCount: 1,
                minutesAgo: 20
            ),

            EpochPost.mock(
                authorName: "Chris Anderson",
                content: "Looking for someone to play tennis with this weekend. Intermediate level.",
                locationName: "Prospect Park",
                reactionCount: 5,
                commentCount: 3,
                minutesAgo: 25
            ),

            // Lapse post
            EpochPost.mockLapse(
                authorName: "Maya Santos",
                epochName: "Rooftop Yoga Session",
                participantCount: 15,
                locationName: "DUMBO",
                minutesAgo: 28
            ),

            EpochPost.mock(
                authorName: "Tom Bradley",
                content: "Power outage on my block. Anyone else affected? Trying to figure out how widespread it is.",
                locationName: "Astoria",
                reactionCount: 12,
                commentCount: 28,
                minutesAgo: 30
            ),

            EpochPost.mock(
                authorName: "Rachel Green",
                content: "My cat escaped! Orange tabby, answers to Whiskers. Please DM if you see him near the park.",
                locationName: "Upper West Side",
                reactionCount: 34,
                commentCount: 15,
                hasFutureMessages: true,
                minutesAgo: 35
            ),

            // Lapse post
            EpochPost.mockLapse(
                authorName: "Jordan Lee",
                epochName: "Late Night Coding Session",
                participantCount: 6,
                locationName: "Tech Hub",
                minutesAgo: 40
            ),

            EpochPost.mock(
                authorName: "Sophia Martinez",
                content: "Street performers at the subway station are killing it tonight. Worth stopping by!",
                locationName: "Times Square",
                reactionCount: 89,
                commentCount: 41,
                journeyCount: 3,
                minutesAgo: 45
            ),

            EpochPost.mock(
                authorName: "Kevin O'Brien",
                content: "Hosting a small potluck dinner next week. Bringing together neighbors. DM if interested!",
                locationName: "Hell's Kitchen",
                reactionCount: 23,
                commentCount: 19,
                minutesAgo: 50
            ),

            // Lapse post
            EpochPost.mockLapse(
                authorName: "Isabella Russo",
                epochName: "Vinyl Record Swap",
                participantCount: 31,
                locationName: "Bushwick",
                minutesAgo: 55
            )
        ]
    }
}
