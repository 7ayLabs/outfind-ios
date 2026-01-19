import SwiftUI

// MARK: - Radial Menu View

/// Minimalist radial menu for quick epoch creation
/// Press and drag to select, releases commit selection
struct RadialMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RadialMenuViewModel()

    // Gesture state
    @State private var dragLocation: CGPoint = .zero
    @State private var menuCenter: CGPoint = .zero
    @GestureState private var isGestureActive = false

    // Animation state
    @State private var appearAnimation = false

    let onComplete: (EpochCreationData) -> Void
    let onDismiss: () -> Void

    private let menuRadius: CGFloat = 120
    private let segmentCount = 6
    private let subOptionThreshold: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Dimmed background - faster fade
                Color.black.opacity(appearAnimation ? 0.5 : 0)
                    .ignoresSafeArea()

                // Main radial menu - cleaner design
                ZStack {
                    // Simple dark background
                    Circle()
                        .fill(Color(hex: "1A1A1A").opacity(0.95))
                        .frame(width: menuRadius * 2 + 20, height: menuRadius * 2 + 20)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    Theme.Colors.liveGreen.opacity(viewModel.isDragging ? 0.6 : 0.3),
                                    lineWidth: viewModel.isDragging ? 2 : 1
                                )
                        }

                    // Segments - simplified
                    ForEach(Array(RadialSegment.allCases.enumerated()), id: \.element) { index, segment in
                        MinimalSegmentView(
                            segment: segment,
                            isActive: viewModel.activeSegment == segment,
                            isCompleted: isSegmentCompleted(segment),
                            isHovered: viewModel.isDragging && viewModel.activeSegment == segment
                        )
                        .offset(x: menuRadius * 0.65 * CGFloat(cos(Double(index) * .pi / 3 - .pi / 2)),
                                y: menuRadius * 0.65 * CGFloat(sin(Double(index) * .pi / 3 - .pi / 2)))
                    }

                    // Sub-options - radial display when hovering
                    if let activeSegment = viewModel.activeSegment, viewModel.isShowingSubOptions {
                        RadialSubOptionsView(
                            segment: activeSegment,
                            activeSubOption: viewModel.activeSubOption,
                            menuRadius: menuRadius
                        )
                    }

                    // Center - minimal
                    MinimalCenterView(
                        viewModel: viewModel,
                        onCreateTap: createEpoch
                    )
                }
                .scaleEffect(appearAnimation ? 1 : 0.8)
                .opacity(appearAnimation ? 1 : 0)
                .position(center)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value.location, center: center)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
            .onAppear {
                menuCenter = center
                withAnimation(.easeOut(duration: 0.2)) {
                    appearAnimation = true
                }
                RadialHaptics.shared.menuAppear()
            }
        }
    }

    // MARK: - Gesture Handling

    private func handleDragChanged(_ location: CGPoint, center: CGPoint) {
        // Mark as dragging
        if !viewModel.isDragging {
            viewModel.isDragging = true
        }

        dragLocation = location

        // Calculate angle and distance from center
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // Convert to angle in degrees (0-360, starting from top)
        var angle = atan2(dx, -dy) * 180 / .pi
        if angle < 0 { angle += 360 }

        // Only detect segments if within reasonable range
        let minDistance: CGFloat = 30
        let maxDistance: CGFloat = menuRadius + 80

        if distance > minDistance && distance < maxDistance {
            // Detect segment
            if let segment = viewModel.segmentAt(angle: angle) {
                let previousSegment = viewModel.activeSegment

                if previousSegment != segment {
                    withAnimation(.easeOut(duration: 0.1)) {
                        viewModel.activeSegment = segment
                        viewModel.activeSubOption = nil
                    }
                    RadialHaptics.shared.segmentChange()
                }

                // Show sub-options when past threshold
                if distance > subOptionThreshold {
                    if !viewModel.isShowingSubOptions {
                        withAnimation(.easeOut(duration: 0.1)) {
                            viewModel.isShowingSubOptions = true
                        }
                    }

                    // Detect sub-option
                    if let optionIndex = viewModel.subOptionIndex(distance: distance, for: segment) {
                        if viewModel.activeSubOption != optionIndex {
                            viewModel.activeSubOption = optionIndex
                            RadialHaptics.shared.optionHover()
                        }
                    }
                } else {
                    if viewModel.isShowingSubOptions {
                        withAnimation(.easeOut(duration: 0.1)) {
                            viewModel.isShowingSubOptions = false
                            viewModel.activeSubOption = nil
                        }
                    }
                }
            }
        } else if distance <= minDistance {
            // Inside center zone - clear selection
            if viewModel.activeSegment != nil {
                withAnimation(.easeOut(duration: 0.1)) {
                    viewModel.activeSegment = nil
                    viewModel.activeSubOption = nil
                    viewModel.isShowingSubOptions = false
                }
            }
        }
    }

    private func handleDragEnded() {
        viewModel.isDragging = false

        // Check if valid selection was made
        if let segment = viewModel.activeSegment,
           let optionIndex = viewModel.activeSubOption {
            // Valid selection - commit
            viewModel.selectOption(segment: segment, optionIndex: optionIndex)
            RadialHaptics.shared.selectionMade()

            // Check if all selections complete
            if viewModel.isComplete {
                RadialHaptics.shared.celebrate()
                // Small delay before showing create button feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Menu stays visible - user can tap center to create
                }
            }
        } else if viewModel.activeSegment == nil {
            // Released without any selection - dismiss menu
            RadialHaptics.shared.dismiss()
            dismissMenu()
            return
        }

        // Reset hover state but keep committed selections
        withAnimation(.easeOut(duration: 0.15)) {
            viewModel.activeSegment = nil
            viewModel.activeSubOption = nil
            viewModel.isShowingSubOptions = false
        }
    }

    // MARK: - Helper Methods

    private func isSegmentCompleted(_ segment: RadialSegment) -> Bool {
        switch segment {
        case .duration: return viewModel.currentStep > 0
        case .capability: return viewModel.currentStep > 1
        case .visibility: return viewModel.currentStep > 2
        case .category: return viewModel.currentStep > 3
        case .location: return true // Optional, always "completed"
        case .title: return !viewModel.suggestedTitles.isEmpty
        }
    }

    private func createEpoch() {
        RadialHaptics.shared.success()

        let data = EpochCreationData(
            duration: viewModel.selectedDuration,
            capability: viewModel.selectedCapability,
            visibility: viewModel.selectedVisibility,
            category: viewModel.selectedCategory,
            location: viewModel.selectedLocation,
            suggestedTitle: viewModel.suggestedTitles.first
        )

        dismissMenu()
        onComplete(data)
    }

    private func dismissMenu() {
        RadialHaptics.shared.dismiss()
        withAnimation(.easeOut(duration: 0.15)) {
            appearAnimation = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onDismiss()
        }
    }
}

// MARK: - Minimal Segment View

private struct MinimalSegmentView: View {
    let segment: RadialSegment
    let isActive: Bool
    let isCompleted: Bool
    var isHovered: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? segment.color.opacity(isHovered ? 0.4 : 0.2) : Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)

                Image(systemName: segment.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? segment.color : .white.opacity(0.6))

                if isCompleted {
                    Circle()
                        .strokeBorder(Theme.Colors.liveGreen, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }

                // Hover ring
                if isHovered {
                    Circle()
                        .strokeBorder(segment.color, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
            }

            Text(segment.displayName)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.5))
        }
        .scaleEffect(isHovered ? 1.2 : (isActive ? 1.1 : 1.0))
        .animation(.easeOut(duration: 0.1), value: isActive)
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

// MARK: - Radial Sub-Options View

private struct RadialSubOptionsView: View {
    let segment: RadialSegment
    let activeSubOption: Int?
    let menuRadius: CGFloat

    // Calculate segment center angle
    private var segmentCenterAngle: Double {
        let index = RadialSegment.allCases.firstIndex(of: segment) ?? 0
        // Each segment is 60 degrees, offset by -90 to start from top
        return Double(index) * 60 - 90
    }

    var body: some View {
        ForEach(Array(segment.options.prefix(4).enumerated()), id: \.offset) { index, option in
            let isActive = activeSubOption == index
            let distance = menuRadius + 50 + CGFloat(index) * 35
            let angleInRadians = segmentCenterAngle * .pi / 180

            SubOptionBubble(
                text: option,
                color: segment.color,
                isActive: isActive
            )
            .offset(
                x: distance * CGFloat(cos(angleInRadians)),
                y: distance * CGFloat(sin(angleInRadians))
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Sub-Option Bubble

private struct SubOptionBubble: View {
    let text: String
    let color: Color
    let isActive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isActive ? .white : .white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(isActive ? color : color.opacity(0.3))
            }
            .overlay {
                if isActive {
                    Capsule()
                        .strokeBorder(color, lineWidth: 2)
                }
            }
            .scaleEffect(isActive ? 1.15 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isActive)
    }
}

// MARK: - Minimal Center View

private struct MinimalCenterView: View {
    let viewModel: RadialMenuViewModel
    let onCreateTap: () -> Void

    var body: some View {
        if viewModel.isComplete {
            Button(action: onCreateTap) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Colors.liveGreen, Theme.Colors.primaryFallback],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            VStack(spacing: 4) {
                Text("\(viewModel.currentStep)/4")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Colors.liveGreen)

                Text(stepLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var stepLabel: String {
        switch viewModel.currentStep {
        case 0: return "Duration"
        case 1: return "Type"
        case 2: return "Visibility"
        case 3: return "Category"
        default: return "Ready"
        }
    }
}


// MARK: - Epoch Creation Data

struct EpochCreationData {
    let duration: EpochDuration
    let capability: EpochCapability
    let visibility: EpochVisibility
    let category: EpochCategory
    let location: RadialLocationOption
    let suggestedTitle: String?
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        RadialMenuView(
            onComplete: { _ in },
            onDismiss: {}
        )
    }
}
