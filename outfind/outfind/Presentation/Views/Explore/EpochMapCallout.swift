import SwiftUI

// MARK: - Epoch Map Callout

/// Bottom card showing selected epoch details with Join button
struct EpochMapCallout: View {
    let epoch: Epoch
    let onJoin: () -> Void
    let onDismiss: () -> Void
    var bottomSafeArea: CGFloat = 0

    @State private var offset: CGFloat = 250
    @State private var isFavorited = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, Theme.Spacing.sm)

            // Content
            VStack(spacing: Theme.Spacing.md) {
                // Header row
                HStack(spacing: Theme.Spacing.md) {
                    // Epoch icon/image
                    epochIcon

                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            // State badge
                            stateBadge

                            Spacer()

                            // Favorite button
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isFavorited.toggle()
                                }
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                            } label: {
                                Image(systemName: isFavorited ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundStyle(isFavorited ? Theme.Colors.error : Theme.Colors.textSecondary)
                                    .scaleEffect(isFavorited ? 1.1 : 1.0)
                            }
                        }

                        Text(epoch.title)
                            .font(Typography.titleSmall)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineLimit(1)

                        // Meta info
                        HStack(spacing: Theme.Spacing.sm) {
                            Label("\(epoch.participantCount)", systemImage: "person.2.fill")
                            Text("·")
                                .foregroundStyle(Theme.Colors.textTertiary)
                            Label(timeRemaining, systemImage: "clock.fill")

                            if let locationName = epoch.location?.name {
                                Text("·")
                                    .foregroundStyle(Theme.Colors.textTertiary)
                                Label(locationName, systemImage: "mappin")
                                    .lineLimit(1)
                            }
                        }
                        .font(Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                // Description if available
                if let description = epoch.description {
                    Text(description)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Capability badges
                capabilityBadges

                // Join button
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onJoin()
                }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: epoch.state == .active ? "arrow.right.circle.fill" : "bell.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(epoch.state == .active ? "Join Epoch" : "Notify Me")
                            .font(Typography.titleSmall)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(
                                LinearGradient(
                                    colors: [stateColor, stateColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .shadow(color: stateColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(Theme.Spacing.md)
        }
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, bottomSafeArea + 90) // Account for tab bar
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        offset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 300
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offset = 0
            }
        }
    }

    // MARK: - Subviews

    private var epochIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [stateColor.opacity(0.3), stateColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)

            Image(systemName: capabilityIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(stateColor)
        }
    }

    private var stateBadge: some View {
        HStack(spacing: 4) {
            if epoch.state == .active {
                Circle()
                    .fill(Theme.Colors.epochActive)
                    .frame(width: 8, height: 8)
            }

            Text(epoch.state == .active ? "LIVE" : "UPCOMING")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(stateColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(stateColor.opacity(0.15))
        }
    }

    private var capabilityBadges: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if epoch.capability.supportsDiscovery {
                capabilityChip(icon: "antenna.radiowaves.left.and.right", text: "Discovery")
            }
            if epoch.capability.supportsMessaging {
                capabilityChip(icon: "bubble.left.and.bubble.right", text: "Signals")
            }
            if epoch.capability.supportsMedia {
                capabilityChip(icon: "camera", text: "Media")
            }
            Spacer()
        }
    }

    private func capabilityChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(Theme.Colors.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(Theme.Colors.backgroundTertiary)
        }
    }

    // MARK: - Computed Properties

    private var stateColor: Color {
        switch epoch.state {
        case .active: return Theme.Colors.epochActive
        case .scheduled: return Theme.Colors.epochScheduled
        default: return Theme.Colors.textTertiary
        }
    }

    private var capabilityIcon: String {
        switch epoch.capability {
        case .presenceOnly: return "person.fill"
        case .presenceWithSignals: return "bubble.left.and.bubble.right.fill"
        case .presenceWithEphemeralData: return "camera.fill"
        }
    }

    private var timeRemaining: String {
        let time = epoch.timeUntilNextPhase
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60

        if epoch.state == .active {
            if hours > 0 {
                return "\(hours)h \(minutes)m left"
            } else if minutes > 0 {
                return "\(minutes)m left"
            } else {
                return "Ending soon"
            }
        } else {
            if hours > 24 {
                return "in \(hours / 24)d"
            } else if hours > 0 {
                return "in \(hours)h"
            } else {
                return "in \(minutes)m"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            Spacer()
            EpochMapCallout(
                epoch: .mock(
                    title: "Tech Meetup 2026",
                    state: .active,
                    capability: .presenceWithEphemeralData,
                    participantCount: 42,
                    location: EpochLocation(latitude: 37.7749, longitude: -122.4194, radius: 500, name: "Downtown SF")
                ),
                onJoin: {},
                onDismiss: {}
            )
        }
    }
}
