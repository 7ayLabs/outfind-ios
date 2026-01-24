//
//  LapserTokenRepositoryProtocol.swift
//  lapses
//
//  Repository protocol for ephemeral presence token operations
//

import Foundation

// MARK: - Lapser Token Repository Protocol

protocol LapserTokenRepositoryProtocol: Sendable {
    /// Fetch trending tokens by price momentum
    func fetchTrendingTokens() async throws -> [LapserToken]

    /// Fetch top tokens by market cap
    func fetchTopTokens() async throws -> [LapserToken]

    /// Fetch newly created tokens
    func fetchNewTokens() async throws -> [LapserToken]

    /// Fetch tokens with creators in active epochs
    func fetchLiveTokens() async throws -> [LapserToken]

    /// Fetch a specific token by creator address
    func fetchToken(by address: String) async throws -> LapserToken?

    /// Fetch current user's token holdings
    func fetchUserHoldings() async throws -> [LapserTokenHolding]
}
