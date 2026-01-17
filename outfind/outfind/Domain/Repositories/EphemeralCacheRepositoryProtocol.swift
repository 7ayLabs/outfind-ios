import Foundation

/// Repository protocol for ephemeral (epoch-scoped) caching
/// CRITICAL: Implements INV14 - all data must be purged when epoch closes
protocol EphemeralCacheRepositoryProtocol: Sendable {
    // MARK: - Epoch-Scoped Storage

    /// Store a value for an epoch
    /// - Parameters:
    ///   - value: Value to store
    ///   - key: Storage key
    ///   - epochId: Epoch ID (scope)
    func store<T: Codable & Sendable>(_ value: T, key: String, epochId: UInt64) async

    /// Retrieve a stored value
    /// - Parameters:
    ///   - key: Storage key
    ///   - epochId: Epoch ID (scope)
    /// - Returns: Stored value if exists
    func retrieve<T: Codable & Sendable>(key: String, epochId: UInt64) async -> T?

    /// Delete a specific key
    /// - Parameters:
    ///   - key: Storage key
    ///   - epochId: Epoch ID (scope)
    func delete(key: String, epochId: UInt64) async

    /// Check if a key exists
    /// - Parameters:
    ///   - key: Storage key
    ///   - epochId: Epoch ID (scope)
    /// - Returns: True if key exists
    func exists(key: String, epochId: UInt64) async -> Bool

    // MARK: - Cleanup (CRITICAL for INV14, INV29)

    /// Purge ALL data for an epoch
    /// Called when epoch closes to enforce INV14
    /// - Parameter epochId: Epoch ID to purge
    func purgeEpoch(epochId: UInt64) async

    /// Get list of epochs with cached data
    /// - Returns: Array of epoch IDs
    func getCachedEpochIds() async -> [UInt64]

    /// Purge all expired epochs (cleanup on app launch)
    /// - Parameter closedEpochIds: IDs of epochs that are known to be closed
    func purgeExpiredEpochs(closedEpochIds: [UInt64]) async

    /// Purge all cached data (full reset)
    func purgeAll() async
}

// MARK: - Cache Keys

/// Standard cache keys for epoch-scoped data
enum EphemeralCacheKey {
    static let messages = "messages"
    static let nodes = "nodes"
    static let mediaMetadata = "media_metadata"
    static let mediaContent = "media_content"
    static let presence = "presence"
    static let epochState = "epoch_state"

    /// Generate a key with a suffix
    static func key(_ base: String, suffix: String) -> String {
        "\(base)_\(suffix)"
    }
}
