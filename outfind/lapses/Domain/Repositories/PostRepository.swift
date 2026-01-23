import Foundation

// MARK: - Post Repository Protocol

/// Repository for managing epoch-scoped posts.
/// Posts are ephemeral and tied to active epochs (INV14).
protocol PostRepositoryProtocol: Sendable {

    /// Fetch posts for a specific epoch or all active epochs
    /// - Parameter epochId: Optional epoch ID to filter by. If nil, returns posts from all active epochs.
    /// - Returns: Array of posts sorted by creation date (newest first)
    func fetchPosts(for epochId: UInt64?) async throws -> [EpochPost]

    /// Fetch a single post by ID
    /// - Parameter postId: The post identifier
    /// - Returns: The post if found
    func fetchPost(by postId: UUID) async throws -> EpochPost?

    /// Create a new post
    /// - Parameter post: The post to create
    /// - Returns: The created post with server-assigned properties
    func createPost(_ post: EpochPost) async throws -> EpochPost

    /// Like a post
    /// - Parameter postId: The post identifier to like
    func likePost(_ postId: UUID) async throws

    /// Unlike a post
    /// - Parameter postId: The post identifier to unlike
    func unlikePost(_ postId: UUID) async throws

    /// Delete a post (author only)
    /// - Parameter postId: The post identifier to delete
    func deletePost(_ postId: UUID) async throws

    /// Observe posts for real-time updates
    /// - Parameter epochId: Optional epoch ID to filter by
    /// - Returns: AsyncStream of post arrays
    func observePosts(for epochId: UInt64?) -> AsyncStream<[EpochPost]>
}

// MARK: - Post Repository Errors

/// Errors that can occur during post operations
enum PostRepositoryError: Error, LocalizedError {
    case notFound
    case unauthorized
    case epochNotActive
    case capabilityRequired
    case networkError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Post not found"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .epochNotActive:
            return "Cannot post - epoch is not active"
        case .capabilityRequired:
            return "This epoch doesn't support posts"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
