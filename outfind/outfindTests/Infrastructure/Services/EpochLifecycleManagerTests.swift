import Testing
import Foundation
@testable import outfind

/// Tests for EpochLifecycleManager service
@MainActor
struct EpochLifecycleManagerTests {

    // MARK: - Setup Helpers

    private func createManager(
        epochRepo: TestEpochRepository = TestEpochRepository(),
        presenceRepo: TestPresenceRepository = TestPresenceRepository(),
        cacheRepo: TestEphemeralCacheRepository = TestEphemeralCacheRepository()
    ) -> (EpochLifecycleManager, TestEpochRepository, TestPresenceRepository, TestEphemeralCacheRepository) {
        let manager = EpochLifecycleManager(
            epochRepository: epochRepo,
            presenceRepository: presenceRepo,
            ephemeralCacheRepository: cacheRepo
        )
        return (manager, epochRepo, presenceRepo, cacheRepo)
    }

    // MARK: - Epoch Activation Tests

    @Test("activateEpoch adds epoch to activeEpochs")
    func activateEpochAddsToActiveEpochs() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 42, state: .active)

        await manager.activateEpoch(epoch)

        #expect(manager.activeEpochs[42] != nil)
        #expect(manager.currentEpochId == 42)
    }

    @Test("activateEpoch notifies observers when epoch is active")
    func activateEpochNotifiesObservers() async {
        let (manager, _, _, _) = createManager()
        let observer = TestLifecycleObserver()
        manager.addObserver(observer)

        let epoch = Epoch.mock(id: 1, state: .active)
        await manager.activateEpoch(epoch)

        #expect(observer.activatedEpochs.contains(1))
    }

    @Test("activateEpoch does not notify observers for scheduled epoch")
    func activateEpochDoesNotNotifyForScheduled() async {
        let (manager, _, _, _) = createManager()
        let observer = TestLifecycleObserver()
        manager.addObserver(observer)

        let epoch = Epoch.mock(id: 1, state: .scheduled)
        await manager.activateEpoch(epoch)

        #expect(observer.activatedEpochs.isEmpty)
    }

    @Test("activateEpoch sets correct monitor state")
    func activateEpochSetsCorrectMonitorState() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 1, state: .active, participantCount: 100)

        await manager.activateEpoch(epoch)

        let state = manager.activeEpochs[1]
        #expect(state?.epoch.id == 1)
        #expect(state?.isActive == true)
        #expect(state?.participantCount == 100)
    }

    // MARK: - Deactivation Tests

    @Test("deactivateEpoch removes epoch from activeEpochs")
    func deactivateEpochRemovesFromActiveEpochs() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 1, state: .active)

        await manager.activateEpoch(epoch)
        #expect(manager.activeEpochs[1] != nil)

        await manager.deactivateEpoch(1)
        #expect(manager.activeEpochs[1] == nil)
    }

    @Test("deactivateEpoch clears currentEpochId if matching")
    func deactivateEpochClearsCurrentEpochId() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 1, state: .active)

        await manager.activateEpoch(epoch)
        #expect(manager.currentEpochId == 1)

        await manager.deactivateEpoch(1)
        #expect(manager.currentEpochId == nil)
    }

    // MARK: - Observer Management Tests

    @Test("addObserver registers observer")
    func addObserverRegistersObserver() async {
        let (manager, _, _, _) = createManager()
        let observer = TestLifecycleObserver()

        manager.addObserver(observer)

        // Verify by triggering an event
        let epoch = Epoch.mock(id: 1, state: .active)
        await manager.activateEpoch(epoch)

        #expect(observer.activatedEpochs.contains(1))
    }

    @Test("removeObserver unregisters observer")
    func removeObserverUnregistersObserver() async {
        let (manager, _, _, _) = createManager()
        let observer = TestLifecycleObserver()

        manager.addObserver(observer)
        manager.removeObserver(observer)

        let epoch = Epoch.mock(id: 1, state: .active)
        await manager.activateEpoch(epoch)

        #expect(observer.activatedEpochs.isEmpty)
    }

    // MARK: - Presence Management Tests

    @Test("updatePresence updates presence in monitor state")
    func updatePresenceUpdatesMonitorState() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 1, state: .active)
        await manager.activateEpoch(epoch)

        let presence = Presence.mock(epochId: 1, state: .validated)
        manager.updatePresence(presence, for: 1)

        #expect(manager.activeEpochs[1]?.presence == presence)
    }

    @Test("updatePresence notifies observers")
    func updatePresenceNotifiesObservers() async {
        let (manager, _, _, _) = createManager()
        let observer = TestLifecycleObserver()
        manager.addObserver(observer)

        let epoch = Epoch.mock(id: 1, state: .active)
        await manager.activateEpoch(epoch)

        let presence = Presence.mock(epochId: 1, state: .declared)
        manager.updatePresence(presence, for: 1)

        #expect(observer.presenceUpdates.count == 1)
        #expect(observer.presenceUpdates.first?.epochId == 1)
    }

    // MARK: - Startup Cleanup Tests (INV14)

    @Test("performStartupCleanup purges closed epoch data")
    func performStartupCleanupPurgesClosedEpochs() async {
        let cacheRepo = TestEphemeralCacheRepository()
        let epochRepo = TestEpochRepository()
        epochRepo.epochs[1] = Epoch.mock(id: 1, state: .closed)
        epochRepo.epochs[2] = Epoch.mock(id: 2, state: .active)

        // Store some data for both epochs
        await cacheRepo.store("test1", key: "data", epochId: 1)
        await cacheRepo.store("test2", key: "data", epochId: 2)

        let (manager, _, _, _) = createManager(
            epochRepo: epochRepo,
            cacheRepo: cacheRepo
        )

        await manager.performStartupCleanup()

        #expect(cacheRepo.purgedEpochIds.contains(1))
        #expect(!cacheRepo.purgedEpochIds.contains(2))
    }

    @Test("performStartupCleanup purges finalized epoch data")
    func performStartupCleanupPurgesFinalizedEpochs() async {
        let cacheRepo = TestEphemeralCacheRepository()
        let epochRepo = TestEpochRepository()
        epochRepo.epochs[1] = Epoch.mock(id: 1, state: .finalized)

        await cacheRepo.store("test", key: "data", epochId: 1)

        let (manager, _, _, _) = createManager(
            epochRepo: epochRepo,
            cacheRepo: cacheRepo
        )

        await manager.performStartupCleanup()

        #expect(cacheRepo.purgedEpochIds.contains(1))
    }

    @Test("performStartupCleanup purges on fetch error (assume closed)")
    func performStartupCleanupPurgesOnFetchError() async {
        let cacheRepo = TestEphemeralCacheRepository()
        let epochRepo = TestEpochRepository()
        epochRepo.shouldThrowError = true

        await cacheRepo.store("test", key: "data", epochId: 999)

        let (manager, _, _, _) = createManager(
            epochRepo: epochRepo,
            cacheRepo: cacheRepo
        )

        await manager.performStartupCleanup()

        // Should purge because fetch failed (assume closed)
        #expect(cacheRepo.purgedEpochIds.contains(999))
    }

    // MARK: - Convenience Accessor Tests

    @Test("currentEpochState returns state for current epoch")
    func currentEpochStateReturnsCorrectState() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 1, state: .active)

        await manager.activateEpoch(epoch)

        let state = manager.currentEpochState
        #expect(state?.epoch.id == 1)
    }

    @Test("currentEpochState returns nil when no current epoch")
    func currentEpochStateReturnsNilWhenNone() async {
        let (manager, _, _, _) = createManager()
        #expect(manager.currentEpochState == nil)
    }

    @Test("isMonitoring returns true for active epoch")
    func isMonitoringReturnsTrueForActiveEpoch() async {
        let (manager, _, _, _) = createManager()
        let epoch = Epoch.mock(id: 1, state: .active)

        await manager.activateEpoch(epoch)

        #expect(manager.isMonitoring(epochId: 1) == true)
        #expect(manager.isMonitoring(epochId: 2) == false)
    }
}

// MARK: - EpochMonitorState Tests

struct EpochMonitorStateTests {

    @Test("initializes with epoch values")
    func initializesWithEpochValues() {
        let epoch = Epoch.mock(id: 1, state: .active, participantCount: 50)
        let state = EpochMonitorState(epoch: epoch)

        #expect(state.epoch.id == 1)
        #expect(state.participantCount == 50)
        #expect(state.isActive == true)
        #expect(state.presence == nil)
        #expect(state.error == nil)
    }

    @Test("initializes with presence")
    func initializesWithPresence() {
        let epoch = Epoch.mock(id: 1, state: .active)
        let presence = Presence.mock(epochId: 1, state: .validated)
        let state = EpochMonitorState(epoch: epoch, presence: presence)

        #expect(state.presence == presence)
    }

    @Test("isActive reflects epoch state")
    func isActiveReflectsEpochState() {
        let activeEpoch = Epoch.mock(state: .active)
        let scheduledEpoch = Epoch.mock(state: .scheduled)

        #expect(EpochMonitorState(epoch: activeEpoch).isActive == true)
        #expect(EpochMonitorState(epoch: scheduledEpoch).isActive == false)
    }
}
