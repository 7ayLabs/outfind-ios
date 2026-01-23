import Foundation

// MARK: - Lapse Journey

/// A curated path connecting multiple epochs into a storyline
/// Complete all epochs to unlock special rewards
struct LapseJourney: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let description: String
    let epochIds: [UInt64]
    let creatorId: String
    let completionNFTMetadata: String?
    let createdAt: Date

    var epochCount: Int { epochIds.count }

    func contains(epochId: UInt64) -> Bool {
        epochIds.contains(epochId)
    }

    func orderOf(epochId: UInt64) -> Int? {
        guard let index = epochIds.firstIndex(of: epochId) else { return nil }
        return index + 1
    }
}

// MARK: - Journey Progress

struct JourneyProgress: Identifiable, Codable, Sendable {
    var id: String { journeyId }
    let journeyId: String
    let userId: String
    var completedEpochIds: Set<UInt64>
    var startedAt: Date
    var completedAt: Date?

    func progress(totalEpochs: Int) -> Double {
        guard totalEpochs > 0 else { return 0 }
        return Double(completedEpochIds.count) / Double(totalEpochs)
    }

    func isCompleted(epochId: UInt64) -> Bool {
        completedEpochIds.contains(epochId)
    }

    var isJourneyCompleted: Bool { completedAt != nil }
}

// MARK: - Factory Methods

extension LapseJourney {
    static func mock() -> LapseJourney {
        LapseJourney(
            id: UUID().uuidString,
            title: "Art Walk SF",
            description: "Explore 5 iconic art locations across San Francisco",
            epochIds: [1, 2, 3, 4, 5],
            creatorId: "creator-1",
            completionNFTMetadata: "ipfs://completion-nft",
            createdAt: Date().addingTimeInterval(-86400 * 7)
        )
    }

    static func mockJourneys() -> [LapseJourney] {
        [
            LapseJourney(
                id: "journey-1",
                title: "Art Walk SF",
                description: "Explore 5 iconic art locations",
                epochIds: [1, 2, 3],
                creatorId: "creator-1",
                completionNFTMetadata: "ipfs://art-walk-nft",
                createdAt: Date().addingTimeInterval(-86400 * 7)
            ),
            LapseJourney(
                id: "journey-2",
                title: "Coffee Trail",
                description: "Visit the best coffee spots",
                epochIds: [4, 5, 6, 7],
                creatorId: "creator-2",
                completionNFTMetadata: nil,
                createdAt: Date().addingTimeInterval(-86400 * 3)
            ),
            LapseJourney(
                id: "journey-3",
                title: "Tech Tour",
                description: "Experience SF's tech scene",
                epochIds: [1, 4],
                creatorId: "creator-1",
                completionNFTMetadata: "ipfs://tech-tour-nft",
                createdAt: Date().addingTimeInterval(-86400)
            )
        ]
    }
}

extension JourneyProgress {
    static func mock(journeyId: String, completedCount: Int = 2) -> JourneyProgress {
        JourneyProgress(
            journeyId: journeyId,
            userId: "user-1",
            completedEpochIds: Set([1, 2].prefix(completedCount).map { UInt64($0) }),
            startedAt: Date().addingTimeInterval(-86400 * 3),
            completedAt: nil
        )
    }
}
