//
//  PredictionMarketRepositoryProtocol.swift
//  lapses
//
//  Protocol for prediction market operations
//

import Foundation

/// Repository protocol for prediction market operations
protocol PredictionMarketRepositoryProtocol: Sendable {

    // MARK: - Fetch Markets

    /// Fetch all active prediction markets
    func fetchActiveMarkets() async throws -> [PredictionMarket]

    /// Fetch trending prediction markets (sorted by pool size/activity)
    func fetchTrendingMarkets() async throws -> [PredictionMarket]

    /// Fetch markets for a specific epoch
    func fetchMarketsForEpoch(epochId: UInt64) async throws -> [PredictionMarket]

    /// Fetch a single market by ID
    func fetchMarket(id: String) async throws -> PredictionMarket?

    // MARK: - User Predictions

    /// Fetch predictions made by the current user
    func fetchMyPredictions() async throws -> [UserPrediction]

    /// Check if user has already predicted on a market
    func hasUserPredicted(marketId: String) async throws -> Bool

    // MARK: - Place Prediction

    /// Place a prediction on a market
    /// - Parameters:
    ///   - marketId: The market ID to predict on
    ///   - side: The side to bet on (yes/no)
    ///   - amount: The amount in ETH to stake
    /// - Returns: The created UserPrediction
    func placePrediction(
        marketId: String,
        side: PredictionSide,
        amount: Double
    ) async throws -> UserPrediction

    // MARK: - Market Creation (for epoch creators)

    /// Create a new prediction market for an epoch
    /// - Parameters:
    ///   - epochId: The epoch ID to create market for
    ///   - predictionType: Type of prediction
    ///   - targetValue: Target value for participation predictions
    /// - Returns: The created PredictionMarket
    func createMarket(
        epochId: UInt64,
        predictionType: PredictionType,
        targetValue: Int?
    ) async throws -> PredictionMarket
}

// MARK: - Prediction Market Errors

enum PredictionMarketError: Error, Sendable {
    case marketNotFound
    case marketClosed
    case alreadyPredicted
    case insufficientFunds
    case walletNotConnected
    case invalidAmount
    case marketAlreadyExists
    case epochNotFound
    case notEpochCreator
    case networkError(String)
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .marketNotFound:
            return "Prediction market not found"
        case .marketClosed:
            return "This prediction market has closed"
        case .alreadyPredicted:
            return "You have already placed a prediction on this market"
        case .insufficientFunds:
            return "Insufficient funds to place this prediction"
        case .walletNotConnected:
            return "Please connect your wallet to place predictions"
        case .invalidAmount:
            return "Invalid prediction amount"
        case .marketAlreadyExists:
            return "A prediction market already exists for this epoch"
        case .epochNotFound:
            return "Epoch not found"
        case .notEpochCreator:
            return "Only the epoch creator can create markets"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
