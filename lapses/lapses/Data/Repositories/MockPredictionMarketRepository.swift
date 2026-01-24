//
//  MockPredictionMarketRepository.swift
//  lapses
//
//  Mock implementation of prediction market repository
//

import Foundation
import os.lock

/// Mock implementation of PredictionMarketRepositoryProtocol
final class MockPredictionMarketRepository: PredictionMarketRepositoryProtocol, @unchecked Sendable {

    // MARK: - Thread-Safe State

    private struct State {
        var markets: [String: PredictionMarket]
        var userPredictions: [String: UserPrediction]
    }

    private let state: OSAllocatedUnfairLock<State>

    // MARK: - Initialization

    init() {
        let initialMarkets = Dictionary(
            uniqueKeysWithValues: PredictionMarket.mockMarkets().map { ($0.id, $0) }
        )

        self.state = OSAllocatedUnfairLock(initialState: State(
            markets: initialMarkets,
            userPredictions: [:]
        ))
    }

    // MARK: - Fetch Markets

    func fetchActiveMarkets() async throws -> [PredictionMarket] {
        try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay

        return state.withLock { state in
            state.markets.values
                .filter { $0.isActive }
                .sorted { $0.endTime < $1.endTime }
        }
    }

    func fetchTrendingMarkets() async throws -> [PredictionMarket] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return state.withLock { state in
            state.markets.values
                .filter { $0.isActive }
                .sorted { $0.totalPool > $1.totalPool }
        }
    }

    func fetchMarketsForEpoch(epochId: UInt64) async throws -> [PredictionMarket] {
        try await Task.sleep(nanoseconds: 200_000_000)

        return state.withLock { state in
            state.markets.values
                .filter { $0.epochId == epochId }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    func fetchMarket(id: String) async throws -> PredictionMarket? {
        try await Task.sleep(nanoseconds: 100_000_000)

        return state.withLock { state in
            state.markets[id]
        }
    }

    // MARK: - User Predictions

    func fetchMyPredictions() async throws -> [UserPrediction] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return state.withLock { state in
            Array(state.userPredictions.values)
                .sorted { $0.placedAt > $1.placedAt }
        }
    }

    func hasUserPredicted(marketId: String) async throws -> Bool {
        return state.withLock { state in
            state.userPredictions.values.contains { $0.marketId == marketId }
        }
    }

    // MARK: - Place Prediction

    func placePrediction(
        marketId: String,
        side: PredictionSide,
        amount: Double
    ) async throws -> UserPrediction {
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate transaction

        return try state.withLock { state in
            guard var market = state.markets[marketId] else {
                throw PredictionMarketError.marketNotFound
            }

            guard market.isActive else {
                throw PredictionMarketError.marketClosed
            }

            // Check if already predicted
            if state.userPredictions.values.contains(where: { $0.marketId == marketId }) {
                throw PredictionMarketError.alreadyPredicted
            }

            guard amount > 0 else {
                throw PredictionMarketError.invalidAmount
            }

            // Create the prediction
            let prediction = UserPrediction(
                id: UUID().uuidString,
                marketId: marketId,
                userId: "current-user",
                side: side,
                amount: amount,
                placedAt: Date(),
                payout: nil
            )

            // Update market pools
            var updatedMarket = market
            switch side {
            case .yes:
                updatedMarket = PredictionMarket(
                    id: market.id,
                    epochId: market.epochId,
                    epochTitle: market.epochTitle,
                    predictionType: market.predictionType,
                    question: market.question,
                    targetValue: market.targetValue,
                    yesPool: market.yesPool + amount,
                    noPool: market.noPool,
                    yesVoters: market.yesVoters + 1,
                    noVoters: market.noVoters,
                    endTime: market.endTime,
                    createdAt: market.createdAt,
                    outcome: market.outcome
                )
            case .no:
                updatedMarket = PredictionMarket(
                    id: market.id,
                    epochId: market.epochId,
                    epochTitle: market.epochTitle,
                    predictionType: market.predictionType,
                    question: market.question,
                    targetValue: market.targetValue,
                    yesPool: market.yesPool,
                    noPool: market.noPool + amount,
                    yesVoters: market.yesVoters,
                    noVoters: market.noVoters + 1,
                    endTime: market.endTime,
                    createdAt: market.createdAt,
                    outcome: market.outcome
                )
            }

            state.markets[marketId] = updatedMarket
            state.userPredictions[prediction.id] = prediction

            return prediction
        }
    }

    // MARK: - Market Creation

    func createMarket(
        epochId: UInt64,
        predictionType: PredictionType,
        targetValue: Int?
    ) async throws -> PredictionMarket {
        try await Task.sleep(nanoseconds: 500_000_000)

        return state.withLock { state in
            let market = PredictionMarket(
                id: UUID().uuidString,
                epochId: epochId,
                epochTitle: "Epoch #\(epochId)",
                predictionType: predictionType,
                question: predictionType.displayQuestion,
                targetValue: targetValue,
                yesPool: 0,
                noPool: 0,
                yesVoters: 0,
                noVoters: 0,
                endTime: Date().addingTimeInterval(86400), // 24 hours
                createdAt: Date(),
                outcome: nil
            )

            state.markets[market.id] = market
            return market
        }
    }
}
