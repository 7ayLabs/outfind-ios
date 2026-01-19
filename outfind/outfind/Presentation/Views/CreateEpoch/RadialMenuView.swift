import SwiftUI

// MARK: - Radial Menu View

/// Minimalist radial menu for quick epoch creation
/// Press and drag to select, releases commit selection
/// Monochromatic design with centered sub-options
struct RadialMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RadialMenuViewModel()

    // Gesture state
    @State private var dragLocation: CGPoint = .zero
    @State private var menuCenter: CGPoint = .zero
    @GestureState private var isGestureActive = false

    // Animation state
    @State private var appearAnimation = false
    @State private var pulseAnimation = false

    // Posting state
    @State private var isPosting = false
    @State private var postingComplete = false
    @State private var postingError: String?

    let onComplete: (EpochCreationData) -> Void
    let onDismiss: () -> Void

    private let menuRadius: CGFloat = 140
    private let segmentCount = 6
    private let subOptionThreshold: CGFloat = 70

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Blur background with dimming
                BlurBackgroundView(isVisible: appearAnimation)

                // Posting overlay
                if isPosting || postingComplete {
                    PostingBannerView(
                        isPosting: isPosting,
                        isComplete: postingComplete,
                        error: postingError,
                        onDismiss: {
                            dismissMenu()
                        }
                    )
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(100)
                } else {
                    // Main radial menu - transparent design
                    ZStack {
                        // Floating segments - no background, no colors
                        ForEach(Array(RadialSegment.allCases.enumerated()), id: \.element) { index, segment in
                            MinimalSegmentView(
                                segment: segment,
                                isActive: viewModel.activeSegment == segment,
                                isCompleted: isSegmentCompleted(segment),
                                isHovered: viewModel.isDragging && viewModel.activeSegment == segment
                            )
                            .offset(segmentOffset(index: index, isActive: viewModel.activeSegment == segment))
                            .opacity(viewModel.isShowingSubOptions && viewModel.activeSegment != segment ? 0.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.activeSegment)
                            .animation(.easeOut(duration: 0.2), value: viewModel.isShowingSubOptions)
                        }

                        // Center - minimal orb (fades when showing sub-options)
                        MinimalCenterView(
                            viewModel: viewModel,
                            onCreateTap: createEpoch
                        )
                        .opacity(viewModel.isShowingSubOptions ? 0.0 : 1.0)
                        .scaleEffect(viewModel.isShowingSubOptions ? 0.8 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: viewModel.isShowingSubOptions)

                        // CENTERED Sub-options - appear in the middle when hovering
                        if let activeSegment = viewModel.activeSegment, viewModel.isShowingSubOptions {
                            CenteredSubOptionsView(
                                segment: activeSegment,
                                activeSubOption: viewModel.activeSubOption
                            )
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    .opacity(appearAnimation ? 1 : 0)
                    .position(center)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isPosting && !postingComplete {
                            handleDragChanged(value.location, center: center)
                        }
                    }
                    .onEnded { _ in
                        if !isPosting && !postingComplete {
                            handleDragEnded()
                        }
                    }
            )
            .onAppear {
                menuCenter = center
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appearAnimation = true
                }
                // Start pulse animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
                RadialHaptics.shared.menuAppear()
            }
        }
    }

    // MARK: - Segment Positioning

    private func segmentOffset(index: Int, isActive: Bool) -> CGSize {
        let baseRadius = menuRadius * 0.7
        let activeRadius = menuRadius * 0.85
        let radius = isActive ? activeRadius : baseRadius
        let angle = Double(index) * .pi / 3 - .pi / 2

        return CGSize(
            width: radius * CGFloat(cos(angle)),
            height: radius * CGFloat(sin(angle))
        )
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
        let maxDistance: CGFloat = menuRadius + 120

        if distance > minDistance && distance < maxDistance {
            // Detect segment
            if let segment = viewModel.segmentAt(angle: angle) {
                let previousSegment = viewModel.activeSegment

                if previousSegment != segment {
                    withAnimation(.easeOut(duration: 0.15)) {
                        viewModel.activeSegment = segment
                        viewModel.activeSubOption = nil
                    }
                    RadialHaptics.shared.segmentChange()
                }

                // Show sub-options when past threshold
                if distance > subOptionThreshold {
                    if !viewModel.isShowingSubOptions {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewModel.isShowingSubOptions = true
                        }
                    }

                    // Detect sub-option based on angle within segment
                    let optionCount = min(segment.options.count, 6)
                    let segmentStartAngle = segment.startAngle
                    let segmentEndAngle = segment.endAngle

                    // Normalize angles
                    var normalizedAngle = angle
                    var normalizedStart = segmentStartAngle
                    var normalizedEnd = segmentEndAngle

                    if normalizedEnd < normalizedStart {
                        normalizedEnd += 360
                        if normalizedAngle < normalizedStart {
                            normalizedAngle += 360
                        }
                    }

                    // Calculate which option based on angle position within segment
                    let angleProgress = (normalizedAngle - normalizedStart) / (normalizedEnd - normalizedStart)
                    let optionIndex = Int(angleProgress * Double(optionCount))
                    let clampedIndex = max(0, min(optionCount - 1, optionIndex))

                    if viewModel.activeSubOption != clampedIndex {
                        viewModel.activeSubOption = clampedIndex
                        RadialHaptics.shared.optionHover()
                    }
                } else {
                    if viewModel.isShowingSubOptions {
                        withAnimation(.easeOut(duration: 0.15)) {
                            viewModel.isShowingSubOptions = false
                            viewModel.activeSubOption = nil
                        }
                    }
                }
            }
        } else if distance <= minDistance {
            // Inside center zone - clear selection
            if viewModel.activeSegment != nil {
                withAnimation(.easeOut(duration: 0.15)) {
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
        RadialHaptics.shared.selectionMade()

        let data = EpochCreationData(
            duration: viewModel.selectedDuration,
            capability: viewModel.selectedCapability,
            visibility: viewModel.selectedVisibility,
            category: viewModel.selectedCategory,
            location: viewModel.selectedLocation,
            suggestedTitle: viewModel.suggestedTitles.first
        )

        // Start posting animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPosting = true
        }

        // Simulate posting (replace with actual API call)
        Task {
            do {
                // Simulate network delay
                try await Task.sleep(nanoseconds: 2_000_000_000)

                await MainActor.run {
                    RadialHaptics.shared.celebrate()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPosting = false
                        postingComplete = true
                    }
                }

                // Auto-dismiss after showing success
                try await Task.sleep(nanoseconds: 1_500_000_000)

                await MainActor.run {
                    onComplete(data)
                    dismissMenu()
                }
            } catch {
                await MainActor.run {
                    RadialHaptics.shared.error()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPosting = false
                        postingError = "Failed to create epoch"
                    }
                }
            }
        }
    }

    private func dismissMenu() {
        RadialHaptics.shared.dismiss()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appearAnimation = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Blur Background View

private struct BlurBackgroundView: View {
    let isVisible: Bool

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(isVisible ? 0.7 : 0)

            // Blur effect
            if isVisible {
                VisualEffectBlur(blurStyle: .dark)
                    .opacity(isVisible ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.3), value: isVisible)
    }
}

// MARK: - Visual Effect Blur

private struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Posting Banner View

private struct PostingBannerView: View {
    let isPosting: Bool
    let isComplete: Bool
    let error: String?
    let onDismiss: () -> Void

    @State private var dotAnimation = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Main banner card - monochromatic
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                ZStack {
                    // Glow - white only
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    // Icon background - monochrome
                    Circle()
                        .fill(Color.white.opacity(isComplete ? 0.9 : 0.15))
                        .frame(width: 72, height: 72)

                    // Icon
                    Group {
                        if isPosting {
                            // Loading spinner
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(dotAnimation ? 360 : 0))
                        } else if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.black)
                        } else if error != nil {
                            Image(systemName: "xmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                // Status text
                VStack(spacing: Theme.Spacing.xs) {
                    Text(statusTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text(statusSubtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }

                // Error retry button
                if error != nil {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            }
                    }
                }
            }
            .padding(Theme.Spacing.xl)
            .background {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 32)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    }
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                dotAnimation = true
            }
        }
    }

    private var statusTitle: String {
        if error != nil {
            return "Oops!"
        } else if isComplete {
            return "Epoch Live!"
        } else {
            return "Creating Epoch"
        }
    }

    private var statusSubtitle: String {
        if let error = error {
            return error
        } else if isComplete {
            return "Your epoch is now live and ready for participants"
        } else {
            return "Setting up your ephemeral space..."
        }
    }
}

// MARK: - Minimal Segment View (Monochromatic)

private struct MinimalSegmentView: View {
    let segment: RadialSegment
    let isActive: Bool
    let isCompleted: Bool
    var isHovered: Bool = false

    var body: some View {
        ZStack {
            // Main icon circle - no colors, pure white/gray
            ZStack {
                // Background - glass effect
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 52, height: 52)
                    .opacity(isActive ? 1 : 0.5)

                // White overlay when active
                if isActive {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                }

                // Icon - monochrome
                Image(systemName: segment.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.5))
                    .symbolEffect(.bounce, value: isHovered)

                // Completion checkmark - subtle white
                if isCompleted && !isActive {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 16, height: 16)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        .offset(x: 18, y: -18)
                }

                // Hover ring - white
                if isHovered {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 58, height: 58)
                }
            }

            // Label
            Text(segment.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.4))
                .offset(y: 38)
        }
        .scaleEffect(isHovered ? 1.2 : (isActive ? 1.1 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
    }
}

// MARK: - Centered Sub-Options View (Appears in center when hovering)

private struct CenteredSubOptionsView: View {
    let segment: RadialSegment
    let activeSubOption: Int?

    var body: some View {
        VStack(spacing: 12) {
            // Segment title
            Text(segment.displayName.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            // Options in vertical list
            VStack(spacing: 8) {
                ForEach(Array(segment.options.prefix(6).enumerated()), id: \.offset) { index, option in
                    CenteredOptionRow(
                        text: option,
                        isActive: activeSubOption == index,
                        index: index
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

// MARK: - Centered Option Row

private struct CenteredOptionRow: View {
    let text: String
    let isActive: Bool
    let index: Int

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Circle()
                .fill(isActive ? Color.white : Color.white.opacity(0.2))
                .frame(width: 8, height: 8)

            // Option text
            Text(text)
                .font(.system(size: 16, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .white : .white.opacity(0.6))

            Spacer()

            // Checkmark when active
            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
            }
        }
        .scaleEffect(isActive ? 1.02 : (appeared ? 1.0 : 0.9))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.03)) {
                appeared = true
            }
        }
    }
}

// MARK: - Minimal Center View (Monochromatic)

private struct MinimalCenterView: View {
    let viewModel: RadialMenuViewModel
    let onCreateTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Main orb
            Button(action: {
                if viewModel.isComplete {
                    onCreateTap()
                }
            }) {
                ZStack {
                    // Glass background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)

                    // White fill when complete
                    if viewModel.isComplete {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 60, height: 60)
                    }

                    // Content
                    if viewModel.isComplete {
                        // Create icon
                        Image(systemName: "arrow.up")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.black)
                    } else {
                        // Step indicator - simple text
                        Text("\(viewModel.currentStep)/4")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // Outer ring
                    Circle()
                        .strokeBorder(
                            Color.white.opacity(viewModel.isComplete ? 0.8 : 0.2),
                            lineWidth: 2
                        )
                        .frame(width: 64, height: 64)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .scaleEffect(viewModel.isComplete ? pulseScale : 1.0)
            .disabled(!viewModel.isComplete)
        }
        .onAppear {
            if viewModel.isComplete {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
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
