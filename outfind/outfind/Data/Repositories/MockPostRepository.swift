import Foundation

// MARK: - Mock Post Repository

/// Mock implementation of PostRepositoryProtocol for MVP development and testing.
/// Returns sample data and simulates network delays.
final class MockPostRepository: PostRepositoryProtocol, @unchecked Sendable {

    // MARK: - Storage

    private var posts: [EpochPost] = EpochPost.mockPosts()
    private var likedPostIds: Set<UUID> = []

    // MARK: - PostRepositoryProtocol

    func fetchPosts(for epochId: UInt64?) async throws -> [EpochPost] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)

        var result = posts

        // Filter by epoch if specified
        if let epochId = epochId {
            result = result.filter { $0.epochId == epochId }
        }

        // Update liked status
        result = result.map { post in
            var mutablePost = post
            mutablePost.hasLiked = likedPostIds.contains(post.id)
            return mutablePost
        }

        // Sort by newest first
        return result.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPost(by postId: UUID) async throws -> EpochPost? {
        try await Task.sleep(nanoseconds: 100_000_000)
        guard var post = posts.first(where: { $0.id == postId }) else {
            return nil
        }
        post.hasLiked = likedPostIds.contains(post.id)
        return post
    }

    func createPost(_ post: EpochPost) async throws -> EpochPost {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        let newPost = post
        // Ensure fresh timestamps
        let updatedPost = EpochPost(
            id: newPost.id,
            epochId: newPost.epochId,
            author: newPost.author,
            content: newPost.content,
            imageURLs: newPost.imageURLs,
            location: newPost.location,
            createdAt: Date(),
            postType: newPost.postType,
            epochName: newPost.epochName,
            participantCount: newPost.participantCount,
            reactionCount: 0,
            commentCount: 0,
            shareCount: 0,
            hasLiked: false,
            reactions: [:],
            userReaction: nil,
            journeyCount: 0,
            hasFutureMessages: false,
            journeyId: nil
        )

        posts.insert(updatedPost, at: 0)
        return updatedPost
    }

    func likePost(_ postId: UUID) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            throw PostRepositoryError.notFound
        }

        if !likedPostIds.contains(postId) {
            likedPostIds.insert(postId)
            posts[index].reactionCount += 1
            posts[index].hasLiked = true
        }
    }

    func unlikePost(_ postId: UUID) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            throw PostRepositoryError.notFound
        }

        if likedPostIds.contains(postId) {
            likedPostIds.remove(postId)
            posts[index].reactionCount = max(0, posts[index].reactionCount - 1)
            posts[index].hasLiked = false
        }
    }

    func deletePost(_ postId: UUID) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)

        guard let index = posts.firstIndex(where: { $0.id == postId }) else {
            throw PostRepositoryError.notFound
        }

        posts.remove(at: index)
    }

    func observePosts(for epochId: UInt64?) -> AsyncStream<[EpochPost]> {
        AsyncStream { continuation in
            // Initial emission
            Task {
                if let posts = try? await self.fetchPosts(for: epochId) {
                    continuation.yield(posts)
                }
            }

            // In a real implementation, this would set up WebSocket listeners
            continuation.onTermination = { _ in
                // Cleanup if needed
            }
        }
    }

    // MARK: - Testing Helpers

    /// Reset to initial state
    func reset() {
        posts = EpochPost.mockPosts()
        likedPostIds = []
    }

    /// Add a custom post for testing
    func addPost(_ post: EpochPost) {
        posts.insert(post, at: 0)
    }
}
