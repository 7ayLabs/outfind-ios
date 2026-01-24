import SwiftUI

// MARK: - Profile Sheet View

/// Web3-style profile sheet with NFT grid display
struct ProfileSheetView: View {
    let user: User?
    @Binding var isPresented: Bool

    // Profile data state
    @State private var profileData: ProfileData?
    @State private var isLoading = true
    @State private var appeared = false
    @State private var isFollowing = false

    // Tab selection
    @State private var selectedTab: ProfileTab = .epochs

    enum ProfileTab: String, CaseIterable {
        case epochs = "Epochs"
        case lapses = "Lapses"
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile Header Section
                    profileHeaderSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    // Epoch Tags (horizontal scroll)
                    if let tags = profileData?.epochTags, !tags.isEmpty {
                        EpochTagsSection(tags: tags)
                            .padding(.bottom, 16)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }

                    // Followed By Section
                    if let mutuals = profileData?.mutualFollowers, !mutuals.isEmpty {
                        FollowedBySection(mutualFollowers: mutuals)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }

                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .opacity(appeared ? 1 : 0)

                    // Grid content
                    gridContent
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                }
                .padding(.top, 16)
            }
            .background(Theme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    appeared = true
                }
            }
            .task {
                await loadProfileData()
            }
        }
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar with glow
            ProfileAvatarWithBadge(
                avatarURL: user?.avatarURL,
                badgeIcon: nil,
                size: 80,
                glowColor: Theme.Colors.neonGreen
            )

            // Name and username
            VStack(spacing: 4) {
                Text(user?.displayName ?? "Anonymous")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(username)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.neonGreen)
            }

            // Action buttons
            HStack(spacing: 12) {
                ProfileActionButton(style: .chat) {
                    // TODO: Open chat
                }

                ProfileActionButton(style: .follow(isFollowing: isFollowing)) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isFollowing.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            // Stats row
            if let data = profileData {
                ProfileStatsRow(
                    followerCount: data.followerCount,
                    followingCount: data.followingCount,
                    addressCount: data.addressCount
                )
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: tab == .epochs ? "circle.hexagongrid.fill" : "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? Theme.Colors.neonGreen : Theme.Colors.textTertiary)

                        // Indicator
                        Rectangle()
                            .fill(selectedTab == tab ? Theme.Colors.neonGreen : .clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Grid Content

    @ViewBuilder
    private var gridContent: some View {
        switch selectedTab {
        case .epochs:
            if let epochs = profileData?.epochs, !epochs.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(epochs) { epoch in
                        EpochNFTCard(epoch: epoch) {
                            // TODO: Navigate to epoch detail
                        }
                    }
                }
            } else {
                emptyStateView(
                    icon: "circle.hexagongrid",
                    title: "No Epochs Yet",
                    subtitle: "Epochs you participate in will appear here as NFTs"
                )
            }

        case .lapses:
            if let lapses = profileData?.lapses, !lapses.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(lapses) { lapse in
                        LapseNFTCard(lapse: lapse) {
                            // TODO: Navigate to lapse detail
                        }
                    }
                }
            } else {
                emptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No Lapses Yet",
                    subtitle: "Your captured moments will appear here"
                )
            }
        }
    }

    // MARK: - Empty State

    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            isPresented = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .background {
                    Circle()
                        .fill(Theme.Colors.backgroundSecondary)
                }
        }
    }

    // MARK: - Helpers

    private var username: String {
        if let name = user?.displayName {
            return "@\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
        }
        return "@user"
    }

    private func loadProfileData() async {
        // Simulate loading delay
        try? await Task.sleep(nanoseconds: 300_000_000)

        await MainActor.run {
            // Use mock data for MVP
            if let user = user {
                profileData = ProfileData.mock(user: user)
                isFollowing = profileData?.isFollowing ?? false
            }
            isLoading = false
        }
    }
}

// MARK: - Previews

#Preview("Profile Sheet") {
    ProfileSheetView(
        user: .mockWallet,
        isPresented: .constant(true)
    )
}

#Preview("Profile Sheet - Dark") {
    ProfileSheetView(
        user: .mockWallet,
        isPresented: .constant(true)
    )
    .preferredColorScheme(.dark)
}
