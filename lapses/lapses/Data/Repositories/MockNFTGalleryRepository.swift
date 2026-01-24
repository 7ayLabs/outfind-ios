//
//  MockNFTGalleryRepository.swift
//  lapses
//
//  Mock implementation of NFT gallery repository
//

import Foundation
import os.lock

/// Mock implementation of NFTGalleryRepositoryProtocol
final class MockNFTGalleryRepository: NFTGalleryRepositoryProtocol, @unchecked Sendable {

    // MARK: - Thread-Safe State

    private struct State {
        var listings: [String: LapseNFTListing]
        var myCollection: [String: LapseNFTListing]
        var likedNFTs: Set<String>
    }

    private let state: OSAllocatedUnfairLock<State>

    // MARK: - Initialization

    init() {
        let initialListings = Dictionary(
            uniqueKeysWithValues: LapseNFTListing.mockListings().map { ($0.id, $0) }
        )

        let myNFTs = Dictionary(
            uniqueKeysWithValues: LapseNFTListing.mockMyCollection().map { ($0.id, $0) }
        )

        // Pre-set some as liked
        let likedIds = Set(LapseNFTListing.mockListings().filter { $0.isLikedByUser }.map { $0.id })

        self.state = OSAllocatedUnfairLock(initialState: State(
            listings: initialListings,
            myCollection: myNFTs,
            likedNFTs: likedIds
        ))
    }

    // MARK: - Browse NFTs

    func fetchHotNFTs() async throws -> [LapseNFTListing] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return state.withLock { state in
            state.listings.values
                .filter { $0.isHot }
                .sorted { $0.viewCount > $1.viewCount }
        }
    }

    func fetchRecentNFTs() async throws -> [LapseNFTListing] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return state.withLock { state in
            state.listings.values
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    func fetchExpiringSoon() async throws -> [LapseNFTListing] {
        try await Task.sleep(nanoseconds: 200_000_000)

        return state.withLock { state in
            state.listings.values
                .filter { $0.timeRemaining != nil }
                .sorted { ($0.timeRemaining ?? .infinity) < ($1.timeRemaining ?? .infinity) }
        }
    }

    func searchNFTs(query: String) async throws -> [LapseNFTListing] {
        try await Task.sleep(nanoseconds: 200_000_000)

        let lowercasedQuery = query.lowercased()

        return state.withLock { state in
            state.listings.values
                .filter {
                    $0.nft.epochTitle.lowercased().contains(lowercasedQuery) ||
                    $0.nft.creator.rawValue.lowercased().contains(lowercasedQuery)
                }
                .sorted { $0.viewCount > $1.viewCount }
        }
    }

    func fetchListing(id: String) async throws -> LapseNFTListing? {
        try await Task.sleep(nanoseconds: 100_000_000)

        return state.withLock { state in
            state.listings[id] ?? state.myCollection[id]
        }
    }

    // MARK: - My Collection

    func fetchMyCollection() async throws -> [LapseNFTListing] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return state.withLock { state in
            Array(state.myCollection.values)
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    func fetchMyLikedNFTs() async throws -> [LapseNFTListing] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return state.withLock { state in
            state.listings.values
                .filter { state.likedNFTs.contains($0.id) }
                .sorted { $0.likeCount > $1.likeCount }
        }
    }

    // MARK: - Listing Operations

    func listForSale(nftId: String, price: Double) async throws -> LapseNFTListing {
        try await Task.sleep(nanoseconds: 500_000_000)

        return try state.withLock { state in
            guard var listing = state.myCollection[nftId] else {
                throw NFTGalleryError.nftNotFound
            }

            guard !listing.isListed else {
                throw NFTGalleryError.alreadyListed
            }

            guard price > 0 else {
                throw NFTGalleryError.invalidPrice
            }

            // Create updated listing with price
            let updatedListing = LapseNFTListing(
                id: listing.id,
                nft: listing.nft,
                listPrice: price,
                viewCount: listing.viewCount,
                likeCount: listing.likeCount,
                expiresAt: listing.expiresAt,
                owner: listing.owner,
                isHot: listing.isHot,
                createdAt: listing.createdAt,
                isLikedByUser: listing.isLikedByUser,
                previewImageURL: listing.previewImageURL
            )

            state.myCollection[nftId] = updatedListing
            state.listings[nftId] = updatedListing

            return updatedListing
        }
    }

    func unlistFromSale(listingId: String) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)

        try state.withLock { state in
            guard var listing = state.myCollection[listingId] else {
                throw NFTGalleryError.listingNotFound
            }

            guard listing.isListed else {
                throw NFTGalleryError.notListed
            }

            // Create updated listing without price
            let updatedListing = LapseNFTListing(
                id: listing.id,
                nft: listing.nft,
                listPrice: nil,
                viewCount: listing.viewCount,
                likeCount: listing.likeCount,
                expiresAt: listing.expiresAt,
                owner: listing.owner,
                isHot: listing.isHot,
                createdAt: listing.createdAt,
                isLikedByUser: listing.isLikedByUser,
                previewImageURL: listing.previewImageURL
            )

            state.myCollection[listingId] = updatedListing
            state.listings.removeValue(forKey: listingId)
        }
    }

    func updateListingPrice(listingId: String, newPrice: Double) async throws -> LapseNFTListing {
        try await Task.sleep(nanoseconds: 300_000_000)

        return try state.withLock { state in
            guard var listing = state.myCollection[listingId] else {
                throw NFTGalleryError.listingNotFound
            }

            guard listing.isListed else {
                throw NFTGalleryError.notListed
            }

            guard newPrice > 0 else {
                throw NFTGalleryError.invalidPrice
            }

            // Create updated listing with new price
            let updatedListing = LapseNFTListing(
                id: listing.id,
                nft: listing.nft,
                listPrice: newPrice,
                viewCount: listing.viewCount,
                likeCount: listing.likeCount,
                expiresAt: listing.expiresAt,
                owner: listing.owner,
                isHot: listing.isHot,
                createdAt: listing.createdAt,
                isLikedByUser: listing.isLikedByUser,
                previewImageURL: listing.previewImageURL
            )

            state.myCollection[listingId] = updatedListing
            state.listings[listingId] = updatedListing

            return updatedListing
        }
    }

    // MARK: - Social Interactions

    func toggleLike(nftId: String) async throws -> (likeCount: Int, isLiked: Bool) {
        try await Task.sleep(nanoseconds: 200_000_000)

        return state.withLock { state in
            let wasLiked = state.likedNFTs.contains(nftId)
            var likeCount = state.listings[nftId]?.likeCount ?? 0

            if wasLiked {
                state.likedNFTs.remove(nftId)
                likeCount = max(0, likeCount - 1)
            } else {
                state.likedNFTs.insert(nftId)
                likeCount += 1
            }

            // Update the listing with new like count
            if var listing = state.listings[nftId] {
                let updatedListing = LapseNFTListing(
                    id: listing.id,
                    nft: listing.nft,
                    listPrice: listing.listPrice,
                    viewCount: listing.viewCount,
                    likeCount: likeCount,
                    expiresAt: listing.expiresAt,
                    owner: listing.owner,
                    isHot: listing.isHot,
                    createdAt: listing.createdAt,
                    isLikedByUser: !wasLiked,
                    previewImageURL: listing.previewImageURL
                )
                state.listings[nftId] = updatedListing
            }

            return (likeCount, !wasLiked)
        }
    }

    func recordView(nftId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)

        state.withLock { state in
            if var listing = state.listings[nftId] {
                let updatedListing = LapseNFTListing(
                    id: listing.id,
                    nft: listing.nft,
                    listPrice: listing.listPrice,
                    viewCount: listing.viewCount + 1,
                    likeCount: listing.likeCount,
                    expiresAt: listing.expiresAt,
                    owner: listing.owner,
                    isHot: listing.isHot,
                    createdAt: listing.createdAt,
                    isLikedByUser: listing.isLikedByUser,
                    previewImageURL: listing.previewImageURL
                )
                state.listings[nftId] = updatedListing
            }
        }
    }
}
