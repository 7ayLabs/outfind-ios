//
//  LapserToken.swift
//  lapses
//
//  Ephemeral presence-based tokens for user trading
//

import Foundation

// MARK: - Lapser Token

struct LapserToken: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: String
    let creatorAddress: String
    let creatorName: String
    let creatorUsername: String
    let creatorAvatarURL: URL?
    let isVerified: Bool

    // Token Economics
    let currentPrice: Double
    let priceChange24h: Double
    let marketCap: Double
    let holders: Int
    let volume24h: Double

    // Ephemeral Presence Link
    let activeEpochCount: Int
    let totalPresenceScore: Double
    let lastActiveAt: Date

    // Chart data (sparkline points)
    let priceHistory: [Double]

    // MARK: - Computed Properties

    var isPriceUp: Bool {
        priceChange24h >= 0
    }

    var formattedPrice: String {
        if currentPrice >= 1_000_000 {
            return String(format: "$%.2fM", currentPrice / 1_000_000)
        } else if currentPrice >= 1_000 {
            return String(format: "$%.0fK", currentPrice / 1_000)
        }
        return String(format: "$%.2f", currentPrice)
    }

    var formattedMarketCap: String {
        if marketCap >= 1_000_000 {
            return String(format: "$%.1fM", marketCap / 1_000_000)
        } else if marketCap >= 1_000 {
            return String(format: "$%.0fK", marketCap / 1_000)
        }
        return String(format: "$%.0f", marketCap)
    }

    var formattedChange: String {
        let prefix = priceChange24h >= 0 ? "+" : ""
        if abs(priceChange24h) >= 1000 {
            return String(format: "%@%.2f%%", prefix, priceChange24h)
        }
        return String(format: "%@%.2f%%", prefix, priceChange24h)
    }

    var formattedVolume: String {
        if volume24h >= 1_000_000 {
            return String(format: "$%.1fM", volume24h / 1_000_000)
        } else if volume24h >= 1_000 {
            return String(format: "$%.0fK", volume24h / 1_000)
        }
        return String(format: "$%.0f", volume24h)
    }
}

// MARK: - Lapser Token Holding

struct LapserTokenHolding: Identifiable, Codable, Sendable {
    let id: String
    let token: LapserToken
    let amount: Double
    let purchasePrice: Double
    let purchasedAt: Date

    var currentValue: Double {
        amount * token.currentPrice
    }

    var profitLoss: Double {
        currentValue - (amount * purchasePrice)
    }

    var profitLossPercentage: Double {
        guard purchasePrice > 0 else { return 0 }
        return ((token.currentPrice - purchasePrice) / purchasePrice) * 100
    }
}

// MARK: - Mock Data

extension LapserToken {
    private static func generateSparkline(seed: Int, trend: Double) -> [Double] {
        var rng = SeededGenerator(seed: UInt64(abs(seed)))
        var points: [Double] = []
        var value = 50.0

        for i in 0..<24 {
            let noise = (rng.next() - 0.5) * 15
            let trendPull = trend * 0.3
            let momentum = sin(Double(i) * 0.5) * 5
            value = value + noise + trendPull + momentum
            value = max(10, min(90, value))
            points.append(value)
        }

        // Push toward trend direction at end
        for _ in 0..<4 {
            value += (trend > 0 ? 8 : -8) * rng.next()
            value = max(5, min(95, value))
            points.append(value)
        }

        return points
    }

    static func mockTokens() -> [LapserToken] {
        let now = Date()
        return [
            LapserToken(
                id: "token-1",
                creatorAddress: "0x742d35Cc6634C0532925a3b844Bc9e7595f8a2b1",
                creatorName: "USORU.S...",
                creatorUsername: "usorr.base.eth",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser1/200"),
                isVerified: true,
                currentPrice: 2_600_000,
                priceChange24h: 5602.04,
                marketCap: 45_000_000,
                holders: 12847,
                volume24h: 8_500_000,
                activeEpochCount: 3,
                totalPresenceScore: 98.5,
                lastActiveAt: now.addingTimeInterval(-1800),
                priceHistory: generateSparkline(seed: 1, trend: 1)
            ),
            LapserToken(
                id: "token-2",
                creatorAddress: "0x8ba1f109551bD432803012645Ac136ddd64DBA72",
                creatorName: "U.S. Oil Res...",
                creatorUsername: "dexcheckai",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser2/200"),
                isVerified: true,
                currentPrice: 833_000,
                priceChange24h: 163271.23,
                marketCap: 28_000_000,
                holders: 8934,
                volume24h: 12_400_000,
                activeEpochCount: 5,
                totalPresenceScore: 95.2,
                lastActiveAt: now.addingTimeInterval(-3600),
                priceHistory: generateSparkline(seed: 2, trend: 1)
            ),
            LapserToken(
                id: "token-3",
                creatorAddress: "0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE",
                creatorName: "dexcheckai",
                creatorUsername: "dexcheck",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser3/200"),
                isVerified: false,
                currentPrice: 126_000,
                priceChange24h: 1224.57,
                marketCap: 4_200_000,
                holders: 3421,
                volume24h: 890_000,
                activeEpochCount: 2,
                totalPresenceScore: 78.4,
                lastActiveAt: now.addingTimeInterval(-7200),
                priceHistory: generateSparkline(seed: 3, trend: 1)
            ),
            LapserToken(
                id: "token-4",
                creatorAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
                creatorName: "solana token",
                creatorUsername: "productvortex",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser4/200"),
                isVerified: true,
                currentPrice: 70_000,
                priceChange24h: 3370.3,
                marketCap: 2_100_000,
                holders: 2156,
                volume24h: 540_000,
                activeEpochCount: 1,
                totalPresenceScore: 82.1,
                lastActiveAt: now.addingTimeInterval(-14400),
                priceHistory: generateSparkline(seed: 4, trend: 1)
            ),
            LapserToken(
                id: "token-5",
                creatorAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                creatorName: "US OIL",
                creatorUsername: "usaproject",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser5/200"),
                isVerified: true,
                currentPrice: 127_000,
                priceChange24h: 500.93,
                marketCap: 3_800_000,
                holders: 2890,
                volume24h: 720_000,
                activeEpochCount: 2,
                totalPresenceScore: 88.7,
                lastActiveAt: now.addingTimeInterval(-3600),
                priceHistory: generateSparkline(seed: 5, trend: 1)
            ),
            LapserToken(
                id: "token-6",
                creatorAddress: "0x6B175474E89094C44Da98b954EescdeCB5",
                creatorName: "USORV",
                creatorUsername: "spaceblock",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser6/200"),
                isVerified: true,
                currentPrice: 220_000,
                priceChange24h: 9680.65,
                marketCap: 6_500_000,
                holders: 4521,
                volume24h: 1_200_000,
                activeEpochCount: 4,
                totalPresenceScore: 91.3,
                lastActiveAt: now.addingTimeInterval(-1200),
                priceHistory: generateSparkline(seed: 6, trend: 1)
            ),
            LapserToken(
                id: "token-7",
                creatorAddress: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
                creatorName: "zorbofficial",
                creatorUsername: "zorb",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser7/200"),
                isVerified: true,
                currentPrice: 30_000,
                priceChange24h: 128.39,
                marketCap: 980_000,
                holders: 1245,
                volume24h: 180_000,
                activeEpochCount: 1,
                totalPresenceScore: 72.5,
                lastActiveAt: now.addingTimeInterval(-28800),
                priceHistory: generateSparkline(seed: 7, trend: 0.5)
            ),
            LapserToken(
                id: "token-8",
                creatorAddress: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
                creatorName: "ethereal.dev",
                creatorUsername: "etherealdev",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser8/200"),
                isVerified: true,
                currentPrice: 456_000,
                priceChange24h: -12.45,
                marketCap: 12_000_000,
                holders: 6234,
                volume24h: 2_100_000,
                activeEpochCount: 3,
                totalPresenceScore: 94.8,
                lastActiveAt: now.addingTimeInterval(-600),
                priceHistory: generateSparkline(seed: 8, trend: -0.5)
            ),
            LapserToken(
                id: "token-9",
                creatorAddress: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
                creatorName: "cryptoninja",
                creatorUsername: "ninja.eth",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser9/200"),
                isVerified: false,
                currentPrice: 89_500,
                priceChange24h: 847.23,
                marketCap: 2_800_000,
                holders: 1987,
                volume24h: 450_000,
                activeEpochCount: 2,
                totalPresenceScore: 85.2,
                lastActiveAt: now.addingTimeInterval(-5400),
                priceHistory: generateSparkline(seed: 9, trend: 1)
            ),
            LapserToken(
                id: "token-10",
                creatorAddress: "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",
                creatorName: "defi_whale",
                creatorUsername: "whale.lens",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser10/200"),
                isVerified: true,
                currentPrice: 1_250_000,
                priceChange24h: 2341.67,
                marketCap: 32_000_000,
                holders: 9876,
                volume24h: 5_600_000,
                activeEpochCount: 6,
                totalPresenceScore: 97.1,
                lastActiveAt: now.addingTimeInterval(-900),
                priceHistory: generateSparkline(seed: 10, trend: 1)
            ),
            LapserToken(
                id: "token-11",
                creatorAddress: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                creatorName: "moonshot.eth",
                creatorUsername: "moonshot",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser11/200"),
                isVerified: false,
                currentPrice: 15_600,
                priceChange24h: -5.82,
                marketCap: 520_000,
                holders: 678,
                volume24h: 85_000,
                activeEpochCount: 1,
                totalPresenceScore: 65.4,
                lastActiveAt: now.addingTimeInterval(-43200),
                priceHistory: generateSparkline(seed: 11, trend: -0.3)
            ),
            LapserToken(
                id: "token-12",
                creatorAddress: "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e",
                creatorName: "presenceking",
                creatorUsername: "pk.base",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser12/200"),
                isVerified: true,
                currentPrice: 678_000,
                priceChange24h: 4521.89,
                marketCap: 18_500_000,
                holders: 7234,
                volume24h: 3_200_000,
                activeEpochCount: 4,
                totalPresenceScore: 93.6,
                lastActiveAt: now.addingTimeInterval(-2400),
                priceHistory: generateSparkline(seed: 12, trend: 1)
            ),
            LapserToken(
                id: "token-13",
                creatorAddress: "0xD533a949740bb3306d119CC777fa900bA034cd52",
                creatorName: "alpha_caller",
                creatorUsername: "alphacalls",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser13/200"),
                isVerified: true,
                currentPrice: 345_000,
                priceChange24h: 1876.54,
                marketCap: 9_200_000,
                holders: 5432,
                volume24h: 1_800_000,
                activeEpochCount: 3,
                totalPresenceScore: 89.9,
                lastActiveAt: now.addingTimeInterval(-4800),
                priceHistory: generateSparkline(seed: 13, trend: 1)
            ),
            LapserToken(
                id: "token-14",
                creatorAddress: "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
                creatorName: "web3builder",
                creatorUsername: "builder.eth",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser14/200"),
                isVerified: false,
                currentPrice: 42_300,
                priceChange24h: 234.12,
                marketCap: 1_400_000,
                holders: 1123,
                volume24h: 210_000,
                activeEpochCount: 2,
                totalPresenceScore: 76.8,
                lastActiveAt: now.addingTimeInterval(-10800),
                priceHistory: generateSparkline(seed: 14, trend: 0.7)
            ),
            LapserToken(
                id: "token-15",
                creatorAddress: "0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55",
                creatorName: "epochmaster",
                creatorUsername: "epochs.lens",
                creatorAvatarURL: URL(string: "https://picsum.photos/seed/lapser15/200"),
                isVerified: true,
                currentPrice: 892_000,
                priceChange24h: 6789.32,
                marketCap: 24_000_000,
                holders: 8123,
                volume24h: 4_100_000,
                activeEpochCount: 5,
                totalPresenceScore: 96.2,
                lastActiveAt: now.addingTimeInterval(-1800),
                priceHistory: generateSparkline(seed: 15, trend: 1)
            )
        ]
    }
}

// MARK: - Seeded Generator

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1000) / 1000.0
    }
}
