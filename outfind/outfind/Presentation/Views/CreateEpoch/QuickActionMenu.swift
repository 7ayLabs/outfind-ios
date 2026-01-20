
import SwiftUI

// MARK: - Quick Action Menu

/// Long-press gesture menu with radial options
/// Options appear around the pressed button, user drags to select
struct QuickActionMenu: View {
    @Environment(\.colorScheme) private var colorScheme

    let anchor: CGPoint
    let onCreateEpoch: () -> Void
    let onCamera: () -> Void
    let onMicrophone: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var backdropOpacity: Double = 0
    @State private var dragLocation: CGPoint?
    @State private var hoveredAction: QuickAction?
    @State private var actionAppeared: [QuickAction: Bool] = [:]

    private let actionRadius: CGFloat = 80
    private let actionSize: CGFloat = 54
    private let verticalOffset: CGFloat = -60 // Move menu up above navbar

    enum QuickAction: CaseIterable {
        case create
        case camera
        case microphone

        var icon: String {
            switch self {
            case .create: return "plus"
            case .camera: return "camera.fill"
            case .microphone: return "mic.fill"
            }
        }

        var label: String {
            switch self {
            case .create: return "Create"
            case .camera: return "Camera"
            case .microphone: return "Audio"
            }
        }

        var color: Color {
            switch self {
            case .create: return Theme.Colors.primaryFallback
            case .camera: return Theme.Colors.info
            case .microphone: return Theme.Colors.warning
            }
        }

        // Angle from center (0 = right, counter-clockwise)
        var angle: Double {
            switch self {
            case .create: return -90      // Top
            case .camera: return -155     // Top-left
            case .microphone: return -25  // Top-right
            }
        }

        var animationDelay: Double {
            switch self {
            case .camera: return 0.0
            case .create: return 0.04
            case .microphone: return 0.08
            }
        }
    }

    // Adjusted anchor point (moved up)
    private var menuCenter: CGPoint {
        CGPoint(x: anchor.x, y: anchor.y + verticalOffset)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Semi-transparent backdrop with blur
                Color.black.opacity(backdropOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissMenu()
                    }
                    .animation(.easeOut(duration: 0.2), value: backdropOpacity)

                // Menu container positioned above navbar
                ZStack {
                    // Connection lines to hovered action
                    if let hovered = hoveredAction {
                        connectionLine(to: hovered)
                            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: hoveredAction)
                    }

                    // Action buttons with staggered animation
                    ForEach(QuickAction.allCases, id: \.self) { action in
                        actionButton(action)
                    }

                    // Center indicator
                    centerIndicator
                }
                .position(menuCenter)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragLocation = value.location
                        updateHoveredAction(from: value.location)
                    }
                    .onEnded { _ in
                        selectHoveredAction()
                    }
            )
            .accessibilityIdentifier("QuickActionMenu")
        }
        .onAppear {
            // Staggered appearance animation
            withAnimation(.easeOut(duration: 0.2)) {
                backdropOpacity = 0.5
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                appeared = true
            }

            // Stagger each action button
            for action in QuickAction.allCases {
                withAnimation(
                    .spring(response: 0.35, dampingFraction: 0.65)
                    .delay(action.animationDelay)
                ) {
                    actionAppeared[action] = true
                }
            }

            RadialHaptics.shared.menuAppear()
        }
    }

    // MARK: - Center Indicator

    private var centerIndicator: some View {
        ZStack {
            // Glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (hoveredAction?.color ?? Theme.Colors.primaryFallback).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 15,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)
                .opacity(appeared ? 1 : 0)

            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 48, height: 48)

            Circle()
                .fill(hoveredAction != nil ? (hoveredAction?.color ?? .white).opacity(0.15) : .white.opacity(0.05))
                .frame(width: 48, height: 48)

            Circle()
                .strokeBorder(
                    hoveredAction != nil ? (hoveredAction?.color ?? .white).opacity(0.5) : .white.opacity(0.2),
                    lineWidth: 1.5
                )
                .frame(width: 48, height: 48)

            // Icon changes based on hover
            Group {
                if let hovered = hoveredAction {
                    Image(systemName: hovered.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(hovered.color)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: hoveredAction)
        }
        .scaleEffect(appeared ? 1 : 0.3)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appeared)
    }

    // MARK: - Action Button

    private func actionButton(_ action: QuickAction) -> some View {
        let isHovered = hoveredAction == action
        let offset = actionOffset(for: action)
        let isVisible = actionAppeared[action] ?? false

        return ZStack {
            // Glow when hovered
            if isHovered {
                Circle()
                    .fill(action.color.opacity(0.35))
                    .frame(width: actionSize + 24, height: actionSize + 24)
                    .blur(radius: 12)
                    .transition(.scale.combined(with: .opacity))
            }

            // Background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: actionSize, height: actionSize)

            Circle()
                .fill(isHovered ? action.color.opacity(0.2) : .white.opacity(0.05))
                .frame(width: actionSize, height: actionSize)

            // Border
            Circle()
                .strokeBorder(
                    isHovered ? action.color.opacity(0.8) : .white.opacity(0.15),
                    lineWidth: isHovered ? 2 : 1
                )
                .frame(width: actionSize, height: actionSize)

            // Content
            VStack(spacing: 3) {
                Image(systemName: action.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isHovered ? action.color : .white.opacity(0.9))

                Text(action.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isHovered ? action.color : .white.opacity(0.7))
            }
        }
        .offset(x: isVisible ? offset.width : 0, y: isVisible ? offset.height : 0)
        .scaleEffect(isVisible ? (isHovered ? 1.12 : 1) : 0.1)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHovered)
        .accessibilityIdentifier("QuickAction_\(action.label)")
        .accessibilityLabel(action.label)
    }

    // MARK: - Connection Line

    private func connectionLine(to action: QuickAction) -> some View {
        let offset = actionOffset(for: action)

        return Path { path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: offset.width, y: offset.height))
        }
        .stroke(
            LinearGradient(
                colors: [action.color.opacity(0.1), action.color.opacity(0.5)],
                startPoint: .center,
                endPoint: offset.width < 0 ? .leading : (offset.width > 0 ? .trailing : .top)
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Helpers

    private func actionOffset(for action: QuickAction) -> CGSize {
        let angle = action.angle * .pi / 180
        return CGSize(
            width: actionRadius * CGFloat(Darwin.cos(angle)),
            height: actionRadius * CGFloat(Darwin.sin(angle))
        )
    }

    private func updateHoveredAction(from location: CGPoint) {
        let dx = location.x - menuCenter.x
        let dy = location.y - menuCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        // Only detect hover if dragged far enough
        guard distance > 35 else {
            if hoveredAction != nil {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    hoveredAction = nil
                }
            }
            return
        }

        // Calculate angle
        let angle = atan2(dy, dx) * 180 / .pi

        // Find closest action
        let closest = QuickAction.allCases.min { a, b in
            abs(angleDiff(a.angle, angle)) < abs(angleDiff(b.angle, angle))
        }

        if hoveredAction != closest {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                hoveredAction = closest
            }
            RadialHaptics.shared.lightTap()
        }
    }

    private func angleDiff(_ a: Double, _ b: Double) -> Double {
        var diff = a - b
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private func selectHoveredAction() {
        guard let action = hoveredAction else {
            dismissMenu()
            return
        }

        RadialHaptics.shared.selectionMade()

        // Animate out with selected action growing
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            appeared = false
            backdropOpacity = 0
            for a in QuickAction.allCases {
                actionAppeared[a] = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            switch action {
            case .create:
                onCreateEpoch()
            case .camera:
                onCamera()
            case .microphone:
                onMicrophone()
            }
        }
    }

    private func dismissMenu() {
        RadialHaptics.shared.dismiss()

        // Staggered disappear animation (reverse order)
        for action in QuickAction.allCases.reversed() {
            withAnimation(
                .spring(response: 0.2, dampingFraction: 0.8)
                .delay(action.animationDelay)
            ) {
                actionAppeared[action] = false
            }
        }

        withAnimation(.easeIn(duration: 0.15)) {
            backdropOpacity = 0
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.8).delay(0.05)) {
            appeared = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        QuickActionMenu(
            anchor: CGPoint(x: 200, y: 700),
            onCreateEpoch: {},
            onCamera: {},
            onMicrophone: {},
            onDismiss: {}
        )
    }
}
