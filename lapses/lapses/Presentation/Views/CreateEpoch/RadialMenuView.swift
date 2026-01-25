import SwiftUI

// MARK: - Radial Menu View

/// Fluid radial menu with 3 segments
/// Gesture-driven with smooth transitions
struct RadialMenuView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var viewModel = RadialMenuViewModel()
    @State private var appeared = false
    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging = false
    @State private var hoveredSegment: MainRadialSegment?

    let onCreateEpoch: (EpochDuration, EpochVisibility) -> Void
    let onCaptureRequest: (CaptureType) -> Void
    let onDismiss: () -> Void

    private let segmentRadius: CGFloat = 110
    private let segmentSize: CGFloat = 64

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)

            ZStack {
                // Backdrop
                backdrop
                    .onTapGesture { dismissMenu() }

                // Menu container
                ZStack {
                    // Connection lines (when expanded)
                    if viewModel.expandedSegment != nil {
                        connectionLines
                    }

                    // Segments
                    ForEach(MainRadialSegment.allCases) { segment in
                        segmentView(segment)
                    }

                    // Nested options
                    if let expanded = viewModel.expandedSegment {
                        NestedRadialView(
                            segment: expanded,
                            activeOptionIndex: viewModel.activeSubOption,
                            onOptionSelected: { handleOptionSelected($0) },
                            onOptionHovered: { viewModel.activeSubOption = $0 }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }

                    // Center button
                    centerButton
                }
                .position(center)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(value.location, center: center)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                appeared = true
            }
            RadialHaptics.shared.menuAppear()
        }
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            // Blur
            Rectangle()
                .fill(.ultraThinMaterial)

            // Radial gradient
            RadialGradient(
                colors: [
                    Theme.Colors.primaryFallback.opacity(0.08),
                    .clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: appeared)
    }

    // MARK: - Connection Lines

    private var connectionLines: some View {
        ForEach(MainRadialSegment.allCases) { segment in
            if segment == viewModel.expandedSegment {
                let offset = segmentOffset(for: segment)
                Path { path in
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: offset.width, y: offset.height))
                }
                .stroke(
                    segment.accentColor.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - Segment View

    private func segmentView(_ segment: MainRadialSegment) -> some View {
        let isExpanded = viewModel.expandedSegment == segment
        let isOther = viewModel.expandedSegment != nil && !isExpanded
        let isHovered = hoveredSegment == segment && viewModel.expandedSegment == nil

        return Button {
            handleSegmentTap(segment)
        } label: {
            ZStack {
                // Glow
                if isExpanded || isHovered {
                    Circle()
                        .fill(segment.accentColor.opacity(0.25))
                        .frame(width: segmentSize + 20, height: segmentSize + 20)
                        .blur(radius: 12)
                }

                // Background
                Circle()
                    .fill(isExpanded ? segment.accentColor.opacity(0.2) : Theme.Colors.textOnAccent.opacity(0.08))
                    .frame(width: segmentSize, height: segmentSize)
                    .background {
                        if !isExpanded {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: segmentSize, height: segmentSize)
                        }
                    }

                // Border
                Circle()
                    .strokeBorder(
                        isExpanded ? segment.accentColor.opacity(0.6) : Theme.Colors.textOnAccent.opacity(0.1),
                        lineWidth: isExpanded ? 2 : 1
                    )
                    .frame(width: segmentSize, height: segmentSize)

                // Icon
                Image(systemName: segment.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isExpanded ? segment.accentColor : Theme.Colors.textOnAccent)
                    .scaleEffect(isExpanded ? 1.1 : 1)
            }
        }
        .buttonStyle(SegmentPressStyle())
        .offset(segmentOffset(for: segment, expanded: isExpanded))
        .scaleEffect(isOther ? 0.85 : 1)
        .opacity(isOther ? 0.4 : 1)
        .zIndex(isExpanded ? 10 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOther)
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    // MARK: - Center Button

    private var centerButton: some View {
        Button {
            if viewModel.expandedSegment != nil {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    viewModel.expandedSegment = nil
                    viewModel.activeSubOption = nil
                }
            } else {
                dismissMenu()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.Colors.textOnAccent.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                    }

                Circle()
                    .strokeBorder(Theme.Colors.textOnAccent.opacity(0.15), lineWidth: 1)
                    .frame(width: 48, height: 48)

                Image(systemName: viewModel.expandedSegment != nil ? "chevron.down" : "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textOnAccent.opacity(0.7))
            }
        }
        .buttonStyle(SegmentPressStyle())
    }

    // MARK: - Helpers

    private func segmentOffset(for segment: MainRadialSegment, expanded: Bool = false) -> CGSize {
        let angle = (segment.angle - 90) * .pi / 180
        let radius = expanded ? segmentRadius + 15 : segmentRadius
        return CGSize(
            width: radius * CGFloat(cos(angle)),
            height: radius * CGFloat(sin(angle))
        )
    }

    private func handleSegmentTap(_ segment: MainRadialSegment) {
        RadialHaptics.shared.segmentChange()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            if viewModel.expandedSegment == segment {
                viewModel.expandedSegment = nil
                viewModel.activeSubOption = nil
            } else {
                viewModel.expandedSegment = segment
                viewModel.activeSubOption = nil
            }
        }
    }

    private func handleOptionSelected(_ option: RadialSubOption) {
        viewModel.selectSubOption(option)

        if let capture = viewModel.pendingCaptureType {
            viewModel.clearPendingCapture()
            onCaptureRequest(capture)
            dismissMenu()
        }
    }

    private func handleDrag(_ location: CGPoint, center: CGPoint) {
        isDragging = true
        dragLocation = location

        // Calculate angle and distance from center
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance > 50 && distance < segmentRadius + 40 && viewModel.expandedSegment == nil {
            // Find closest segment
            var angle = atan2(dy, dx) * 180 / .pi + 90
            if angle < 0 { angle += 360 }

            let closest = MainRadialSegment.allCases.min {
                abs(angleDiff($0.angle, angle)) < abs(angleDiff($1.angle, angle))
            }

            if hoveredSegment != closest {
                hoveredSegment = closest
                RadialHaptics.shared.lightTap()
            }
        } else {
            hoveredSegment = nil
        }
    }

    private func handleDragEnd() {
        isDragging = false

        if let hovered = hoveredSegment {
            handleSegmentTap(hovered)
        }

        hoveredSegment = nil
    }

    private func angleDiff(_ a: Double, _ b: Double) -> Double {
        var diff = a - b
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private func dismissMenu() {
        RadialHaptics.shared.dismiss()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Segment Press Style

private struct SegmentPressStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
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
    RadialMenuView(
        onCreateEpoch: { _, _ in },
        onCaptureRequest: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
