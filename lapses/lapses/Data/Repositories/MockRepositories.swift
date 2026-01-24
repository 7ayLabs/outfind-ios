import Foundation
import os

// MARK: - Mock Wallet Repository

/// Mock implementation of WalletRepositoryProtocol for development and testing
final class MockWalletRepository: WalletRepositoryProtocol, @unchecked Sendable {
    private struct WalletState {
        var wallet: Wallet?
        var connectionContinuation: AsyncStream<WalletConnectionState>.Continuation?
    }

    private let state = OSAllocatedUnfairLock(initialState: WalletState())

    var currentWallet: Wallet? {
        get async {
            state.withLock { $0.wallet }
        }
    }

    func connect() async throws -> Wallet {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        let wallet = Wallet.mock()

        let continuation = state.withLock { walletState -> AsyncStream<WalletConnectionState>.Continuation? in
            walletState.wallet = wallet
            return walletState.connectionContinuation
        }

        continuation?.yield(.connected(wallet))
        return wallet
    }

    func disconnect() async throws {
        let continuation = state.withLock { walletState -> AsyncStream<WalletConnectionState>.Continuation? in
            walletState.wallet = nil
            return walletState.connectionContinuation
        }

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
            guard let self else { return }

            let wallet = self.state.withLock { walletState -> Wallet? in
                walletState.connectionContinuation = continuation
                return walletState.wallet
            }

            if let wallet = wallet {
                continuation.yield(.connected(wallet))
            } else {
                continuation.yield(.disconnected)
            }

            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { $0.connectionContinuation = nil }
            }
        }
    }
}

// MARK: - Mock Epoch Repository

/// Mock implementation of EpochRepositoryProtocol for development and testing
final class MockEpochRepository: EpochRepositoryProtocol, @unchecked Sendable {
    private struct EpochRepoState {
        var epochs: [UInt64: Epoch]
        var eventContinuations: [UInt64: AsyncStream<EpochEvent>.Continuation] = [:]
    }

    private let state: OSAllocatedUnfairLock<EpochRepoState>

    init() {
        // Initialize with sample epochs
        let sampleEpochs: [Epoch] = [
            .mock(id: 1, title: "Crypto Meetup SF", state: .active, capability: .presenceWithEphemeralData, participantCount: 42),
            .mock(id: 2, title: "Web3 Hackathon", state: .scheduled, capability: .presenceWithSignals, participantCount: 128),
            .mock(id: 3, title: "ETH Denver Afterparty", state: .active, capability: .presenceWithEphemeralData, participantCount: 256),
            .mock(id: 4, title: "DeFi Summit", state: .closed, capability: .presenceWithSignals, participantCount: 512)
        ]
        let epochs = Dictionary(uniqueKeysWithValues: sampleEpochs.map { ($0.id, $0) })
        self.state = OSAllocatedUnfairLock(initialState: EpochRepoState(epochs: epochs))
    }

    func fetchEpochs(filter: EpochFilter?) async throws -> [Epoch] {
        var result = state.withLock { Array($0.epochs.values) }

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
        let epoch = state.withLock { $0.epochs[id] }

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

            self.state.withLock { epochState in
                epochState.eventContinuations[id] = continuation
            }

            // Start timer task for epoch
            Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)

                    guard let self = self else { break }
                    let currentEpoch = self.state.withLock { $0.epochs[id] }

                    if let epoch = currentEpoch {
                        continuation.yield(.timerTick(timeRemaining: epoch.timeUntilNextPhase))
                    }
                }
            }

            continuation.onTermination = { [weak self] _ in
                _ = self?.state.withLock { $0.eventContinuations.removeValue(forKey: id) }
            }
        }
    }

    func unsubscribeFromEpochEvents(id: UInt64) async {
        let continuation = state.withLock { $0.eventContinuations.removeValue(forKey: id) }
        continuation?.finish()
    }

    // MARK: - Test Helpers

    func addEpoch(_ epoch: Epoch) {
        state.withLock { $0.epochs[epoch.id] = epoch }
    }

    func updateEpoch(_ epoch: Epoch) {
        state.withLock { epochState in
            epochState.epochs[epoch.id] = epoch
            epochState.eventContinuations[epoch.id]?.yield(.phaseChanged(epoch.state))
        }
    }
}

// MARK: - Mock Presence Repository

/// Mock implementation of PresenceRepositoryProtocol for development and testing
final class MockPresenceRepository: PresenceRepositoryProtocol, @unchecked Sendable {
    private struct PresenceState {
        var presences: [String: Presence] = [:]
        var eventContinuations: [String: AsyncStream<PresenceEvent>.Continuation] = [:]
        var quorumSize: UInt64 = 3
    }

    private let state = OSAllocatedUnfairLock(initialState: PresenceState())

    func fetchPresence(actor: Address, epochId: UInt64) async throws -> Presence? {
        let key = makeKey(actor: actor, epochId: epochId)
        return state.withLock { $0.presences[key] }
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

        let continuation = state.withLock { presenceState -> AsyncStream<PresenceEvent>.Continuation? in
            presenceState.presences[key] = presence
            return presenceState.eventContinuations[key]
        }

        continuation?.yield(.declared(presence))

        return presence
    }

    func subscribeToPresenceEvents(actor: Address, epochId: UInt64) -> AsyncStream<PresenceEvent> {
        let key = makeKey(actor: actor, epochId: epochId)

        return AsyncStream { [weak self] continuation in
            guard let self = self else { return }

            self.state.withLock { $0.eventContinuations[key] = continuation }

            continuation.onTermination = { [weak self] _ in
                _ = self?.state.withLock { $0.eventContinuations.removeValue(forKey: key) }
            }
        }
    }

    func unsubscribeFromPresenceEvents(actor: Address, epochId: UInt64) async {
        let key = makeKey(actor: actor, epochId: epochId)
        let continuation = state.withLock { $0.eventContinuations.removeValue(forKey: key) }
        continuation?.finish()
    }

    func fetchParticipants(epochId: UInt64) async throws -> [Presence] {
        let participants = state.withLock { $0.presences.values.filter { $0.epochId == epochId } }
        return Array(participants)
    }

    func fetchQuorumSize() async throws -> UInt64 {
        state.withLock { $0.quorumSize }
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
        state.withLock { $0.quorumSize = size }
    }

    func simulateValidation(actor: Address, epochId: UInt64) {
        let key = makeKey(actor: actor, epochId: epochId)

        state.withLock { presenceState in
            guard let presence = presenceState.presences[key] else { return }

            let validatedPresence = Presence(
                epochId: presence.epochId,
                actor: presence.actor,
                state: .validated,
                declaredAt: presence.declaredAt,
                validatedAt: Date(),
                validationCount: presenceState.quorumSize
            )
            presenceState.presences[key] = validatedPresence
            presenceState.eventContinuations[key]?.yield(.validated(validatedPresence))
        }
    }
}

// MARK: - In-Memory Ephemeral Cache Repository

/// In-memory implementation of EphemeralCacheRepositoryProtocol
/// Data is lost when app terminates (as per ephemerality requirement)
final class InMemoryEphemeralCacheRepository: EphemeralCacheRepositoryProtocol, @unchecked Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: [String: Data]())

    func store<T: Codable & Sendable>(_ value: T, key: String, epochId: UInt64) async {
        guard let data = try? JSONEncoder().encode(value) else { return }
        let storageKey = makeKey(key: key, epochId: epochId)

        storage.withLock { $0[storageKey] = data }
    }

    func retrieve<T: Codable & Sendable>(key: String, epochId: UInt64) async -> T? {
        let storageKey = makeKey(key: key, epochId: epochId)

        let data = storage.withLock { $0[storageKey] }

        guard let data = data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func delete(key: String, epochId: UInt64) async {
        let storageKey = makeKey(key: key, epochId: epochId)
        _ = storage.withLock { $0.removeValue(forKey: storageKey) }
    }

    func exists(key: String, epochId: UInt64) async -> Bool {
        let storageKey = makeKey(key: key, epochId: epochId)
        return storage.withLock { $0[storageKey] != nil }
    }

    func purgeEpoch(epochId: UInt64) async {
        let prefix = "\(epochId):"
        storage.withLock { $0 = $0.filter { !$0.key.hasPrefix(prefix) } }
    }

    func getCachedEpochIds() async -> [UInt64] {
        let keys = storage.withLock { Array($0.keys) }

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
        storage.withLock { $0.removeAll() }
    }

    // MARK: - Private Helpers

    private func makeKey(key: String, epochId: UInt64) -> String {
        "\(epochId):\(key)"
    }
}

// MARK: - Mock Time Capsule Repository

/// Mock implementation of TimeCapsuleRepositoryProtocol
final class MockTimeCapsuleRepository: TimeCapsuleRepositoryProtocol, @unchecked Sendable {
    private let capsules: OSAllocatedUnfairLock<[String: TimeCapsule]>

    init() {
        // Add some sample capsules
        let sample1 = TimeCapsule.mock(isUnlocked: false)
        let sample2 = TimeCapsule.mock(isUnlocked: true)
        var initialCapsules: [String: TimeCapsule] = [:]
        initialCapsules[sample1.id] = sample1
        initialCapsules[sample2.id] = sample2
        self.capsules = OSAllocatedUnfairLock(initialState: initialCapsules)
    }

    func create(_ capsule: TimeCapsule) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        capsules.withLock { $0[capsule.id] = capsule }
    }

    func fetchMyCapsules() async throws -> [TimeCapsule] {
        capsules.withLock { Array($0.values).sorted { $0.createdAt > $1.createdAt } }
    }

    func fetchUnlockable(for epochId: UInt64) async throws -> [TimeCapsule] {
        capsules.withLock {
            Array($0.values.filter { capsule in
                !capsule.isUnlocked && capsule.associatedEpochId == epochId
            })
        }
    }

    func unlock(_ capsuleId: String) async throws -> TimeCapsule {
        try await Task.sleep(nanoseconds: 500_000_000)

        return try capsules.withLock { capsulesDict -> TimeCapsule in
            guard var capsule = capsulesDict[capsuleId] else {
                throw NSError(domain: "TimeCapsule", code: 404, userInfo: [NSLocalizedDescriptionKey: "Capsule not found"])
            }
            capsule.isUnlocked = true
            capsule.unlockedAt = Date()
            capsulesDict[capsuleId] = capsule
            return capsule
        }
    }

    func delete(_ capsuleId: String) async throws {
        _ = capsules.withLock { $0.removeValue(forKey: capsuleId) }
    }
}

// MARK: - Mock Journey Repository

/// Mock implementation of JourneyRepositoryProtocol
final class MockJourneyRepository: JourneyRepositoryProtocol, @unchecked Sendable {
    private struct JourneyState {
        var journeys: [String: LapseJourney] = [:]
        var progressRecords: [String: JourneyProgress] = [:]
    }

    private let state: OSAllocatedUnfairLock<JourneyState>

    init() {
        var initialState = JourneyState()

        // Initialize with sample journeys
        for journey in LapseJourney.mockJourneys() {
            initialState.journeys[journey.id] = journey
        }

        // Add sample progress for one journey
        let sampleProgress = JourneyProgress.mock(journeyId: "journey-1", completedCount: 2)
        initialState.progressRecords["journey-1"] = sampleProgress

        self.state = OSAllocatedUnfairLock(initialState: initialState)
    }

    func fetchJourneys() async throws -> [LapseJourney] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return state.withLock { Array($0.journeys.values).sorted { $0.createdAt > $1.createdAt } }
    }

    func fetchJourney(id: String) async throws -> LapseJourney? {
        state.withLock { $0.journeys[id] }
    }

    func fetchJourneys(containing epochId: UInt64) async throws -> [LapseJourney] {
        state.withLock { Array($0.journeys.values.filter { $0.contains(epochId: epochId) }) }
    }

    func fetchProgress(for journeyId: String) async throws -> JourneyProgress? {
        state.withLock { $0.progressRecords[journeyId] }
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
        state.withLock { $0.progressRecords[journeyId] = progress }
        return progress
    }

    func completeEpoch(_ epochId: UInt64, in journeyId: String) async throws -> JourneyProgress {
        try await Task.sleep(nanoseconds: 300_000_000)

        return try state.withLock { journeyState -> JourneyProgress in
            guard var progress = journeyState.progressRecords[journeyId] else {
                throw NSError(domain: "Journey", code: 404, userInfo: [NSLocalizedDescriptionKey: "Journey progress not found"])
            }

            progress.completedEpochIds.insert(epochId)

            // Check if journey is fully completed
            if let journey = journeyState.journeys[journeyId] {
                if progress.completedEpochIds.count == journey.epochCount {
                    progress.completedAt = Date()
                }
            }

            journeyState.progressRecords[journeyId] = progress
            return progress
        }
    }

    func isJourneyCompleted(_ journeyId: String) async throws -> Bool {
        state.withLock { $0.progressRecords[journeyId]?.isJourneyCompleted ?? false }
    }

    func fetchMyJourneys() async throws -> [(journey: LapseJourney, progress: JourneyProgress)] {
        state.withLock { journeyState in
            var result: [(journey: LapseJourney, progress: JourneyProgress)] = []
            for (journeyId, progress) in journeyState.progressRecords {
                if let journey = journeyState.journeys[journeyId] {
                    result.append((journey: journey, progress: progress))
                }
            }
            return result.sorted { $0.progress.startedAt > $1.progress.startedAt }
        }
    }
}

// MARK: - Mock Prophecy Repository

/// Mock implementation of ProphecyRepositoryProtocol
final class MockProphecyRepository: ProphecyRepositoryProtocol, @unchecked Sendable {
    private let prophecies: OSAllocatedUnfairLock<[String: Prophecy]>
    private let currentUserId = "current-user"

    init() {
        var initialProphecies: [String: Prophecy] = [:]
        // Initialize with sample prophecies
        for prophecy in Prophecy.mockProphecies() {
            initialProphecies[prophecy.id] = prophecy
        }
        self.prophecies = OSAllocatedUnfairLock(initialState: initialProphecies)
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

        prophecies.withLock { $0[prophecy.id] = prophecy }

        return prophecy
    }

    func fetchMyProphecies() async throws -> [Prophecy] {
        prophecies.withLock {
            Array($0.values.filter { $0.userId == currentUserId }
                .sorted { $0.committedAt > $1.committedAt })
        }
    }

    func fetchProphecies(for epochId: UInt64) async throws -> [Prophecy] {
        prophecies.withLock {
            Array($0.values.filter { $0.epochId == epochId }
                .sorted { $0.committedAt > $1.committedAt })
        }
    }

    func fetchFriendProphecies() async throws -> [Prophecy] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return prophecies.withLock {
            // Return prophecies from other users (simulating "friends")
            Array($0.values.filter { $0.userId != currentUserId && $0.status == .pending }
                .sorted { $0.committedAt > $1.committedAt })
        }
    }

    func cancelProphecy(_ prophecyId: String) async throws {
        _ = prophecies.withLock { $0.removeValue(forKey: prophecyId) }
    }

    func hasProphecy(for epochId: UInt64) async throws -> Bool {
        prophecies.withLock { $0.values.contains { $0.epochId == epochId && $0.userId == currentUserId } }
    }

    func getProphecy(for epochId: UInt64) async throws -> Prophecy? {
        prophecies.withLock { $0.values.first { $0.epochId == epochId && $0.userId == currentUserId } }
    }

    func fetchProphecyStats() async throws -> ProphecyStats {
        prophecies.withLock { propheciesDict in
            let userProphecies = propheciesDict.values.filter { $0.userId == currentUserId }
            let fulfilled = userProphecies.filter { $0.status == .fulfilled }.count
            let broken = userProphecies.filter { $0.status == .broken }.count
            let pending = userProphecies.filter { $0.status == .pending }.count
            let totalStaked = userProphecies.reduce(0) { $0 + $1.stakeAmount }

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
}
