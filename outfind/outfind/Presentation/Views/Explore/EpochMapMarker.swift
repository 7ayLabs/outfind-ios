import SwiftUI

// MARK: - Epoch Map Marker

/// Animated circular marker for epochs on the map (Snapchat-style)
struct EpochMapMarker: View {
    let epoch: Epoch
    let isSelected: Bool

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var glowScale: CGFloat = 1.0

    private let markerSize: CGFloat = 44

    var body: some View {
        ZStack {
            // Outer glow ring (when selected)
            if isSelected {
                Circle()
                    .stroke(stateColor.opacity(0.4), lineWidth: 3)
                    .frame(width: markerSize + 16, height: markerSize + 16)
                    .scaleEffect(glowScale)
            }

            // Pulsing ring for active epochs
            if epoch.state == .active && !isSelected {
                Circle()
                    .stroke(stateColor.opacity(0.3), lineWidth: 2)
                    .frame(width: markerSize + 8, height: markerSize + 8)
                    .scaleEffect(glowScale)
            }

            // Main marker circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [stateColor, stateColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: markerSize, height: markerSize)
                .overlay {
                    // Epoch icon
                    Image(systemName: capabilityIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2.5)
                }
                .shadow(color: stateColor.opacity(0.5), radius: isSelected ? 12 : 6, x: 0, y: 4)

            // Time badge at bottom (only show if there's a label)
            if !timeLabel.isEmpty {
                VStack {
                    Spacer()
                        .frame(height: markerSize - 4)

                    Text(timeLabel)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(.black.opacity(0.7))
                        }
                }
            }
        }
        .frame(width: markerSize + 20, height: markerSize + 24)
        .scaleEffect(scale * (isSelected ? 1.15 : 1.0))
        .opacity(opacity)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
        .onAppear {
            // Staggered appearance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double.random(in: 0...0.3))) {
                scale = 1.0
                opacity = 1.0
            }

            // Pulsing animation for active epochs
            if epoch.state == .active {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowScale = 1.2
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var stateColor: Color {
        switch epoch.state {
        case .active:
            return Theme.Colors.epochActive
        case .scheduled:
            return Theme.Colors.epochScheduled
        case .closed:
            return Theme.Colors.epochClosed
        case .finalized:
            return Theme.Colors.epochFinalized
        case .none:
            return Theme.Colors.textTertiary
        }
    }

    private var capabilityIcon: String {
        switch epoch.capability {
        case .presenceOnly:
            return "person.fill"
        case .presenceWithSignals:
            return "bubble.left.and.bubble.right.fill"
        case .presenceWithEphemeralData:
            return "camera.fill"
        }
    }

    private var timeLabel: String {
        let time = epoch.timeUntilNextPhase
        if epoch.state == .active {
            if time < 60 {
                return "NOW"
            } else if time < 3600 {
                return "\(Int(time / 60))m"
            } else {
                return "\(Int(time / 3600))h"
            }
        } else if epoch.state == .scheduled {
            if time < 3600 {
                return "in \(Int(time / 60))m"
            } else if time < 86400 {
                return "in \(Int(time / 3600))h"
            } else {
                return "soon"
            }
        }
        return ""
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        HStack(spacing: 40) {
            EpochMapMarker(
                epoch: .mock(state: .active, capability: .presenceWithEphemeralData),
                isSelected: false
            )

            EpochMapMarker(
                epoch: .mock(state: .active, capability: .presenceWithSignals),
                isSelected: true
            )

            EpochMapMarker(
                epoch: .mock(state: .scheduled, capability: .presenceOnly),
                isSelected: false
            )
        }
    }
}
