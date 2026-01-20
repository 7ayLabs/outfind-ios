import Foundation

// MARK: - Journey Repository Protocol

/// Repository protocol for managing Lapse Journeys
/// Journeys connect multiple epochs into curated paths with completion rewards
protocol JourneyRepositoryProtocol: Sendable {
    /// Fetch all available journeys
    func fetchJourneys() async throws -> [LapseJourney]

    /// Fetch a specific journey by ID
    func fetchJourney(id: String) async throws -> LapseJourney?

    /// Fetch journeys that contain a specific epoch
    func fetchJourneys(containing epochId: UInt64) async throws -> [LapseJourney]

    /// Fetch user's progress on a journey
    func fetchProgress(for journeyId: String) async throws -> JourneyProgress?

    /// Start a journey (creates progress record)
    func startJourney(_ journeyId: String) async throws -> JourneyProgress

    /// Mark an epoch as completed in a journey
    func completeEpoch(_ epochId: UInt64, in journeyId: String) async throws -> JourneyProgress

    /// Check if user has completed a journey
    func isJourneyCompleted(_ journeyId: String) async throws -> Bool

    /// Fetch all journeys the user has started
    func fetchMyJourneys() async throws -> [(journey: LapseJourney, progress: JourneyProgress)]
}
