import Foundation

// MARK: - Epoch Lifecycle Observer Protocol

/// Observer protocol for epoch lifecycle events.
/// Implement this protocol to receive notifications about epoch state changes.
///
/// All methods have default empty implementations, so only override what you need.
protocol EpochLifecycleObserver: AnyObject {
    func epochDidActivate(_ epochId: UInt64)
    func epochDidClose(_ epochId: UInt64)
    func epochDidFinalize(_ epochId: UInt64)
    func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval)
    func presenceDidUpdate(_ presence: Presence, for epochId: UInt64)
}

/// Default implementation for optional observer methods.
extension EpochLifecycleObserver {
    func epochDidActivate(_ epochId: UInt64) {}
    func epochDidClose(_ epochId: UInt64) {}
    func epochDidFinalize(_ epochId: UInt64) {}
    func epochTimerDidTick(_ epochId: UInt64, timeRemaining: TimeInterval) {}
    func presenceDidUpdate(_ presence: Presence, for epochId: UInt64) {}
}

// MARK: - Epoch Monitor State

/// Represents the current monitoring state for an epoch.
/// Conforms to `Sendable` for safe passing across actor boundaries.
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

/// Manages epoch lifecycle and enforces ephemerality invariants.
///
/// ## Protocol Invariants Enforced
/// - **INV14**: Ephemeral data only during Active epoch - purges cache on close
/// - **INV29**: Media inaccessible after epoch closes - deletes on close
///
/// ## Architecture
/// Uses the Observer pattern to notify interested parties of lifecycle events.
/// All state is `@MainActor` isolated for thread-safe UI updates.
@Observable
@MainActor
final class EpochLifecycleManager {

    // MARK: - Observable State

    /// Currently active epochs being monitored. Key is epoch ID.
    private(set) var activeEpochs: [UInt64: EpochMonitorState] = [:]

    /// ID of the currently focused epoch (most recently activated).
    private(set) var currentEpochId: UInt64?

    // MARK: - Dependencies

    @ObservationIgnored
    private let epochRepository: any EpochRepositoryProtocol

    @ObservationIgnored
    private let presenceRepository: any PresenceRepositoryProtocol

    @ObservationIgnored
    private let ephemeralCacheRepository: any EphemeralCacheRepositoryProtocol

    // MARK: - Observers

    /// Weak references to observers to avoid retain cycles.
    @ObservationIgnored
    private var observers: [ObjectIdentifier: WeakObserver] = [:]

    private struct WeakObserver {
        weak var observer: (any EpochLifecycleObserver)?
    }

    // MARK: - Background Tasks

    /// Tasks monitoring epoch events. Key is epoch ID.
    @ObservationIgnored
    private var monitorTasks: [UInt64: Task<Void, Never>] = [:]

    /// Tasks running phase timers. Key is epoch ID.
    @ObservationIgnored
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

    /// Register an observer for lifecycle events.
    func addObserver(_ observer: any EpochLifecycleObserver) {
        let id = ObjectIdentifier(observer)
        observers[id] = WeakObserver(observer: observer)
    }

    /// Unregister an observer.
    func removeObserver(_ observer: any EpochLifecycleObserver) {
        let id = ObjectIdentifier(observer)
        observers.removeValue(forKey: id)
    }

    /// Notify all registered observers, cleaning up any deallocated ones.
    private func notifyObservers(_ action: (any EpochLifecycleObserver) -> Void) {
        observers = observers.filter { $0.value.observer != nil }
        for (_, weakObserver) in observers {
            if let observer = weakObserver.observer {
                action(observer)
            }
        }
    }

    // MARK: - Epoch Activation

    /// Start monitoring an epoch.
    /// - Parameter epoch: The epoch to monitor.
    func activateEpoch(_ epoch: Epoch) async {
        let epochId = epoch.id

        activeEpochs[epochId] = EpochMonitorState(epoch: epoch)
        startPhaseTimer(for: epoch)
        startMonitoring(epochId: epochId)
        currentEpochId = epochId

        if epoch.state == .active {
            notifyObservers { $0.epochDidActivate(epochId) }
        }
    }

    /// Stop monitoring an epoch and clean up resources.
    /// - Parameter epochId: The epoch ID to deactivate.
    func deactivateEpoch(_ epochId: UInt64) async {
        monitorTasks[epochId]?.cancel()
        monitorTasks.removeValue(forKey: epochId)

        timerTasks[epochId]?.cancel()
        timerTasks.removeValue(forKey: epochId)

        await epochRepository.unsubscribeFromEpochEvents(id: epochId)
        activeEpochs.removeValue(forKey: epochId)

        if currentEpochId == epochId {
            currentEpochId = nil
        }
    }

    // MARK: - Phase Timer

    private func startPhaseTimer(for epoch: Epoch) {
        let epochId = epoch.id

        timerTasks[epochId]?.cancel()
        timerTasks[epochId] = Task { @MainActor [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard let state = activeEpochs[epochId] else { break }

                let timeRemaining = state.epoch.timeUntilNextPhase

                if timeRemaining <= 0 {
                    await handlePhaseTransition(epochId: epochId)
                    break
                }

                // Update state directly (we're on MainActor)
                activeEpochs[epochId]?.timeRemaining = timeRemaining
                notifyObservers { $0.epochTimerDidTick(epochId, timeRemaining: timeRemaining) }

                // Tick faster when close to expiry
                let tickInterval: UInt64 = timeRemaining > 60 ? 1_000_000_000 : 100_000_000
                try? await Task.sleep(nanoseconds: tickInterval)
            }
        }
    }

    // MARK: - Phase Transitions

    private func handlePhaseTransition(epochId: UInt64) async {
        do {
            let updatedEpoch = try await epochRepository.fetchEpoch(id: epochId)

            activeEpochs[epochId] = EpochMonitorState(
                epoch: updatedEpoch,
                presence: activeEpochs[epochId]?.presence
            )

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

            if !updatedEpoch.state.isTerminal {
                startPhaseTimer(for: updatedEpoch)
            }

        } catch {
            await deactivateEpoch(epochId)
        }
    }

    private func handleEpochActivated(epochId: UInt64) async {
        activeEpochs[epochId]?.isActive = true
        NotificationCenter.default.post(name: .epochActivated, object: epochId)
        notifyObservers { $0.epochDidActivate(epochId) }
    }

    /// Handles epoch closure - CRITICAL for INV14 and INV29.
    /// Purges all ephemeral data associated with this epoch.
    private func handleEpochClosed(epochId: UInt64) async {
        // 1. Mark as inactive
        activeEpochs[epochId]?.isActive = false

        // 2. Purge all ephemeral cache data (INV14)
        await ephemeralCacheRepository.purgeEpoch(epochId: epochId)

        // 3. Post notification for UI cleanup
        NotificationCenter.default.post(name: .epochClosed, object: epochId)

        // 4. Notify observers
        notifyObservers { $0.epochDidClose(epochId) }
    }

    /// Handles epoch finalization - ensures complete cleanup.
    private func handleEpochFinalized(epochId: UInt64) async {
        await ephemeralCacheRepository.purgeEpoch(epochId: epochId)
        NotificationCenter.default.post(name: .epochFinalized, object: epochId)
        notifyObservers { $0.epochDidFinalize(epochId) }
        await deactivateEpoch(epochId)
    }

    // MARK: - Event Monitoring

    private func startMonitoring(epochId: UInt64) {
        monitorTasks[epochId]?.cancel()
        monitorTasks[epochId] = Task { @MainActor [weak self] in
            guard let self else { return }

            for await event in epochRepository.subscribeToEpochEvents(id: epochId) {
                guard !Task.isCancelled else { break }
                await handleEpochEvent(epochId: epochId, event: event)
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
            activeEpochs[epochId]?.participantCount = count

        case .timerTick(let remaining):
            activeEpochs[epochId]?.timeRemaining = remaining

        case .closed:
            await handleEpochClosed(epochId: epochId)

        case .finalized:
            await handleEpochFinalized(epochId: epochId)

        case .error(let message):
            activeEpochs[epochId]?.error = message
        }
    }

    // MARK: - Presence Management

    /// Update presence state for an epoch.
    func updatePresence(_ presence: Presence, for epochId: UInt64) {
        activeEpochs[epochId]?.presence = presence
        notifyObservers { $0.presenceDidUpdate(presence, for: epochId) }
    }

    // MARK: - Startup Cleanup

    /// Cleans up stale data from previous sessions.
    /// Called on app launch to enforce INV14.
    func performStartupCleanup() async {
        let cachedEpochIds = await ephemeralCacheRepository.getCachedEpochIds()
        var closedEpochIds: [UInt64] = []

        for epochId in cachedEpochIds {
            do {
                let state = try await epochRepository.fetchEpochState(id: epochId)
                if state == .closed || state == .finalized {
                    closedEpochIds.append(epochId)
                }
            } catch {
                // Can't verify epoch state, assume it's closed
                closedEpochIds.append(epochId)
            }
        }

        await ephemeralCacheRepository.purgeExpiredEpochs(closedEpochIds: closedEpochIds)
    }

    // MARK: - Convenience Accessors

    /// Returns the state of the currently focused epoch, if any.
    var currentEpochState: EpochMonitorState? {
        guard let epochId = currentEpochId else { return nil }
        return activeEpochs[epochId]
    }

    /// Checks if a specific epoch is being monitored.
    func isMonitoring(epochId: UInt64) -> Bool {
        activeEpochs[epochId] != nil
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when an epoch becomes active.
    static let epochActivated = Notification.Name("lapses.epochActivated")

    /// Posted when an epoch closes. INV14/INV29 cleanup has been triggered.
    static let epochClosed = Notification.Name("lapses.epochClosed")

    /// Posted when an epoch is finalized.
    static let epochFinalized = Notification.Name("lapses.epochFinalized")
}
