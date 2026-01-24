//
//  LapseNFTListing.swift
//  lapses
//
//  NFT listing entity for the gallery view
//

import Foundation
import SwiftUI

// MARK: - Urgency Level

enum UrgencyLevel: Sendable, Equatable {
    case none
    case normal
    case moderate
    case high
    case critical

    var color: Color {
        switch self {
        case .none, .normal:
            return Color.secondary
        case .moderate:
            return Color.orange
        case .high, .critical:
            return Color.red
        }
    }

    var label: String {
        switch self {
        case .none, .normal:
            return ""
        case .moderate:
            return "Ending Soon"
        case .high:
            return "Almost Over"
        case .critical:
            return "Final Moments"
        }
    }

    var shouldPulse: Bool {
        self == .high || self == .critical
    }
}

// MARK: - Lapse NFT Listing

struct LapseNFTListing: Identifiable, Sendable, Equatable {
    let id: String
    let nft: EpochNFT
    let listPrice: Double?  // nil if not listed for sale
    let viewCount: Int
    var likeCount: Int
    let expiresAt: Date?
    let owner: Address
    let isHot: Bool
    let createdAt: Date
    var isLikedByUser: Bool

    // Optional preview image URL
    let previewImageURL: URL?

    // MARK: - Computed Properties

    var isListed: Bool {
        listPrice != nil
    }

    var timeRemaining: TimeInterval? {
        guard let expiresAt else { return nil }
        let remaining = expiresAt.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    var urgencyLevel: UrgencyLevel {
        guard let remaining = timeRemaining else { return .none }
        if remaining < 300 { return .critical }     // < 5 min
        if remaining < 900 { return .high }         // < 15 min
        if remaining < 3600 { return .moderate }    // < 1 hour
        return .normal
    }

    var formattedPrice: String? {
        guard let price = listPrice else { return nil }
        if price >= 1.0 {
            return String(format: "%.2f ETH", price)
        } else {
            return String(format: "%.4f ETH", price)
        }
    }

    var formattedTimeRemaining: String? {
        guard let remaining = timeRemaining else { return nil }

        if remaining < 60 {
            return "\(Int(remaining))s"
        } else if remaining < 3600 {
            let minutes = Int(remaining / 60)
            let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return String(format: "%dh %dm", hours, minutes)
        }
    }

    var formattedViewCount: String {
        if viewCount >= 1000 {
            return String(format: "%.1fK", Double(viewCount) / 1000)
        }
        return "\(viewCount)"
    }

    var hotBadgeText: String? {
        guard isHot else { return nil }
        return "Hot"
    }

    var authorDisplayName: String {
        nft.creator.abbreviated
    }
}

// MARK: - Mock Data

extension LapseNFTListing {
    static func mockListings() -> [LapseNFTListing] {
        let now = Date()

        return [
            LapseNFTListing(
                id: "listing-1",
                nft: EpochNFT.mock(id: 1, epochId: 1, epochTitle: "Sunset at Venice Beach"),
                listPrice: 0.05,
                viewCount: 234,
                likeCount: 45,
                expiresAt: now.addingTimeInterval(272), // ~4:32
                owner: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
                isHot: true,
                createdAt: now.addingTimeInterval(-3600),
                isLikedByUser: false,
                previewImageURL: URL(string: "https://picsum.photos/seed/nft1/400/400")
            ),
            LapseNFTListing(
                id: "listing-2",
                nft: EpochNFT.mock(id: 2, epochId: 2, epochTitle: "Morning Coffee Run"),
                listPrice: 0.032,
                viewCount: 89,
                likeCount: 12,
                expiresAt: now.addingTimeInterval(1800), // 30 min
                owner: Address(rawValue: "0xabcdef1234567890abcdef1234567890abcdef12")!,
                isHot: false,
                createdAt: now.addingTimeInterval(-7200),
                isLikedByUser: true,
                previewImageURL: URL(string: "https://picsum.photos/seed/nft2/400/400")
            ),
            LapseNFTListing(
                id: "listing-3",
                nft: EpochNFT.mock(id: 3, epochId: 3, epochTitle: "Tech Meetup Downtown"),
                listPrice: nil, // Not listed
                viewCount: 567,
                likeCount: 123,
                expiresAt: now.addingTimeInterval(180), // 3 min - critical!
                owner: Address(rawValue: "0x9876543210987654321098765432109876543210")!,
                isHot: true,
                createdAt: now.addingTimeInterval(-14400),
                isLikedByUser: false,
                previewImageURL: URL(string: "https://picsum.photos/seed/nft3/400/400")
            ),
            LapseNFTListing(
                id: "listing-4",
                nft: EpochNFT.mock(id: 4, epochId: 4, epochTitle: "Art Gallery Opening"),
                listPrice: 0.15,
                viewCount: 1245,
                likeCount: 89,
                expiresAt: now.addingTimeInterval(7200), // 2 hours
                owner: Address(rawValue: "0xfedcba0987654321fedcba0987654321fedcba09")!,
                isHot: true,
                createdAt: now.addingTimeInterval(-28800),
                isLikedByUser: false,
                previewImageURL: URL(string: "https://picsum.photos/seed/nft4/400/400")
            ),
            LapseNFTListing(
                id: "listing-5",
                nft: EpochNFT.mock(id: 5, epochId: 5, epochTitle: "Beach Yoga Session"),
                listPrice: 0.08,
                viewCount: 432,
                likeCount: 67,
                expiresAt: nil, // No expiry
                owner: Address(rawValue: "0x1111222233334444555566667777888899990000")!,
                isHot: false,
                createdAt: now.addingTimeInterval(-43200),
                isLikedByUser: true,
                previewImageURL: URL(string: "https://picsum.photos/seed/nft5/400/400")
            ),
            LapseNFTListing(
                id: "listing-6",
                nft: EpochNFT.mock(id: 6, epochId: 6, epochTitle: "Rooftop Party"),
                listPrice: 0.25,
                viewCount: 2100,
                likeCount: 312,
                expiresAt: now.addingTimeInterval(600), // 10 min
                owner: Address(rawValue: "0xaaaabbbbccccddddeeeeffff0000111122223333")!,
                isHot: true,
                createdAt: now.addingTimeInterval(-86400),
                isLikedByUser: false,
                previewImageURL: URL(string: "https://picsum.photos/seed/nft6/400/400")
            )
        ]
    }

    static func mockMyCollection() -> [LapseNFTListing] {
        let now = Date()

        return [
            LapseNFTListing(
                id: "my-1",
                nft: EpochNFT.mock(id: 101, epochId: 101, epochTitle: "My First Epoch"),
                listPrice: nil,
                viewCount: 45,
                likeCount: 8,
                expiresAt: nil,
                owner: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
                isHot: false,
                createdAt: now.addingTimeInterval(-172800),
                isLikedByUser: false,
                previewImageURL: URL(string: "https://picsum.photos/seed/mynft1/400/400")
            ),
            LapseNFTListing(
                id: "my-2",
                nft: EpochNFT.mock(id: 102, epochId: 102, epochTitle: "Weekend Vibes"),
                listPrice: 0.045,
                viewCount: 23,
                likeCount: 3,
                expiresAt: nil,
                owner: Address(rawValue: "0x1234567890123456789012345678901234567890")!,
                isHot: false,
                createdAt: now.addingTimeInterval(-259200),
                isLikedByUser: false,
                previewImageURL: URL(string: "https://picsum.photos/seed/mynft2/400/400")
            )
        ]
    }
}
