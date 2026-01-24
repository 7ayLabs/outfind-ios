//
//  PredictionMarket.swift
//  lapses
//
//  Prediction markets for epoch outcomes
//

import Foundation

// MARK: - Prediction Type

enum PredictionType: String, Codable, CaseIterable, Sendable {
    case participation = "participation"
    case creatorAttendance = "creator_attendance"
    case epochSuccess = "epoch_success"

    var displayQuestion: String {
        switch self {
        case .participation:
            return "Will this epoch reach the target participants?"
        case .creatorAttendance:
            return "Will the creator attend their own epoch?"
        case .epochSuccess:
            return "Will this epoch be successful?"
        }
    }

    var icon: String {
        switch self {
        case .participation:
            return "person.3.fill"
        case .creatorAttendance:
            return "person.badge.clock.fill"
        case .epochSuccess:
            return "checkmark.seal.fill"
        }
    }
}

// MARK: - Prediction Side

enum PredictionSide: String, Codable, Sendable {
    case yes
    case no
}

// MARK: - Prediction Outcome

enum PredictionOutcome: String, Codable, Sendable {
    case yes
    case no
    case cancelled
}

// MARK: - Prediction Market

struct PredictionMarket: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: String
    let epochId: UInt64
    let epochTitle: String
    let predictionType: PredictionType
    let question: String
    let targetValue: Int?  // For participation type (e.g., 50 participants)
    let yesPool: Double
    let noPool: Double
    let yesVoters: Int
    let noVoters: Int
    let endTime: Date
    let createdAt: Date
    var outcome: PredictionOutcome?

    // MARK: - Computed Properties

    var totalPool: Double {
        yesPool + noPool
    }

    var totalVoters: Int {
        yesVoters + noVoters
    }

    var yesPercentage: Double {
        guard totalPool > 0 else { return 50.0 }
        return (yesPool / totalPool) * 100
    }

    var noPercentage: Double {
        guard totalPool > 0 else { return 50.0 }
        return (noPool / totalPool) * 100
    }

    var yesOdds: Double {
        guard yesPercentage > 0 else { return 0 }
        return 100 / yesPercentage
    }

    var noOdds: Double {
        guard noPercentage > 0 else { return 0 }
        return 100 / noPercentage
    }

    var timeRemaining: TimeInterval {
        endTime.timeIntervalSinceNow
    }

    var isActive: Bool {
        outcome == nil && timeRemaining > 0
    }

    var isResolved: Bool {
        outcome != nil
    }

    var formattedPool: String {
        if totalPool >= 1.0 {
            return String(format: "%.2f ETH", totalPool)
        } else {
            return String(format: "%.4f ETH", totalPool)
        }
    }

    var urgencyLevel: MarketUrgencyLevel {
        guard isActive else { return .none }
        let remaining = timeRemaining
        if remaining < 900 { return .critical }     // < 15 min
        if remaining < 3600 { return .high }        // < 1 hour
        if remaining < 14400 { return .moderate }   // < 4 hours
        return .normal
    }
}

// MARK: - Market Urgency Level

enum MarketUrgencyLevel: Sendable {
    case none
    case normal
    case moderate
    case high
    case critical
}

// MARK: - User Prediction

struct UserPrediction: Identifiable, Codable, Sendable {
    let id: String
    let marketId: String
    let userId: String
    let side: PredictionSide
    let amount: Double
    let placedAt: Date
    var payout: Double?

    var formattedAmount: String {
        if amount >= 1.0 {
            return String(format: "%.2f ETH", amount)
        } else {
            return String(format: "%.4f ETH", amount)
        }
    }
}

// MARK: - Mock Data

extension PredictionMarket {
    static func mockMarkets() -> [PredictionMarket] {
        let now = Date()
        return [
            PredictionMarket(
                id: "market-1",
                epochId: 1,
                epochTitle: "Sunset Yoga at Dolores Park",
                predictionType: .participation,
                question: "Will this epoch reach 50+ participants?",
                targetValue: 50,
                yesPool: 1.35,
                noPool: 0.82,
                yesVoters: 89,
                noVoters: 67,
                endTime: now.addingTimeInterval(9900), // ~2h 45m
                createdAt: now.addingTimeInterval(-86400),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-2",
                epochId: 2,
                epochTitle: "Tech Meetup Downtown",
                predictionType: .creatorAttendance,
                question: "Will the creator attend their own epoch?",
                targetValue: nil,
                yesPool: 0.45,
                noPool: 0.15,
                yesVoters: 34,
                noVoters: 12,
                endTime: now.addingTimeInterval(3600), // 1 hour
                createdAt: now.addingTimeInterval(-43200),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-3",
                epochId: 3,
                epochTitle: "Beach Cleanup Morning",
                predictionType: .epochSuccess,
                question: "Will this epoch be successful?",
                targetValue: nil,
                yesPool: 2.1,
                noPool: 0.9,
                yesVoters: 156,
                noVoters: 78,
                endTime: now.addingTimeInterval(600), // 10 min - urgent!
                createdAt: now.addingTimeInterval(-172800),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-4",
                epochId: 4,
                epochTitle: "Art Gallery Opening",
                predictionType: .participation,
                question: "Will this epoch reach 100+ participants?",
                targetValue: 100,
                yesPool: 0.8,
                noPool: 1.2,
                yesVoters: 45,
                noVoters: 72,
                endTime: now.addingTimeInterval(18000), // 5 hours
                createdAt: now.addingTimeInterval(-259200),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-5",
                epochId: 5,
                epochTitle: "Morning Run Club",
                predictionType: .epochSuccess,
                question: "Will this epoch be successful?",
                targetValue: nil,
                yesPool: 0.5,
                noPool: 0.3,
                yesVoters: 28,
                noVoters: 19,
                endTime: now.addingTimeInterval(-3600), // Ended 1 hour ago
                createdAt: now.addingTimeInterval(-345600),
                outcome: .yes
            )
        ]
    }
}
