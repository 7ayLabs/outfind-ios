//
//  MockLapserTokenRepository.swift
//  lapses
//
//  Mock implementation for ephemeral presence token repository
//

import Foundation

// MARK: - Mock Lapser Token Repository

final class MockLapserTokenRepository: LapserTokenRepositoryProtocol, @unchecked Sendable {
    private let mockTokens: [LapserToken]

    init() {
        self.mockTokens = LapserToken.mockTokens()
    }

    func fetchTrendingTokens() async throws -> [LapserToken] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000)

        // Sort by price change velocity (highest gains first)
        return mockTokens.sorted { $0.priceChange24h > $1.priceChange24h }
    }

    func fetchTopTokens() async throws -> [LapserToken] {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Sort by market cap
        return mockTokens.sorted { $0.marketCap > $1.marketCap }
    }

    func fetchNewTokens() async throws -> [LapserToken] {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Sort by most recently active
        return mockTokens.sorted { $0.lastActiveAt > $1.lastActiveAt }
    }

    func fetchLiveTokens() async throws -> [LapserToken] {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Filter to only tokens with active epoch participation
        return mockTokens
            .filter { $0.activeEpochCount > 0 }
            .sorted { $0.activeEpochCount > $1.activeEpochCount }
    }

    func fetchToken(by address: String) async throws -> LapserToken? {
        try await Task.sleep(nanoseconds: 200_000_000)

        return mockTokens.first { $0.creatorAddress == address }
    }

    func fetchUserHoldings() async throws -> [LapserTokenHolding] {
        try await Task.sleep(nanoseconds: 300_000_000)

        // Return mock holdings for first 3 tokens
        let holdingTokens = Array(mockTokens.prefix(3))
        return holdingTokens.enumerated().map { index, token in
            LapserTokenHolding(
                id: "holding-\(index)",
                token: token,
                amount: Double.random(in: 0.5...5.0),
                purchasePrice: token.currentPrice * Double.random(in: 0.7...0.95),
                purchasedAt: Date().addingTimeInterval(-Double.random(in: 86400...604800))
            )
        }
    }
}
