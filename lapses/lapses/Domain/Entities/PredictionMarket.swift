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
                endTime: now.addingTimeInterval(9900),
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
                endTime: now.addingTimeInterval(3600),
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
                endTime: now.addingTimeInterval(600),
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
                endTime: now.addingTimeInterval(18000),
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
                endTime: now.addingTimeInterval(-3600),
                createdAt: now.addingTimeInterval(-345600),
                outcome: .yes
            ),
            PredictionMarket(
                id: "market-6",
                epochId: 6,
                epochTitle: "Crypto Conference SF",
                predictionType: .participation,
                question: "Will attendance exceed 500 people?",
                targetValue: 500,
                yesPool: 5.2,
                noPool: 2.8,
                yesVoters: 342,
                noVoters: 189,
                endTime: now.addingTimeInterval(28800),
                createdAt: now.addingTimeInterval(-172800),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-7",
                epochId: 7,
                epochTitle: "Night Market Festival",
                predictionType: .epochSuccess,
                question: "Will vendors sell out by midnight?",
                targetValue: nil,
                yesPool: 1.8,
                noPool: 1.4,
                yesVoters: 124,
                noVoters: 98,
                endTime: now.addingTimeInterval(14400),
                createdAt: now.addingTimeInterval(-86400),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-8",
                epochId: 8,
                epochTitle: "Startup Pitch Night",
                predictionType: .creatorAttendance,
                question: "Will all 5 judges attend?",
                targetValue: nil,
                yesPool: 0.65,
                noPool: 0.35,
                yesVoters: 56,
                noVoters: 31,
                endTime: now.addingTimeInterval(7200),
                createdAt: now.addingTimeInterval(-28800),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-9",
                epochId: 9,
                epochTitle: "Rooftop DJ Set",
                predictionType: .participation,
                question: "Will capacity reach 200?",
                targetValue: 200,
                yesPool: 0.95,
                noPool: 0.55,
                yesVoters: 67,
                noVoters: 41,
                endTime: now.addingTimeInterval(21600),
                createdAt: now.addingTimeInterval(-43200),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-10",
                epochId: 10,
                epochTitle: "Meditation Retreat",
                predictionType: .epochSuccess,
                question: "Will all sessions complete on time?",
                targetValue: nil,
                yesPool: 0.72,
                noPool: 0.28,
                yesVoters: 89,
                noVoters: 23,
                endTime: now.addingTimeInterval(36000),
                createdAt: now.addingTimeInterval(-129600),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-11",
                epochId: 11,
                epochTitle: "Food Truck Rally",
                predictionType: .participation,
                question: "Will this reach 300+ visitors?",
                targetValue: 300,
                yesPool: 3.2,
                noPool: 1.1,
                yesVoters: 234,
                noVoters: 87,
                endTime: now.addingTimeInterval(1800),
                createdAt: now.addingTimeInterval(-259200),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-12",
                epochId: 12,
                epochTitle: "Outdoor Cinema Night",
                predictionType: .creatorAttendance,
                question: "Will the director do Q&A?",
                targetValue: nil,
                yesPool: 0.88,
                noPool: 0.42,
                yesVoters: 102,
                noVoters: 53,
                endTime: now.addingTimeInterval(10800),
                createdAt: now.addingTimeInterval(-64800),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-13",
                epochId: 13,
                epochTitle: "Marathon Training",
                predictionType: .epochSuccess,
                question: "Will 80% complete the route?",
                targetValue: nil,
                yesPool: 1.55,
                noPool: 0.95,
                yesVoters: 145,
                noVoters: 92,
                endTime: now.addingTimeInterval(5400),
                createdAt: now.addingTimeInterval(-194400),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-14",
                epochId: 14,
                epochTitle: "Web3 Hackathon",
                predictionType: .participation,
                question: "Will teams exceed 50?",
                targetValue: 50,
                yesPool: 4.5,
                noPool: 1.8,
                yesVoters: 312,
                noVoters: 134,
                endTime: now.addingTimeInterval(43200),
                createdAt: now.addingTimeInterval(-302400),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-15",
                epochId: 15,
                epochTitle: "Sunrise Hike",
                predictionType: .creatorAttendance,
                question: "Will the guide arrive by 5am?",
                targetValue: nil,
                yesPool: 0.38,
                noPool: 0.22,
                yesVoters: 45,
                noVoters: 28,
                endTime: now.addingTimeInterval(25200),
                createdAt: now.addingTimeInterval(-21600),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-16",
                epochId: 16,
                epochTitle: "Street Art Tour",
                predictionType: .epochSuccess,
                question: "Will all murals be visited?",
                targetValue: nil,
                yesPool: 0.62,
                noPool: 0.48,
                yesVoters: 78,
                noVoters: 62,
                endTime: now.addingTimeInterval(16200),
                createdAt: now.addingTimeInterval(-108000),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-17",
                epochId: 17,
                epochTitle: "Vinyl Record Swap",
                predictionType: .participation,
                question: "Will traders exceed 75?",
                targetValue: 75,
                yesPool: 0.55,
                noPool: 0.65,
                yesVoters: 42,
                noVoters: 51,
                endTime: now.addingTimeInterval(12600),
                createdAt: now.addingTimeInterval(-54000),
                outcome: nil
            ),
            PredictionMarket(
                id: "market-18",
                epochId: 18,
                epochTitle: "Coffee Cupping Session",
                predictionType: .creatorAttendance,
                question: "Will the roaster present?",
                targetValue: nil,
                yesPool: 0.85,
                noPool: 0.15,
                yesVoters: 98,
                noVoters: 17,
                endTime: now.addingTimeInterval(4500),
                createdAt: now.addingTimeInterval(-36000),
                outcome: nil
            )
        ]
    }
}
