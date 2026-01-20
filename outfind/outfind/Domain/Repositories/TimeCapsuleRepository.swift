import Foundation

// MARK: - Time Capsule Repository Protocol

/// Repository for managing time capsule operations
protocol TimeCapsuleRepositoryProtocol: Sendable {
    /// Create a new time capsule
    func create(_ capsule: TimeCapsule) async throws

    /// Fetch all capsules created by the current user
    func fetchMyCapsules() async throws -> [TimeCapsule]

    /// Fetch capsules that can be unlocked at a specific epoch
    func fetchUnlockable(for epochId: UInt64) async throws -> [TimeCapsule]

    /// Unlock a capsule
    func unlock(_ capsuleId: String) async throws -> TimeCapsule

    /// Delete a capsule
    func delete(_ capsuleId: String) async throws
}
