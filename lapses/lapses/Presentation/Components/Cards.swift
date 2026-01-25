import SwiftUI

// MARK: - Epoch Card

struct EpochCard: View {
    let epoch: Epoch
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header
                HStack {
                    EpochStateIcon(epoch.state, size: .lg)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(epoch.title)
                            .font(Typography.titleMedium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        Text(epoch.state.displayName)
                            .font(Typography.labelMedium)
                            .foregroundStyle(stateColor)
                    }

                    Spacer()

                    IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
                }

                // Description
                if let description = epoch.description {
                    Text(description)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                // Footer
                HStack(spacing: Theme.Spacing.md) {
                    // Participants
                    HStack(spacing: Theme.Spacing.xxs) {
                        IconView(.participants, size: .sm, color: Theme.Colors.textTertiary)
                        Text("\(epoch.participantCount)")
                            .font(Typography.labelMedium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    // Capability
                    CapabilityBadge(capability: epoch.capability)

                    Spacer()

                    // Timer
                    if epoch.state == .active || epoch.state == .scheduled {
                        TimerBadge(timeRemaining: epoch.timeUntilNextPhase)
                    }
                }
            }
            .glassCard(style: .regular, cornerRadius: Theme.CornerRadius.lg)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var stateColor: Color {
        switch epoch.state {
        case .none: return Theme.Colors.textTertiary
        case .scheduled: return Theme.Colors.epochScheduled
        case .active: return Theme.Colors.epochActive
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        }
    }
}

// MARK: - Capability Badge

struct CapabilityBadge: View {
    let capability: EpochCapability

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            IconView(icon, size: .xs, color: Theme.Colors.textTertiary)
            Text(capability.displayName)
                .font(Typography.labelSmall)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background {
            Capsule()
                .fill(Theme.Colors.backgroundTertiary)
        }
    }

    private var icon: AppIcon {
        switch capability {
        case .presenceOnly: return .presenceOnly
        case .presenceWithSignals: return .signals
        case .presenceWithEphemeralData: return .media
        }
    }
}

// MARK: - Timer Badge

struct TimerBadge: View {
    let timeRemaining: TimeInterval

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            IconView(.timer, size: .xs, color: timerColor)
            Text(formattedTime)
                .font(Typography.captionMono)
                .foregroundStyle(timerColor)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background {
            Capsule()
                .fill(timerColor.opacity(0.15))
        }
    }

    private var formattedTime: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) / 60 % 60
        let seconds = Int(timeRemaining) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var timerColor: Color {
        if timeRemaining < 60 {
            return Theme.Colors.error
        } else if timeRemaining < 300 {
            return Theme.Colors.warning
        }
        return Theme.Colors.textSecondary
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let title: String
    let value: String
    let icon: AppIcon
    let color: Color

    init(
        title: String,
        value: String,
        icon: AppIcon,
        color: Color = Theme.Colors.primaryFallback
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                IconView(icon, size: .md, color: color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(value)
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let title: String
    let message: String
    let status: StatusIcon.Status
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        status: StatusIcon.Status,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.status = status
        self.action = action
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatusIcon(status, size: .xl)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer()

            if action != nil {
                IconView(.forward, size: .sm, color: Theme.Colors.textTertiary)
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
        .onTapGesture {
            action?()
        }
    }
}

// MARK: - Wallet Card

struct WalletCard: View {
    let wallet: Wallet
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Wallet icon with gradient
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryGradient)
                    .frame(width: 48, height: 48)

                IconView(.wallet, size: .lg, color: Theme.Colors.textOnAccent)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Connected Wallet")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text(wallet.address.abbreviated)
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer()

            IconButton(.close, size: .sm, color: Theme.Colors.textTertiary) {
                onDisconnect()
            }
        }
        .glassCard(style: .regular, cornerRadius: Theme.CornerRadius.lg)
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: AppIcon
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: AppIcon,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            LiquidGlassOrb(size: 80, color: Theme.Colors.primaryFallback)
                .overlay {
                    IconView(icon, size: .xl, color: Theme.Colors.primaryFallback)
                }

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Typography.titleLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                SecondaryButton(actionTitle, action: action)
                    .frame(width: 200)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Previews

#Preview("Cards") {
    ScrollView {
        VStack(spacing: Theme.Spacing.lg) {
            EpochCard(epoch: .mock()) {}

            HStack {
                InfoCard(title: "Participants", value: "42", icon: .participants)
                InfoCard(title: "Time Left", value: "1:23:45", icon: .timer, color: Theme.Colors.success)
            }

            StatusCard(
                title: "Presence Declared",
                message: "Awaiting validator confirmation",
                status: .warning
            )

            WalletCard(wallet: .mock()) {}

            EmptyStateCard(
                icon: .mapPinCircle,
                title: "No Epochs Nearby",
                message: "Check back later or expand your search radius",
                actionTitle: "Refresh"
            ) {}
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
