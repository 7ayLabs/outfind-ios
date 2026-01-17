import Foundation

// MARK: - Epoch Lifecycle Observer Protocol

/// Observer protocol for epoch lifecycle events
protocol EpochLifecycleObserver: AnyObject {
    func epochDidActivate(_ epochId: UInt64)
    func epochDidClose(_ epochId: UInt64)
    func epochDidFinalize(_ epochId: UInt64)
    func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval)
    func presenceDidUpdate(_ presence: Presence, for epochId: UInt64)
}

/// Default implementation for optional methods
extension EpochLifecycleObserver {
    func epochDidActivate(_ epochId: UInt64) {}
    func epochDidClose(_ epochId: UInt64) {}
    func epochDidFinalize(_ epochId: UInt64) {}
    func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval) {}
    func presenceDidUpdate(_ presence: Presence, for epochId: UInt64) {}
}

// MARK: - Epoch Monitor State

/// State for a monitored epoch
struct EpochMonitorState: Sendable {
    let epoch: Epoch
    var presence: Presence?
    var timeRemaining: TimeInterval
    var participantCount: UInt64
    var isActive: Bool
    var error: String?

    init(epoch: Epoch, presence: Presence? = nil) {
        self.epoch = epoch
        self.presence = presence
        self.timeRemaining = epoch.timeUntilNextPhase
        self.participantCount = epoch.participantCount
        self.isActive = epoch.state == .active
        self.error = nil
    }
}

// MARK: - Epoch Lifecycle Manager

/// Manages epoch lifecycle and enforces ephemerality invariants (INV14, INV29)
/// Uses Observer pattern for notifying interested parties of lifecycle events
@Observable
@MainActor
final class EpochLifecycleManager {

    // MARK: - Observable State

    private(set) var activeEpochs: [UInt64: EpochMonitorState] = [:]
    private(set) var currentEpochId: UInt64?

    // MARK: - Dependencies

    private let epochRepository: any EpochRepositoryProtocol
    private let presenceRepository: any PresenceRepositoryProtocol
    private let ephemeralCacheRepository: any EphemeralCacheRepositoryProtocol

    // MARK: - Observers (Weak references to avoid retain cycles)

    private var observers: [ObjectIdentifier: WeakObserver] = [:]

    private struct WeakObserver {
        weak var observer: (any EpochLifecycleObserver)?
    }

    // MARK: - Tasks

    private var monitorTasks: [UInt64: Task<Void, Never>] = [:]
    private var timerTasks: [UInt64: Task<Void, Never>] = [:]

    // MARK: - Initialization

    init(
        epochRepository: any EpochRepositoryProtocol,
        presenceRepository: any PresenceRepositoryProtocol,
        ephemeralCacheRepository: any EphemeralCacheRepositoryProtocol
    ) {
        self.epochRepository = epochRepository
        self.presenceRepository = presenceRepository
        self.ephemeralCacheRepository = ephemeralCacheRepository
    }

    // MARK: - Observer Management

    func addObserver(_ observer: any EpochLifecycleObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = WeakObserver(observer: observer)
    }

    func removeObserver(_ observer: any EpochLifecycleObserver) {
        let id = ObjectIdentifier(observer)
        observers.removeValue(forKey: id)
    }

    private func notifyObservers(_ action: (any EpochLifecycleObserver) -> Void) {
        // Clean up nil references and notify active observers
        observers = observers.filter { $0.value.observer != nil }
        for (_, weakObserver) in observers {
            if let observer = weakObserver.observer {
                action(observer)
            }
        }
    }

    // MARK: - Epoch Activation

    /// Activate monitoring for an epoch
    func activateEpoch(_ epoch: Epoch) async {
        let epochId = epoch.id

        // Create monitor state
        activeEpochs[epochId] = EpochMonitorState(epoch: epoch)

        // Start phase timer
        startPhaseTimer(for: epoch)

        // Subscribe to epoch events
        startMonitoring(epochId: epochId)

        // Set as current epoch
        currentEpochId = epochId

        // Notify observers
        if epoch.state == .active {
            notifyObservers { $0.epochDidActivate(epochId) }
        }
    }

    /// Deactivate monitoring for an epoch
    func deactivateEpoch(_ epochId: UInt64) async {
        // Cancel running tasks
        monitorTasks[epochId]?.cancel()
        monitorTasks.removeValue(forKey: epochId)

        timerTasks[epochId]?.cancel()
        timerTasks.removeValue(forKey: epochId)

        // Unsubscribe from events
        await epochRepository.unsubscribeFromEpochEvents(id: epochId)

        // Remove state
        activeEpochs.removeValue(forKey: epochId)

        // Clear current if this was it
        if currentEpochId == epochId {
            currentEpochId = nil
        }
    }

    // MARK: - Phase Timer

    private func startPhaseTimer(for epoch: Epoch) {
        let epochId = epoch.id

        timerTasks[epochId]?.cancel()
        timerTasks[epochId] = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
                guard let state = await self.activeEpochs[epochId] else { break }

                let timeRemaining = state.epoch.timeUntilNextPhase

                if timeRemaining <= 0 {
                    await self.handlePhaseTransition(epochId: epochId)
                    break
                }

                // Update state
                await MainActor.run {
                    self.activeEpochs[epochId]?.timeRemaining = timeRemaining
                }

                // Notify observers
                await MainActor.run {
                    self.notifyObservers { $0.epochTimerDidTick(epochId, timeRemaining: timeRemaining) }
                }

                // Tick interval based on time remaining
                let tickInterval: UInt64 = timeRemaining > 60 ? 1_000_000_000 : 100_000_000
                try? await Task.sleep(nanoseconds: tickInterval)
            }
        }
    }

    // MARK: - Phase Transitions

    private func handlePhaseTransition(epochId: UInt64) async {
        do {
            // Fetch updated epoch state
            let updatedEpoch = try await epochRepository.fetchEpoch(id: epochId)

            await MainActor.run {
                activeEpochs[epochId] = EpochMonitorState(
                    epoch: updatedEpoch,
                    presence: activeEpochs[epochId]?.presence
                )
            }

            switch updatedEpoch.state {
            case .active:
                await handleEpochActivated(epochId: epochId)
            case .closed:
                await handleEpochClosed(epochId: epochId)
            case .finalized:
                await handleEpochFinalized(epochId: epochId)
            case .scheduled, .none:
                break
            }

            // Restart timer for next phase if not terminal
            if !updatedEpoch.state.isTerminal {
                startPhaseTimer(for: updatedEpoch)
            }

        } catch {
            // Epoch may have been removed, deactivate
            await deactivateEpoch(epochId)
        }
    }

    private func handleEpochActivated(epochId: UInt64) async {
        await MainActor.run {
            activeEpochs[epochId]?.isActive = true
        }

        // Post notification
        NotificationCenter.default.post(name: .epochActivated, object: epochId)

        // Notify observers
        notifyObservers { $0.epochDidActivate(epochId) }
    }

    /// CRITICAL: Implements INV14, INV29 - purge all ephemeral data
    private func handleEpochClosed(epochId: UInt64) async {
        // 1. Mark as inactive
        await MainActor.run {
            activeEpochs[epochId]?.isActive = false
        }

        // 2. Purge all ephemeral cache data (INV14)
        await ephemeralCacheRepository.purgeEpoch(epochId: epochId)

        // 3. Post notification for UI cleanup
        NotificationCenter.default.post(name: .epochClosed, object: epochId)

        // 4. Notify observers
        notifyObservers { $0.epochDidClose(epochId) }
    }

    /// Final cleanup when epoch is finalized
    private func handleEpochFinalized(epochId: UInt64) async {
        // Ensure all data is purged
        await ephemeralCacheRepository.purgeEpoch(epochId: epochId)

        // Post notification
        NotificationCenter.default.post(name: .epochFinalized, object: epochId)

        // Notify observers
        notifyObservers { $0.epochDidFinalize(epochId) }

        // Deactivate monitoring
        await deactivateEpoch(epochId)
    }

    // MARK: - Event Monitoring

    private func startMonitoring(epochId: UInt64) {
        monitorTasks[epochId]?.cancel()
        monitorTasks[epochId] = Task { [weak self] in
            guard let self = self else { return }

            for await event in self.epochRepository.subscribeToEpochEvents(id: epochId) {
                await self.handleEpochEvent(epochId: epochId, event: event)
            }
        }
    }

    private func handleEpochEvent(epochId: UInt64, event: EpochEvent) async {
        switch event {
        case .phaseChanged(let phase):
            if phase == .closed {
                await handleEpochClosed(epochId: epochId)
            } else if phase == .finalized {
                await handleEpochFinalized(epochId: epochId)
            }

        case .participantCountChanged(let count):
            await MainActor.run {
                activeEpochs[epochId]?.participantCount = count
            }

        case .timerTick(let remaining):
            await MainActor.run {
                activeEpochs[epochId]?.timeRemaining = remaining
            }

        case .closed:
            await handleEpochClosed(epochId: epochId)

        case .finalized:
            await handleEpochFinalized(epochId: epochId)

        case .error(let message):
            await MainActor.run {
                activeEpochs[epochId]?.error = message
            }
        }
    }

    // MARK: - Presence Management

    /// Update presence for an epoch
    func updatePresence(_ presence: Presence, for epochId: UInt64) {
        activeEpochs[epochId]?.presence = presence
        notifyObservers { $0.presenceDidUpdate(presence, for: epochId) }
    }

    // MARK: - Startup Cleanup

    /// Called on app launch to clean up stale data from previous sessions
    func performStartupCleanup() async {
        // Get all cached epoch IDs
        let cachedEpochIds = await ephemeralCacheRepository.getCachedEpochIds()

        // Check each epoch's state and identify closed ones
        var closedEpochIds: [UInt64] = []

        for epochId in cachedEpochIds {
            do {
                let state = try await epochRepository.fetchEpochState(id: epochId)
                if state == .closed || state == .finalized {
                    closedEpochIds.append(epochId)
                }
            } catch {
                // If we can't fetch the epoch, assume it's closed
                closedEpochIds.append(epochId)
            }
        }

        // Purge all closed epochs (INV14 enforcement)
        await ephemeralCacheRepository.purgeExpiredEpochs(closedEpochIds: closedEpochIds)
    }

    // MARK: - Convenience Methods

    /// Get the current epoch state if active
    var currentEpochState: EpochMonitorState? {
        guard let epochId = currentEpochId else { return nil }
        return activeEpochs[epochId]
    }

    /// Check if a specific epoch is currently being monitored
    func isMonitoring(epochId: UInt64) -> Bool {
        activeEpochs[epochId] != nil
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when an epoch becomes active
    static let epochActivated = Notification.Name("outfind.epochActivated")

    /// Posted when an epoch closes (INV14, INV29 cleanup triggered)
    static let epochClosed = Notification.Name("outfind.epochClosed")

    /// Posted when an epoch is finalized
    static let epochFinalized = Notification.Name("outfind.epochFinalized")
}
