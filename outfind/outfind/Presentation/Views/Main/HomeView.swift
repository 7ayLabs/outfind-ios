import SwiftUI

// MARK: - Home View

/// Main home view with For You feed using ExplorePostCard
/// Optimized with animated tabs and scroll-based fade effects
struct HomeView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies

    @State private var epochs: [Epoch] = []
    @State private var isLoading = true
    @State private var selectedTab: FeedTab = .forYou
    @State private var showWalletSheet = false
    @State private var showPresenceSheet = false
    @State private var showNotificationsSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var hasAppeared = false

    var body: some View {
        @Bindable var bindableCoordinator = coordinator
        NavigationStack(path: $bindableCoordinator.navigationPath) {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.horizontal, Theme.Spacing.md)

                        // Animated Tab Selector
                        AnimatedTabSelector(
                            selectedTab: $selectedTab,
                            scrollOffset: scrollOffset,
                            hasAppeared: hasAppeared
                        )
                        .padding(.top, Theme.Spacing.md)

                        // Feed content
                        if isLoading {
                            loadingView
                        } else {
                            feedContent
                        }

                        Spacer(minLength: 120)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: -geo.frame(in: .named("scroll")).origin.y
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
                .refreshable {
                    await loadEpochs()
                }
            }
            .navigationDestination(for: AppDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $showWalletSheet) {
                WalletSheetView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPresenceSheet) {
                PresenceNetworkSheetView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsSheetView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .task {
                await loadEpochs()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                    hasAppeared = true
                }
            }
        }
    }

    // MARK: - Header Section (No Search Bar)

    private var headerSection: some View {
        HStack {
            // 7ay-presence signal button - activates Bluetooth mesh protocol
            PresenceSignalButton {
                showPresenceSheet = true
            }

            Spacer()

            // Centered title
            VStack(spacing: Theme.Spacing.xxs) {
                Text("outfind.me")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: Theme.Spacing.xxs) {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 6, height: 6)
                    Text("Sepolia Testnet")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            // Notification bell button (liquid glass)
            NotificationBellButton {
                showNotificationsSheet = true
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading your feed...")
                .font(Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer()
        }
        .frame(minHeight: 400)
    }

    // MARK: - Feed Content

    private var feedContent: some View {
        LazyVStack(spacing: Theme.Spacing.lg) {
            ForEach(Array(displayedEpochs.enumerated()), id: \.element.id) { index, epoch in
                ExplorePostCard(epoch: epoch, animationDelay: Double(index) * 0.08) {
                    coordinator.showEpochDetail(epochId: epoch.id)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Displayed Epochs

    private var displayedEpochs: [Epoch] {
        switch selectedTab {
        case .forYou:
            // For You: mix of active and upcoming, sorted by participant count
            return epochs.sorted { $0.participantCount > $1.participantCount }
        case .recent:
            // Recent: sorted by start time (newest first)
            return epochs.sorted { $0.startTime > $1.startTime }
        }
    }

    // MARK: - Load Epochs

    private func loadEpochs() async {
        isLoading = true
        do {
            let fetchedEpochs = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            await MainActor.run {
                epochs = fetchedEpochs
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    // MARK: - Destination View

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .epochDetail(let epochId):
            EpochDetailView(epochId: epochId)
        case .activeEpoch(let epochId):
            ActiveEpochView(epochId: epochId)
        default:
            EmptyView()
        }
    }
}

// MARK: - Feed Tab

enum FeedTab: CaseIterable, Identifiable {
    case forYou
    case recent

    var id: Self { self }

    var title: String {
        switch self {
        case .forYou: return "For you"
        case .recent: return "Recent"
        }
    }
}

// MARK: - Animated Tab Selector

struct AnimatedTabSelector: View {
    @Binding var selectedTab: FeedTab
    let scrollOffset: CGFloat
    let hasAppeared: Bool

    @State private var indicatorOffset: CGFloat = 0
    @State private var tabScale: CGFloat = 0.9
    @State private var tabOpacity: Double = 0

    private let tabWidth: CGFloat = 80

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Tabs
            HStack(spacing: Theme.Spacing.xl) {
                ForEach(FeedTab.allCases) { tab in
                    TabItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        hasAppeared: hasAppeared
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .scaleEffect(tabScale)
            .opacity(tabOpacity)

            // Underline indicator (neutral white/gray)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.textPrimary)
                    .frame(width: tabWidth, height: 2)
                    .offset(x: selectedTab == .forYou ? -tabWidth/2 - Theme.Spacing.xl/2 : tabWidth/2 + Theme.Spacing.xl/2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            .frame(height: 2)
        }
        .opacity(fadeOpacity)
        .onChange(of: hasAppeared) { _, appeared in
            if appeared {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    tabScale = 1.0
                    tabOpacity = 1.0
                }
            }
        }
    }

    // Fade out as user scrolls down
    private var fadeOpacity: Double {
        let fadeStart: CGFloat = 50
        let fadeEnd: CGFloat = 150

        if scrollOffset < fadeStart {
            return 1.0
        } else if scrollOffset > fadeEnd {
            return 0.3
        } else {
            let progress = (scrollOffset - fadeStart) / (fadeEnd - fadeStart)
            return 1.0 - (progress * 0.7)
        }
    }
}

// MARK: - Tab Item

private struct TabItem: View {
    let tab: FeedTab
    let isSelected: Bool
    let hasAppeared: Bool
    let action: () -> Void

    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = -10

    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            Text(tab.title)
                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(AnimatedButtonStyle())
        .onChange(of: isSelected) { _, selected in
            if selected {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    iconScale = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    iconScale = 1.0
                }
            }
        }
    }

    private func triggerHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Presence Signal Button (7ay-presence protocol)

/// Button to activate 7ay-presence protocol for peer-to-peer Bluetooth mesh communication
/// Enables users to communicate without internet using the 7ay-presence network
struct PresenceSignalButton: View {
    let action: () -> Void

    @State private var isActive = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var signalRotation: Double = 0

    var body: some View {
        Button {
            triggerActivation()
            action()
        } label: {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }

                // Pulse ring when active
                if isActive {
                    Circle()
                        .stroke(Theme.Colors.primaryFallback.opacity(0.4), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(pulseScale)
                        .opacity(2 - pulseScale)
                }

                // Signal icon
                IconView(.nearby, size: .md, color: isActive ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                    .rotationEffect(.degrees(signalRotation))
            }
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private func triggerActivation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isActive.toggle()
            signalRotation = isActive ? 15 : 0
        }

        if isActive {
            // Start pulse animation
            withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                pulseScale = 1.8
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1.0
            }
        }
    }
}

// MARK: - Notification Bell Button (Liquid Glass)

/// Notification button with liquid glass style
struct NotificationBellButton: View {
    let action: () -> Void

    @State private var hasNotifications = true
    @State private var bellRotation: Double = 0

    var body: some View {
        Button {
            triggerAnimation()
            action()
        } label: {
            ZStack {
                // Liquid glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }

                // Bell icon
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .rotationEffect(.degrees(bellRotation))

                // Notification dot
                if hasNotifications {
                    Circle()
                        .fill(Theme.Colors.error)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle()
                                .strokeBorder(Theme.Colors.background, lineWidth: 2)
                        }
                        .offset(x: 10, y: -10)
                }
            }
        }
        .buttonStyle(AnimatedButtonStyle())
    }

    private func triggerAnimation() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        // Bell ring animation
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            bellRotation = 15
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3).delay(0.1)) {
            bellRotation = -15
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3).delay(0.2)) {
            bellRotation = 10
        }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5).delay(0.3)) {
            bellRotation = 0
        }
    }
}

// MARK: - Wallet Sheet View

private struct WalletSheetView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dismiss) private var dismiss

    @State private var currentUser: User?
    @State private var isDisconnecting = false
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Capsule()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, Theme.Spacing.sm)

            Text("Profile")
                .font(Typography.titleLarge)
                .foregroundStyle(Theme.Colors.textPrimary)

            if isLoading {
                ProgressView()
                    .padding(.vertical, Theme.Spacing.xl)
            } else if let user = currentUser {
                profileCard(for: user)

                Spacer()

                Button {
                    disconnect()
                } label: {
                    HStack {
                        if isDisconnecting {
                            ProgressView()
                                .tint(Theme.Colors.error)
                                .scaleEffect(0.8)
                        }
                        Text("Disconnect")
                            .font(Typography.titleSmall)
                    }
                    .foregroundStyle(Theme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                            .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                    }
                }
                .buttonStyle(AnimatedButtonStyle())
                .disabled(isDisconnecting)
            } else {
                Text("Not connected")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.vertical, Theme.Spacing.xl)
            }

            SecondaryButton("Done") {
                dismiss()
            }
        }
        .padding()
        .background(Theme.Colors.background)
        .task {
            isLoading = true
            currentUser = await dependencies.authenticationRepository.currentUser
            isLoading = false
        }
    }

    @ViewBuilder
    private func profileCard(for user: User) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 80, height: 80)

                IconView(user.authMethod.isWallet ? .wallet : .google, size: .xl, color: Theme.Colors.primaryFallback)
            }

            VStack(spacing: Theme.Spacing.xxs) {
                if let displayName = user.displayName {
                    Text(displayName)
                        .font(Typography.titleMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Text(user.displayIdentifier)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }

    private func disconnect() {
        isDisconnecting = true
        Task {
            try? await dependencies.authenticationRepository.disconnect()
            await MainActor.run {
                dismiss()
                coordinator.handleWalletDisconnected()
            }
        }
    }
}

// MARK: - Presence Network Sheet View (7ay-presence protocol)

/// Sheet view for 7ay-presence network status and controls
/// Enables peer-to-peer communication via Bluetooth mesh without internet
private struct PresenceNetworkSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isNetworkActive = false
    @State private var nearbyPeers: Int = 0
    @State private var signalStrength: Double = 0
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            Capsule()
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, Theme.Spacing.sm)

            // Title and subtitle
            VStack(spacing: Theme.Spacing.xxs) {
                Text("7ay-presence")
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Peer-to-Peer Network")
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            // Network visualization
            ZStack {
                // Animated rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            Theme.Colors.primaryFallback.opacity(isNetworkActive ? 0.3 - Double(index) * 0.1 : 0.1),
                            lineWidth: 2
                        )
                        .frame(
                            width: CGFloat(80 + index * 40),
                            height: CGFloat(80 + index * 40)
                        )
                        .scaleEffect(isNetworkActive && isScanning ? 1.1 : 1.0)
                        .animation(
                            isScanning
                                ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2)
                                : .default,
                            value: isScanning
                        )
                }

                // Center icon
                ZStack {
                    Circle()
                        .fill(isNetworkActive ? Theme.Colors.primaryFallback.opacity(0.2) : Theme.Colors.backgroundTertiary)
                        .frame(width: 80, height: 80)

                    IconView(.nearby, size: .xl, color: isNetworkActive ? Theme.Colors.primaryFallback : Theme.Colors.textTertiary)
                }
            }
            .frame(height: 200)

            // Status info
            VStack(spacing: Theme.Spacing.md) {
                statusRow(
                    icon: .nearby,
                    title: "Network Status",
                    value: isNetworkActive ? "Active" : "Inactive",
                    color: isNetworkActive ? Theme.Colors.success : Theme.Colors.textTertiary
                )

                statusRow(
                    icon: .participants,
                    title: "Nearby Peers",
                    value: "\(nearbyPeers)",
                    color: Theme.Colors.primaryFallback
                )

                statusRow(
                    icon: .radar,
                    title: "Signal Range",
                    value: isNetworkActive ? "~50m" : "--",
                    color: Theme.Colors.info
                )
            }
            .padding(Theme.Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Description
            Text("Connect with nearby users via Bluetooth mesh without internet. Share presence data securely within epochs.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            // Toggle button
            Button {
                toggleNetwork()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    if isScanning {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }

                    Text(isNetworkActive ? "Disconnect" : "Activate Network")
                        .font(Typography.titleSmall)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    if isNetworkActive {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                            .fill(Theme.Colors.error)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                            .fill(Theme.Colors.primaryGradient)
                    }
                }
            }
            .buttonStyle(AnimatedButtonStyle())
            .padding(.horizontal, Theme.Spacing.md)

            // Close button
            SecondaryButton("Close") {
                dismiss()
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.bottom, Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    private func statusRow(icon: AppIcon, title: String, value: String, color: Color) -> some View {
        HStack {
            HStack(spacing: Theme.Spacing.sm) {
                IconView(icon, size: .sm, color: color)
                Text(title)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(value)
                .font(Typography.titleSmall)
                .foregroundStyle(color)
        }
    }

    private func toggleNetwork() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        if isNetworkActive {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isNetworkActive = false
                isScanning = false
                nearbyPeers = 0
            }
        } else {
            isScanning = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isNetworkActive = true
            }

            // Simulate finding peers
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isScanning = false
                    nearbyPeers = Int.random(in: 1...8)
                }
            }
        }
    }
}

// MARK: - Notifications Sheet View

/// Sheet view for displaying user notifications
private struct NotificationsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var notifications: [NotificationItem] = NotificationItem.sampleNotifications

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: Theme.Spacing.sm) {
                Capsule()
                    .fill(Theme.Colors.textTertiary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, Theme.Spacing.sm)

                HStack {
                    Text("Notifications")
                        .font(Typography.headlineMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    if !notifications.isEmpty {
                        Button {
                            withAnimation {
                                notifications.removeAll()
                            }
                        } label: {
                            Text("Clear All")
                                .font(Typography.bodySmall)
                                .foregroundStyle(Theme.Colors.primaryFallback)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.bottom, Theme.Spacing.md)

            // Content
            if notifications.isEmpty {
                emptyState
            } else {
                notificationsList
            }
        }
        .background(Theme.Colors.background)
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.Colors.backgroundTertiary)
                    .frame(width: 100, height: 100)

                Image(systemName: "bell.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("No Notifications")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("You're all caught up!")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification) {
                        withAnimation {
                            notifications.removeAll { $0.id == notification.id }
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
}

// MARK: - Notification Item Model

struct NotificationItem: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool

    enum NotificationType {
        case epochActive
        case epochEnding
        case presenceValidated
        case newPeer
        case system

        var icon: AppIcon {
            switch self {
            case .epochActive: return .epochActive
            case .epochEnding: return .timer
            case .presenceValidated: return .presenceValidated
            case .newPeer: return .participants
            case .system: return .info
            }
        }

        var color: Color {
            switch self {
            case .epochActive: return Theme.Colors.epochActive
            case .epochEnding: return Theme.Colors.warning
            case .presenceValidated: return Theme.Colors.success
            case .newPeer: return Theme.Colors.primaryFallback
            case .system: return Theme.Colors.info
            }
        }
    }

    static var sampleNotifications: [NotificationItem] {
        [
            NotificationItem(
                type: .epochActive,
                title: "Epoch Now Active",
                message: "\"Downtown Meetup\" has started! Join now to participate.",
                timestamp: Date().addingTimeInterval(-300),
                isRead: false
            ),
            NotificationItem(
                type: .presenceValidated,
                title: "Presence Validated",
                message: "Your presence at \"Coffee Shop Hangout\" was validated by 5 peers.",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            NotificationItem(
                type: .newPeer,
                title: "New Peer Nearby",
                message: "3 new users joined the 7ay-presence network near you.",
                timestamp: Date().addingTimeInterval(-7200),
                isRead: true
            ),
            NotificationItem(
                type: .epochEnding,
                title: "Epoch Ending Soon",
                message: "\"Park Festival\" ends in 15 minutes. Finalize your presence!",
                timestamp: Date().addingTimeInterval(-10800),
                isRead: true
            )
        ]
    }
}

// MARK: - Notification Row

private struct NotificationRow: View {
    let notification: NotificationItem
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                IconView(notification.type.icon, size: .md, color: notification.type.color)
            }

            // Content
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack {
                    Text(notification.title)
                        .font(Typography.titleSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Spacer()

                    Text(timeAgo(notification.timestamp))
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Text(notification.message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .lineLimit(2)

                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Theme.Colors.primaryFallback)
                        .frame(width: 8, height: 8)
                        .padding(.top, Theme.Spacing.xxs)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .fill(notification.isRead ? Theme.Colors.backgroundSecondary : Theme.Colors.surface)
        }
        .overlay {
            if !notification.isRead {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .strokeBorder(notification.type.color.opacity(0.3), lineWidth: 1)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDismiss()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
