//
//  NFTGalleryRepositoryProtocol.swift
//  lapses
//
//  Protocol for NFT gallery operations (view and list only)
//

import Foundation

/// Repository protocol for NFT gallery operations
/// Supports viewing NFTs and listing for sale, but not full trading
protocol NFTGalleryRepositoryProtocol: Sendable {

    // MARK: - Browse NFTs

    /// Fetch hot/trending NFT listings
    func fetchHotNFTs() async throws -> [LapseNFTListing]

    /// Fetch recently created/listed NFTs
    func fetchRecentNFTs() async throws -> [LapseNFTListing]

    /// Fetch NFTs expiring soon (urgency-based)
    func fetchExpiringSoon() async throws -> [LapseNFTListing]

    /// Search NFTs by title or creator
    func searchNFTs(query: String) async throws -> [LapseNFTListing]

    /// Fetch a single NFT listing by ID
    func fetchListing(id: String) async throws -> LapseNFTListing?

    // MARK: - My Collection

    /// Fetch NFTs owned by the current user
    func fetchMyCollection() async throws -> [LapseNFTListing]

    /// Fetch NFTs liked/saved by the current user
    func fetchMyLikedNFTs() async throws -> [LapseNFTListing]

    // MARK: - Listing Operations

    /// List an NFT for sale
    /// - Parameters:
    ///   - nftId: The NFT ID to list
    ///   - price: The listing price in ETH
    /// - Returns: Updated listing
    func listForSale(nftId: String, price: Double) async throws -> LapseNFTListing

    /// Remove an NFT listing from sale
    func unlistFromSale(listingId: String) async throws

    /// Update the price of a listed NFT
    func updateListingPrice(listingId: String, newPrice: Double) async throws -> LapseNFTListing

    // MARK: - Social Interactions

    /// Toggle like status for an NFT
    /// - Returns: Updated like count and whether user now likes it
    func toggleLike(nftId: String) async throws -> (likeCount: Int, isLiked: Bool)

    /// Increment view count for an NFT
    func recordView(nftId: String) async throws
}

// MARK: - NFT Gallery Errors

enum NFTGalleryError: Error, Sendable {
    case nftNotFound
    case listingNotFound
    case notOwner
    case alreadyListed
    case notListed
    case invalidPrice
    case walletNotConnected
    case networkError(String)
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .nftNotFound:
            return "NFT not found"
        case .listingNotFound:
            return "Listing not found"
        case .notOwner:
            return "You don't own this NFT"
        case .alreadyListed:
            return "This NFT is already listed for sale"
        case .notListed:
            return "This NFT is not listed for sale"
        case .invalidPrice:
            return "Invalid price specified"
        case .walletNotConnected:
            return "Please connect your wallet"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
