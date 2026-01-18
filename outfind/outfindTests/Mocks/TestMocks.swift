import Foundation
@testable import outfind

/// Test-specific mock for EpochRepository with controllable behavior
final class TestEpochRepository: EpochRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    var epochs: [UInt64: Epoch] = [:]
    var shouldThrowError = false
    var errorToThrow: Error = EpochError.notFound(epochId: 0)
    private var eventContinuations: [UInt64: AsyncStream<EpochEvent>.Continuation] = [:]

    func fetchEpochs(filter: EpochFilter?) async throws -> [Epoch] {
        if shouldThrowError { throw errorToThrow }
        lock.lock()
        let result = Array(epochs.values)
        lock.unlock()
        return result
    }

    func fetchEpoch(id: UInt64) async throws -> Epoch {
        if shouldThrowError { throw errorToThrow }
        lock.lock()
        let epoch = epochs[id]
        lock.unlock()
        guard let epoch else { throw EpochError.notFound(epochId: id) }
        return epoch
    }

    func fetchEpochState(id: UInt64) async throws -> EpochState {
        let epoch = try await fetchEpoch(id: id)
        return epoch.state
    }

    func fetchEpochCapability(id: UInt64) async throws -> EpochCapability {
        let epoch = try await fetchEpoch(id: id)
        return epoch.capability
    }

    func subscribeToEpochEvents(id: UInt64) -> AsyncStream<EpochEvent> {
        AsyncStream { [weak self] continuation in
            self?.lock.lock()
            self?.eventContinuations[id] = continuation
            self?.lock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.eventContinuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
        }
    }

    func unsubscribeFromEpochEvents(id: UInt64) async {
        lock.lock()
        let continuation = eventContinuations.removeValue(forKey: id)
        lock.unlock()
        continuation?.finish()
    }

    // Test helpers
    func emitEvent(_ event: EpochEvent, for epochId: UInt64) {
        lock.lock()
        eventContinuations[epochId]?.yield(event)
        lock.unlock()
    }
}

/// Test-specific mock for PresenceRepository
final class TestPresenceRepository: PresenceRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    var presences: [String: Presence] = [:]
    var shouldThrowError = false
    var errorToThrow: Error = PresenceError.invalidState(current: .none, expected: .declared)
    var quorumSize: UInt64 = 3

    func fetchPresence(actor: Address, epochId: UInt64) async throws -> Presence? {
        if shouldThrowError { throw errorToThrow }
        let key = "\(epochId):\(actor.hex)"
        lock.lock()
        let presence = presences[key]
        lock.unlock()
        return presence
    }

    func declarePresence(epochId: UInt64, stake: UInt64?) async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        let actor = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        let presence = Presence(
            epochId: epochId,
            actor: actor,
            state: .declared,
            declaredAt: Date(),
            validatedAt: nil,
            validationCount: 0
        )
        let key = "\(epochId):\(actor.hex)"
        lock.lock()
        presences[key] = presence
        lock.unlock()
        return presence
    }

    func subscribeToPresenceEvents(actor: Address, epochId: UInt64) -> AsyncStream<PresenceEvent> {
        AsyncStream { _ in }
    }

    func unsubscribeFromPresenceEvents(actor: Address, epochId: UInt64) async {}

    func fetchParticipants(epochId: UInt64) async throws -> [Presence] {
        lock.lock()
        let participants = presences.values.filter { $0.epochId == epochId }
        lock.unlock()
        return Array(participants)
    }

    func fetchQuorumSize() async throws -> UInt64 {
        lock.lock()
        let size = quorumSize
        lock.unlock()
        return size
    }
}

/// Test-specific mock for EphemeralCacheRepository with tracking
final class TestEphemeralCacheRepository: EphemeralCacheRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
    private(set) var purgedEpochIds: [UInt64] = []
    private(set) var purgeAllCallCount = 0

    func store<T: Codable & Sendable>(_ value: T, key: String, epochId: UInt64) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        lock.lock()
        storage["\(epochId):\(key)"] = data
        lock.unlock()
    }

    func retrieve<T: Codable & Sendable>(key: String, epochId: UInt64) async -> T? {
        lock.lock()
        let data = storage["\(epochId):\(key)"]
        lock.unlock()
        guard let data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func delete(key: String, epochId: UInt64) async {
        lock.lock()
        storage.removeValue(forKey: "\(epochId):\(key)")
        lock.unlock()
    }

    func exists(key: String, epochId: UInt64) async -> Bool {
        lock.lock()
        let exists = storage["\(epochId):\(key)"] != nil
        lock.unlock()
        return exists
    }

    func purgeEpoch(epochId: UInt64) async {
        let prefix = "\(epochId):"
        lock.lock()
        storage = storage.filter { !$0.key.hasPrefix(prefix) }
        purgedEpochIds.append(epochId)
        lock.unlock()
    }

    func getCachedEpochIds() async -> [UInt64] {
        lock.lock()
        let keys = Array(storage.keys)
        lock.unlock()

        let epochIds = Set(keys.compactMap { key -> UInt64? in
            guard let epochString = key.split(separator: ":").first else { return nil }
            return UInt64(epochString)
        })
        return epochIds.sorted()
    }

    func purgeExpiredEpochs(closedEpochIds: [UInt64]) async {
        for epochId in closedEpochIds {
            await purgeEpoch(epochId: epochId)
        }
    }

    func purgeAll() async {
        lock.lock()
        storage.removeAll()
        purgeAllCallCount += 1
        lock.unlock()
    }

    // Test helpers
    func reset() {
        lock.lock()
        purgedEpochIds.removeAll()
        purgeAllCallCount = 0
        storage.removeAll()
        lock.unlock()
    }
}

/// Test observer for EpochLifecycleObserver
final class TestLifecycleObserver: EpochLifecycleObserver {
    private let lock = NSLock()
    private(set) var activatedEpochs: [UInt64] = []
    private(set) var closedEpochs: [UInt64] = []
    private(set) var finalizedEpochs: [UInt64] = []
    private(set) var timerTicks: [(epochId: UInt64, timeRemaining: TimeInterval)] = []
    private(set) var presenceUpdates: [(presence: Presence, epochId: UInt64)] = []

    func epochDidActivate(_ epochId: UInt64) {
        lock.lock()
        activatedEpochs.append(epochId)
        lock.unlock()
    }

    func epochDidClose(_ epochId: UInt64) {
        lock.lock()
        closedEpochs.append(epochId)
        lock.unlock()
    }

    func epochDidFinalize(_ epochId: UInt64) {
        lock.lock()
        finalizedEpochs.append(epochId)
        lock.unlock()
    }

    func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval) {
        lock.lock()
        timerTicks.append((epochId: epochId, timeRemaining: timeRemaining))
        lock.unlock()
    }

    func presenceDidUpdate(_ presence: Presence, for epochId: UInt64) {
        lock.lock()
        presenceUpdates.append((presence: presence, epochId: epochId))
        lock.unlock()
    }

    func reset() {
        lock.lock()
        activatedEpochs.removeAll()
        closedEpochs.removeAll()
        finalizedEpochs.removeAll()
        timerTicks.removeAll()
        presenceUpdates.removeAll()
        lock.unlock()
    }
}
