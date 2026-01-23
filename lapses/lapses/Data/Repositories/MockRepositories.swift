import Foundation

// MARK: - Mock Wallet Repository

/// Mock implementation of WalletRepositoryProtocol for development and testing
final class MockWalletRepository: WalletRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _wallet: Wallet?
    private var connectionContinuation: AsyncStream<WalletConnectionState>.Continuation?

    var currentWallet: Wallet? {
        get async {
            lock.lock()
            defer { lock.unlock() }
            return _wallet
        }
    }

    func connect() async throws -> Wallet {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        let wallet = Wallet.mock()

        lock.lock()
        _wallet = wallet
        let continuation = connectionContinuation
        lock.unlock()

        continuation?.yield(.connected(wallet))
        return wallet
    }

    func disconnect() async throws {
        lock.lock()
        _wallet = nil
        let continuation = connectionContinuation
        lock.unlock()

        continuation?.yield(.disconnected)
    }

    func signMessage(_ message: String) async throws -> Data {
        guard await currentWallet != nil else {
            throw WalletError.connectionFailed("No wallet connected")
        }
        // Return mock 65-byte signature
        return Data(repeating: 0xAB, count: ProtocolConstants.signatureSize)
    }

    func signTypedData(_ typedData: TypedData) async throws -> Data {
        guard await currentWallet != nil else {
            throw WalletError.connectionFailed("No wallet connected")
        }
        return Data(repeating: 0xCD, count: ProtocolConstants.signatureSize)
    }

    func observeWalletState() -> AsyncStream<WalletConnectionState> {
        AsyncStream { [weak self] continuation in
            self?.lock.lock()
            self?.connectionContinuation = continuation
            let wallet = self?._wallet
            self?.lock.unlock()

            if let wallet = wallet {
                continuation.yield(.connected(wallet))
            } else {
                continuation.yield(.disconnected)
            }

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.connectionContinuation = nil
                self?.lock.unlock()
            }
        }
    }
}

// MARK: - Mock Epoch Repository

/// Mock implementation of EpochRepositoryProtocol for development and testing
final class MockEpochRepository: EpochRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var epochs: [UInt64: Epoch]
    private var eventContinuations: [UInt64: AsyncStream<EpochEvent>.Continuation] = [:]

    init() {
        // Initialize with sample epochs
        let sampleEpochs: [Epoch] = [
            .mock(id: 1, title: "Crypto Meetup SF", state: .active, capability: .presenceWithEphemeralData, participantCount: 42),
            .mock(id: 2, title: "Web3 Hackathon", state: .scheduled, capability: .presenceWithSignals, participantCount: 128),
            .mock(id: 3, title: "ETH Denver Afterparty", state: .active, capability: .presenceWithEphemeralData, participantCount: 256),
            .mock(id: 4, title: "DeFi Summit", state: .closed, capability: .presenceWithSignals, participantCount: 512)
        ]
        self.epochs = Dictionary(uniqueKeysWithValues: sampleEpochs.map { ($0.id, $0) })
    }

    func fetchEpochs(filter: EpochFilter?) async throws -> [Epoch] {
        lock.lock()
        var result = Array(epochs.values)
        lock.unlock()

        // Apply filters
        if let states = filter?.states {
            result = result.filter { states.contains($0.state) }
        }

        if let minCapability = filter?.minCapability {
            result = result.filter { $0.capability >= minCapability }
        }

        if let limit = filter?.limit {
            result = Array(result.prefix(limit))
        }

        // Sort by start time
        result.sort { $0.startTime < $1.startTime }

        return result
    }

    func fetchEpoch(id: UInt64) async throws -> Epoch {
        lock.lock()
        let epoch = epochs[id]
        lock.unlock()

        guard let epoch = epoch else {
            throw EpochError.notFound(epochId: id)
        }
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
            guard let self = self else { return }

            self.lock.lock()
            self.eventContinuations[id] = continuation
            let epoch = self.epochs[id]
            self.lock.unlock()

            // Start timer task for epoch
            Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)

                    guard let self = self else { break }
                    self.lock.lock()
                    let currentEpoch = self.epochs[id]
                    self.lock.unlock()

                    if let epoch = currentEpoch {
                        continuation.yield(.timerTick(timeRemaining: epoch.timeUntilNextPhase))
                    }
                }
            }

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

    // MARK: - Test Helpers

    func addEpoch(_ epoch: Epoch) {
        lock.lock()
        epochs[epoch.id] = epoch
        lock.unlock()
    }

    func updateEpoch(_ epoch: Epoch) {
        lock.lock()
        epochs[epoch.id] = epoch
        if let continuation = eventContinuations[epoch.id] {
            continuation.yield(.phaseChanged(epoch.state))
        }
        lock.unlock()
    }
}

// MARK: - Mock Presence Repository

/// Mock implementation of PresenceRepositoryProtocol for development and testing
final class MockPresenceRepository: PresenceRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var presences: [String: Presence] = [:]
    private var eventContinuations: [String: AsyncStream<PresenceEvent>.Continuation] = [:]
    private var quorumSize: UInt64 = 3

    func fetchPresence(actor: Address, epochId: UInt64) async throws -> Presence? {
        let key = makeKey(actor: actor, epochId: epochId)
        lock.lock()
        let presence = presences[key]
        lock.unlock()
        return presence
    }

    func declarePresence(epochId: UInt64, stake: UInt64?) async throws -> Presence {
        // Simulate transaction delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let mockActor = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        let presence = Presence(
            epochId: epochId,
            actor: mockActor,
            state: .declared,
            declaredAt: Date(),
            validatedAt: nil,
            validationCount: 0
        )

        let key = makeKey(actor: mockActor, epochId: epochId)

        lock.lock()
        presences[key] = presence
        let continuation = eventContinuations[key]
        lock.unlock()

        continuation?.yield(.declared(presence))

        return presence
    }

    func subscribeToPresenceEvents(actor: Address, epochId: UInt64) -> AsyncStream<PresenceEvent> {
        let key = makeKey(actor: actor, epochId: epochId)

        return AsyncStream { [weak self] continuation in
            guard let self = self else { return }

            self.lock.lock()
            self.eventContinuations[key] = continuation
            self.lock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.eventContinuations.removeValue(forKey: key)
                self?.lock.unlock()
            }
        }
    }

    func unsubscribeFromPresenceEvents(actor: Address, epochId: UInt64) async {
        let key = makeKey(actor: actor, epochId: epochId)
        lock.lock()
        let continuation = eventContinuations.removeValue(forKey: key)
        lock.unlock()
        continuation?.finish()
    }

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

    func fetchEchoes(for epochId: UInt64) async throws -> [Presence] {
        // Return mock echo data - users who left within the last 24 hours
        let mockEchoes: [Presence] = [
            Presence.mockEcho(epochId: epochId, hoursAgo: 0.5),  // Just left
            Presence.mockEcho(epochId: epochId, hoursAgo: 2.0),  // 2 hours ago
            Presence.mockEcho(epochId: epochId, hoursAgo: 5.0),  // 5 hours ago
            Presence.mockEcho(epochId: epochId, hoursAgo: 12.0), // 12 hours ago
            Presence.mockEcho(epochId: epochId, hoursAgo: 20.0), // 20 hours ago - very faded
        ]

        // Sort by recency (most recent first) and filter out fully faded echoes
        return mockEchoes
            .filter { $0.echoOpacity > 0.05 } // Remove nearly invisible echoes
            .sorted { ($0.leftAt ?? .distantPast) > ($1.leftAt ?? .distantPast) }
    }

    // MARK: - Private Helpers

    private func makeKey(actor: Address, epochId: UInt64) -> String {
        "\(epochId):\(actor.hex)"
    }

    // MARK: - Test Helpers

    func setQuorumSize(_ size: UInt64) {
        lock.lock()
        quorumSize = size
        lock.unlock()
    }

    func simulateValidation(actor: Address, epochId: UInt64) {
        let key = makeKey(actor: actor, epochId: epochId)

        lock.lock()
        guard var presence = presences[key] else {
            lock.unlock()
            return
        }

        let validatedPresence = Presence(
            epochId: presence.epochId,
            actor: presence.actor,
            state: .validated,
            declaredAt: presence.declaredAt,
            validatedAt: Date(),
            validationCount: quorumSize
        )
        presences[key] = validatedPresence
        let continuation = eventContinuations[key]
        lock.unlock()

        continuation?.yield(.validated(validatedPresence))
    }
}

// MARK: - In-Memory Ephemeral Cache Repository

/// In-memory implementation of EphemeralCacheRepositoryProtocol
/// Data is lost when app terminates (as per ephemerality requirement)
final class InMemoryEphemeralCacheRepository: EphemeralCacheRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: Data] = [:]

    func store<T: Codable & Sendable>(_ value: T, key: String, epochId: UInt64) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let storageKey = makeKey(key: key, epochId: epochId)

        lock.lock()
        storage[storageKey] = data
        lock.unlock()
    }

    func retrieve<T: Codable & Sendable>(key: String, epochId: UInt64) async -> T? {
        let storageKey = makeKey(key: key, epochId: epochId)

        lock.lock()
        let data = storage[storageKey]
        lock.unlock()

        guard let data = data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func delete(key: String, epochId: UInt64) async {
        let storageKey = makeKey(key: key, epochId: epochId)

        lock.lock()
        storage.removeValue(forKey: storageKey)
        lock.unlock()
    }

    func exists(key: String, epochId: UInt64) async -> Bool {
        let storageKey = makeKey(key: key, epochId: epochId)

        lock.lock()
        let exists = storage[storageKey] != nil
        lock.unlock()

        return exists
    }

    func purgeEpoch(epochId: UInt64) async {
        let prefix = "\(epochId):"

        lock.lock()
        storage = storage.filter { !$0.key.hasPrefix(prefix) }
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
        lock.unlock()
    }

    // MARK: - Private Helpers

    private func makeKey(key: String, epochId: UInt64) -> String {
        "\(epochId):\(key)"
    }
}

// MARK: - Mock Time Capsule Repository

/// Mock implementation of TimeCapsuleRepositoryProtocol
final class MockTimeCapsuleRepository: TimeCapsuleRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var capsules: [String: TimeCapsule] = [:]

    init() {
        // Add some sample capsules
        let sample1 = TimeCapsule.mock(isUnlocked: false)
        let sample2 = TimeCapsule.mock(isUnlocked: true)
        capsules[sample1.id] = sample1
        capsules[sample2.id] = sample2
    }

    func create(_ capsule: TimeCapsule) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        lock.lock()
        capsules[capsule.id] = capsule
        lock.unlock()
    }

    func fetchMyCapsules() async throws -> [TimeCapsule] {
        lock.lock()
        let result = Array(capsules.values).sorted { $0.createdAt > $1.createdAt }
        lock.unlock()
        return result
    }

    func fetchUnlockable(for epochId: UInt64) async throws -> [TimeCapsule] {
        lock.lock()
        let result = capsules.values.filter { capsule in
            !capsule.isUnlocked &&
            capsule.associatedEpochId == epochId
        }
        lock.unlock()
        return Array(result)
    }

    func unlock(_ capsuleId: String) async throws -> TimeCapsule {
        try await Task.sleep(nanoseconds: 500_000_000)
        lock.lock()
        guard var capsule = capsules[capsuleId] else {
            lock.unlock()
            throw NSError(domain: "TimeCapsule", code: 404, userInfo: [NSLocalizedDescriptionKey: "Capsule not found"])
        }
        capsule.isUnlocked = true
        capsule.unlockedAt = Date()
        capsules[capsuleId] = capsule
        lock.unlock()
        return capsule
    }

    func delete(_ capsuleId: String) async throws {
        lock.lock()
        capsules.removeValue(forKey: capsuleId)
        lock.unlock()
    }
}

// MARK: - Mock Journey Repository

/// Mock implementation of JourneyRepositoryProtocol
final class MockJourneyRepository: JourneyRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var journeys: [String: LapseJourney] = [:]
    private var progressRecords: [String: JourneyProgress] = [:]

    init() {
        // Initialize with sample journeys
        for journey in LapseJourney.mockJourneys() {
            journeys[journey.id] = journey
        }

        // Add sample progress for one journey
        let sampleProgress = JourneyProgress.mock(journeyId: "journey-1", completedCount: 2)
        progressRecords["journey-1"] = sampleProgress
    }

    func fetchJourneys() async throws -> [LapseJourney] {
        try await Task.sleep(nanoseconds: 300_000_000)
        lock.lock()
        let result = Array(journeys.values).sorted { $0.createdAt > $1.createdAt }
        lock.unlock()
        return result
    }

    func fetchJourney(id: String) async throws -> LapseJourney? {
        lock.lock()
        let journey = journeys[id]
        lock.unlock()
        return journey
    }

    func fetchJourneys(containing epochId: UInt64) async throws -> [LapseJourney] {
        lock.lock()
        let result = journeys.values.filter { $0.contains(epochId: epochId) }
        lock.unlock()
        return Array(result)
    }

    func fetchProgress(for journeyId: String) async throws -> JourneyProgress? {
        lock.lock()
        let progress = progressRecords[journeyId]
        lock.unlock()
        return progress
    }

    func startJourney(_ journeyId: String) async throws -> JourneyProgress {
        try await Task.sleep(nanoseconds: 300_000_000)
        let progress = JourneyProgress(
            journeyId: journeyId,
            userId: "current-user",
            completedEpochIds: [],
            startedAt: Date(),
            completedAt: nil
        )
        lock.lock()
        progressRecords[journeyId] = progress
        lock.unlock()
        return progress
    }

    func completeEpoch(_ epochId: UInt64, in journeyId: String) async throws -> JourneyProgress {
        try await Task.sleep(nanoseconds: 300_000_000)
        lock.lock()
        guard var progress = progressRecords[journeyId] else {
            lock.unlock()
            throw NSError(domain: "Journey", code: 404, userInfo: [NSLocalizedDescriptionKey: "Journey progress not found"])
        }

        progress.completedEpochIds.insert(epochId)

        // Check if journey is fully completed
        if let journey = journeys[journeyId] {
            if progress.completedEpochIds.count == journey.epochCount {
                progress.completedAt = Date()
            }
        }

        progressRecords[journeyId] = progress
        lock.unlock()
        return progress
    }

    func isJourneyCompleted(_ journeyId: String) async throws -> Bool {
        lock.lock()
        let progress = progressRecords[journeyId]
        lock.unlock()
        return progress?.isJourneyCompleted ?? false
    }

    func fetchMyJourneys() async throws -> [(journey: LapseJourney, progress: JourneyProgress)] {
        lock.lock()
        var result: [(journey: LapseJourney, progress: JourneyProgress)] = []
        for (journeyId, progress) in progressRecords {
            if let journey = journeys[journeyId] {
                result.append((journey: journey, progress: progress))
            }
        }
        lock.unlock()
        return result.sorted { $0.progress.startedAt > $1.progress.startedAt }
    }
}

// MARK: - Mock Prophecy Repository

/// Mock implementation of ProphecyRepositoryProtocol
final class MockProphecyRepository: ProphecyRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var prophecies: [String: Prophecy] = [:]
    private let currentUserId = "current-user"

    init() {
        // Initialize with sample prophecies
        for prophecy in Prophecy.mockProphecies() {
            prophecies[prophecy.id] = prophecy
        }
    }

    func createProphecy(epochId: UInt64, stakeAmount: Double) async throws -> Prophecy {
        try await Task.sleep(nanoseconds: 500_000_000)

        let prophecy = Prophecy(
            id: UUID().uuidString,
            userId: currentUserId,
            epochId: epochId,
            committedAt: Date(),
            stakeAmount: stakeAmount,
            status: .pending,
            userDisplayName: "You",
            userAvatarURL: nil,
            epochTitle: "Epoch #\(epochId)"
        )

        lock.lock()
        prophecies[prophecy.id] = prophecy
        lock.unlock()

        return prophecy
    }

    func fetchMyProphecies() async throws -> [Prophecy] {
        lock.lock()
        let result = prophecies.values.filter { $0.userId == currentUserId }
            .sorted { $0.committedAt > $1.committedAt }
        lock.unlock()
        return Array(result)
    }

    func fetchProphecies(for epochId: UInt64) async throws -> [Prophecy] {
        lock.lock()
        let result = prophecies.values.filter { $0.epochId == epochId }
            .sorted { $0.committedAt > $1.committedAt }
        lock.unlock()
        return Array(result)
    }

    func fetchFriendProphecies() async throws -> [Prophecy] {
        try await Task.sleep(nanoseconds: 300_000_000)
        lock.lock()
        // Return prophecies from other users (simulating "friends")
        let result = prophecies.values.filter { $0.userId != currentUserId && $0.status == .pending }
            .sorted { $0.committedAt > $1.committedAt }
        lock.unlock()
        return Array(result)
    }

    func cancelProphecy(_ prophecyId: String) async throws {
        lock.lock()
        prophecies.removeValue(forKey: prophecyId)
        lock.unlock()
    }

    func hasProphecy(for epochId: UInt64) async throws -> Bool {
        lock.lock()
        let exists = prophecies.values.contains { $0.epochId == epochId && $0.userId == currentUserId }
        lock.unlock()
        return exists
    }

    func getProphecy(for epochId: UInt64) async throws -> Prophecy? {
        lock.lock()
        let prophecy = prophecies.values.first { $0.epochId == epochId && $0.userId == currentUserId }
        lock.unlock()
        return prophecy
    }

    func fetchProphecyStats() async throws -> ProphecyStats {
        lock.lock()
        let userProphecies = prophecies.values.filter { $0.userId == currentUserId }
        let fulfilled = userProphecies.filter { $0.status == .fulfilled }.count
        let broken = userProphecies.filter { $0.status == .broken }.count
        let pending = userProphecies.filter { $0.status == .pending }.count
        let totalStaked = userProphecies.reduce(0) { $0 + $1.stakeAmount }
        lock.unlock()

        let total = userProphecies.count
        let resolved = total - pending
        let fulfillmentRate = resolved > 0 ? Double(fulfilled) / Double(resolved) : 1.0
        let reputationScore = fulfillmentRate * 100

        return ProphecyStats(
            totalProphecies: total,
            fulfilledCount: fulfilled,
            brokenCount: broken,
            pendingCount: pending,
            totalStaked: totalStaked,
            reputationScore: reputationScore
        )
    }
}
