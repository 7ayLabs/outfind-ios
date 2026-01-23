import Foundation

// MARK: - Post Type

/// Type of ephemeral post
enum EpochPostType: String, Sendable, Equatable, Hashable {
    /// Regular post with content
    case post
    /// Lapse invitation - shows epoch info and join button
    case lapse
}

// MARK: - Post Section Type

/// Section type for organizing posts in feed
enum PostSectionType: String, Sendable, Equatable, Hashable {
    case nearby = "Nearby"
    case `private` = "Private"
    case trending = "Trending"
    case following = "Following"
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

    /// Whether this post contains video content
    let isVideo: Bool

    /// Video URL for video posts
    let videoURL: URL?

    /// Section type for feed organization
    let sectionType: PostSectionType

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

    /// Whether this post has been saved by the user
    var isSaved: Bool

    /// When the post was saved (nil if not saved)
    var savedAt: Date?

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

    /// Author handle (e.g., "@veronica_m")
    let handle: String?

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
        authorHandle: String? = nil,
        content: String = "Hello! Does anyone have a recommendation for a skilled woodworker?",
        imageURLs: [URL] = [],
        isVideo: Bool = false,
        videoURL: URL? = nil,
        sectionType: PostSectionType = .nearby,
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
        // Generate handle from name if not provided
        let handle = authorHandle ?? "@\(authorName.lowercased().replacingOccurrences(of: " ", with: "_").prefix(15))"

        return EpochPost(
            id: id,
            epochId: epochId,
            author: PostAuthor(
                id: UUID().uuidString,
                name: authorName,
                handle: handle,
                avatarURL: nil,
                locationName: locationName
            ),
            content: content,
            imageURLs: imageURLs,
            isVideo: isVideo,
            videoURL: videoURL,
            sectionType: sectionType,
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
            isSaved: false,
            savedAt: nil,
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
        authorHandle: String? = nil,
        epochName: String,
        participantCount: Int,
        sectionType: PostSectionType = .nearby,
        locationName: String? = nil,
        minutesAgo: Int = 5
    ) -> EpochPost {
        EpochPost.mock(
            id: id,
            authorName: authorName,
            authorHandle: authorHandle,
            content: "Join me in this moment",
            imageURLs: [],
            sectionType: sectionType,
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

    /// Sample image URLs for testing
    private static let sampleImageURLs: [URL] = [
        URL(string: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=800")!,
        URL(string: "https://images.unsplash.com/photo-1540979388789-6cee28a1cdc9?w=800")!
    ]

    /// Create sample posts for testing (15+ posts with images and videos)
    static func mockPosts() -> [EpochPost] {
        [
            // NEARBY SECTION - Posts with images/videos
            EpochPost.mock(
                authorName: "Cristiano Ronaldo",
                authorHandle: "@CR7",
                content: "Golden hour at the beach. Perfect end to a perfect day.",
                imageURLs: [sampleImageURLs[3]],
                isVideo: true,
                sectionType: .nearby,
                locationName: "Miami Beach",
                reactionCount: 135000,
                commentCount: 4521,
                minutesAgo: 1
            ),

            EpochPost.mock(
                authorName: "Sarah Johnson",
                authorHandle: "@sarahj",
                content: "Mountain views never get old. Hiking with friends today!",
                imageURLs: [sampleImageURLs[0]],
                sectionType: .nearby,
                locationName: "Colorado",
                reactionCount: 892,
                commentCount: 45,
                journeyCount: 1,
                minutesAgo: 5
            ),

            EpochPost.mock(
                authorName: "James Rodriguez",
                authorHandle: "@jamesrod",
                content: "The new art installation at the park is incredible. Definitely worth checking out before it's gone!",
                imageURLs: [sampleImageURLs[1]],
                isVideo: true,
                sectionType: .nearby,
                locationName: "Central Park",
                reactionCount: 4521,
                commentCount: 234,
                journeyCount: 2,
                hasFutureMessages: true,
                minutesAgo: 12
            ),

            EpochPost.mock(
                authorName: "Lisa Thompson",
                authorHandle: "@lisa_t",
                content: "Perfect beach weather! Who's joining tomorrow?",
                imageURLs: [sampleImageURLs[3]],
                sectionType: .nearby,
                locationName: "Coney Island",
                reactionCount: 1823,
                commentCount: 89,
                minutesAgo: 15
            ),

            // PRIVATE SECTION - Posts from friends/following
            EpochPost.mock(
                authorName: "Veronica Margareth",
                authorHandle: "@veronica_m",
                content: "Hello! Does anyone have a recommendation for a skilled woodworker? I'm looking to create a minibar for my house.",
                sectionType: .private,
                locationName: "The Bronx",
                reactionCount: 2,
                commentCount: 1,
                minutesAgo: 2
            ),

            EpochPost.mockLapse(
                authorName: "Michael Chen",
                authorHandle: "@mike_chen",
                epochName: "Sunset Vibes",
                participantCount: 23,
                sectionType: .private,
                locationName: "Brooklyn Heights",
                minutesAgo: 3
            ),

            EpochPost.mock(
                authorName: "David Kim",
                authorHandle: "@davidk",
                content: "Free couch! First come first served. DM me for pickup address.",
                sectionType: .private,
                locationName: "Queens",
                reactionCount: 3,
                commentCount: 7,
                minutesAgo: 8
            ),

            EpochPost.mockLapse(
                authorName: "Emma Wilson",
                authorHandle: "@emma_w",
                epochName: "Morning Coffee Run",
                participantCount: 8,
                sectionType: .private,
                locationName: "Williamsburg",
                minutesAgo: 10
            ),

            EpochPost.mock(
                authorName: "Nina Patel",
                authorHandle: "@nina_p",
                content: "Just discovered the best ramen spot. Hidden gem in the basement of an old building.",
                sectionType: .private,
                locationName: "East Village",
                reactionCount: 67,
                commentCount: 34,
                journeyCount: 1,
                minutesAgo: 20
            ),

            // MORE NEARBY
            EpochPost.mock(
                authorName: "Chris Anderson",
                authorHandle: "@chrisand",
                content: "Snow-capped peaks at dawn. Nature's masterpiece.",
                imageURLs: [sampleImageURLs[4]],
                isVideo: true,
                sectionType: .nearby,
                locationName: "Rocky Mountains",
                reactionCount: 5632,
                commentCount: 178,
                minutesAgo: 25
            ),

            EpochPost.mockLapse(
                authorName: "Maya Santos",
                authorHandle: "@maya_s",
                epochName: "Rooftop Yoga Session",
                participantCount: 15,
                sectionType: .nearby,
                locationName: "DUMBO",
                minutesAgo: 28
            ),

            EpochPost.mock(
                authorName: "Rachel Green",
                authorHandle: "@rachelg",
                content: "Waterfall magic in the forest. Sound of nature is the best meditation.",
                imageURLs: [sampleImageURLs[6]],
                sectionType: .nearby,
                locationName: "Pacific Northwest",
                reactionCount: 3421,
                commentCount: 156,
                hasFutureMessages: true,
                minutesAgo: 35
            ),

            // MORE PRIVATE
            EpochPost.mock(
                authorName: "Tom Bradley",
                authorHandle: "@tomb",
                content: "Power outage on my block. Anyone else affected? Trying to figure out how widespread it is.",
                sectionType: .private,
                locationName: "Astoria",
                reactionCount: 12,
                commentCount: 28,
                minutesAgo: 30
            ),

            EpochPost.mockLapse(
                authorName: "Jordan Lee",
                authorHandle: "@jordanl",
                epochName: "Late Night Coding Session",
                participantCount: 6,
                sectionType: .private,
                locationName: "Tech Hub",
                minutesAgo: 40
            ),

            EpochPost.mock(
                authorName: "Sophia Martinez",
                authorHandle: "@sophiam",
                content: "City lights from the rooftop. Urban jungle vibes tonight.",
                imageURLs: [sampleImageURLs[7]],
                isVideo: true,
                sectionType: .nearby,
                locationName: "Times Square",
                reactionCount: 8921,
                commentCount: 412,
                journeyCount: 3,
                minutesAgo: 45
            ),

            EpochPost.mock(
                authorName: "Kevin O'Brien",
                authorHandle: "@kevinob",
                content: "Hosting a small potluck dinner next week. Bringing together neighbors. DM if interested!",
                sectionType: .private,
                locationName: "Hell's Kitchen",
                reactionCount: 23,
                commentCount: 19,
                minutesAgo: 50
            ),

            EpochPost.mockLapse(
                authorName: "Isabella Russo",
                authorHandle: "@isabella_r",
                epochName: "Vinyl Record Swap",
                participantCount: 31,
                sectionType: .nearby,
                locationName: "Bushwick",
                minutesAgo: 55
            )
        ]
    }
}
