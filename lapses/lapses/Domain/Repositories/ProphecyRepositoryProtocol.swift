import Foundation

// MARK: - Prophecy Repository Protocol

/// Repository protocol for managing Presence Prophecies
/// Prophecies are commitments to attend future epochs with reputation stake
protocol ProphecyRepositoryProtocol: Sendable {
    /// Create a new prophecy (commit to attend an epoch)
    func createProphecy(epochId: UInt64, stakeAmount: Double) async throws -> Prophecy

    /// Fetch all prophecies made by the current user
    func fetchMyProphecies() async throws -> [Prophecy]

    /// Fetch prophecies for a specific epoch
    func fetchProphecies(for epochId: UInt64) async throws -> [Prophecy]

    /// Fetch prophecies made by friends/following users
    func fetchFriendProphecies() async throws -> [Prophecy]

    /// Cancel a pending prophecy (before epoch starts)
    func cancelProphecy(_ prophecyId: String) async throws

    /// Check if current user has made a prophecy for an epoch
    func hasProphecy(for epochId: UInt64) async throws -> Bool

    /// Get the current user's prophecy for an epoch (if exists)
    func getProphecy(for epochId: UInt64) async throws -> Prophecy?

    /// Get user's prophecy stats (total, fulfilled, broken)
    func fetchProphecyStats() async throws -> ProphecyStats
}

// MARK: - Prophecy Stats

/// Statistics about a user's prophecy history
struct ProphecyStats: Codable, Sendable {
    let totalProphecies: Int
    let fulfilledCount: Int
    let brokenCount: Int
    let pendingCount: Int
    let totalStaked: Double
    let reputationScore: Double

    var fulfillmentRate: Double {
        guard totalProphecies > pendingCount else { return 0 }
        let resolved = totalProphecies - pendingCount
        return resolved > 0 ? Double(fulfilledCount) / Double(resolved) : 0
    }

    static var empty: ProphecyStats {
        ProphecyStats(
            totalProphecies: 0,
            fulfilledCount: 0,
            brokenCount: 0,
            pendingCount: 0,
            totalStaked: 0,
            reputationScore: 100
        )
    }

    static func mock() -> ProphecyStats {
        ProphecyStats(
            totalProphecies: 15,
            fulfilledCount: 12,
            brokenCount: 1,
            pendingCount: 2,
            totalStaked: 250.0,
            reputationScore: 85.5
        )
    }
}
