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
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0

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
                        // Subtle glow ring when dragging
                        if viewModel.isDragging {
                            Circle()
                                .stroke(
                                    RadialGradient(
                                        colors: [
                                            Theme.Colors.liveGreen.opacity(0.4),
                                            Theme.Colors.liveGreen.opacity(0)
                                        ],
                                        center: .center,
                                        startRadius: menuRadius - 20,
                                        endRadius: menuRadius + 40
                                    ),
                                    lineWidth: 60
                                )
                                .frame(width: menuRadius * 2, height: menuRadius * 2)
                                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                        }

                        // Floating segments - no background
                        ForEach(Array(RadialSegment.allCases.enumerated()), id: \.element) { index, segment in
                            FloatingSegmentView(
                                segment: segment,
                                isActive: viewModel.activeSegment == segment,
                                isCompleted: isSegmentCompleted(segment),
                                isHovered: viewModel.isDragging && viewModel.activeSegment == segment,
                                dragProgress: viewModel.isDragging ? 1.0 : 0.0
                            )
                            .offset(segmentOffset(index: index, isActive: viewModel.activeSegment == segment))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.activeSegment)
                        }

                        // Sub-options - radial display when hovering
                        if let activeSegment = viewModel.activeSegment, viewModel.isShowingSubOptions {
                            RadialSubOptionsView(
                                segment: activeSegment,
                                activeSubOption: viewModel.activeSubOption,
                                menuRadius: menuRadius
                            )
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Center - minimal orb
                        FloatingCenterView(
                            viewModel: viewModel,
                            onCreateTap: createEpoch
                        )
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    .opacity(appearAnimation ? 1 : 0)
                    .rotationEffect(.degrees(rotationAngle))
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
                // Subtle rotation on appear
                withAnimation(.easeOut(duration: 0.6)) {
                    rotationAngle = 0
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
            Color.black.opacity(isVisible ? 0.6 : 0)

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

            // Main banner card
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                ZStack {
                    // Glow
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [statusColor, statusColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
                                .foregroundStyle(.white)
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
                        .foregroundStyle(.white.opacity(0.7))
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
                            .strokeBorder(
                                LinearGradient(
                                    colors: [statusColor.opacity(0.5), statusColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
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

    private var statusColor: Color {
        if error != nil {
            return Theme.Colors.error
        } else if isComplete {
            return Theme.Colors.liveGreen
        } else {
            return Theme.Colors.primaryFallback
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

// MARK: - Floating Segment View

private struct FloatingSegmentView: View {
    let segment: RadialSegment
    let isActive: Bool
    let isCompleted: Bool
    var isHovered: Bool = false
    var dragProgress: CGFloat = 0

    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Glow effect when active
            if isActive || isHovered {
                Circle()
                    .fill(segment.color.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                    .scaleEffect(glowPulse ? 1.2 : 1.0)
            }

            // Main icon circle
            ZStack {
                // Background - glass effect
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                    .opacity(isActive ? 1 : 0.6)

                // Color overlay when active
                if isActive {
                    Circle()
                        .fill(segment.color.opacity(0.3))
                        .frame(width: 56, height: 56)
                }

                // Icon - larger and bolder
                Image(systemName: segment.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isActive ? segment.color : .white.opacity(0.7))
                    .symbolEffect(.bounce, value: isHovered)

                // Completion checkmark
                if isCompleted && !isActive {
                    Circle()
                        .fill(Theme.Colors.liveGreen)
                        .frame(width: 18, height: 18)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 20, y: -20)
                }

                // Hover ring
                if isHovered {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [segment.color, segment.color.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 62, height: 62)
                }
            }

            // Label - only show when not hovering
            if !isHovered {
                Text(segment.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.5))
                    .offset(y: 40)
            }
        }
        .scaleEffect(isHovered ? 1.3 : (isActive ? 1.15 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isHovered)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
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
            let distance = menuRadius + 60 + CGFloat(index) * 40
            let angleInRadians = segmentCenterAngle * .pi / 180

            SubOptionBubble(
                text: option,
                color: segment.color,
                isActive: isActive,
                index: index
            )
            .offset(
                x: distance * CGFloat(cos(angleInRadians)),
                y: distance * CGFloat(sin(angleInRadians))
            )
            .transition(
                .asymmetric(
                    insertion: .scale(scale: 0.5).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.05)),
                    removal: .scale(scale: 0.8).combined(with: .opacity).animation(.easeOut(duration: 0.15))
                )
            )
        }
    }
}

// MARK: - Sub-Option Bubble

private struct SubOptionBubble: View {
    let text: String
    let color: Color
    let isActive: Bool
    let index: Int

    @State private var appeared = false

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isActive ? .white : .white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isActive {
                    Capsule()
                        .fill(color)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .fill(color.opacity(0.2))
                        }
                }
            }
            .overlay {
                if isActive {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
            .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 10, x: 0, y: 4)
            .scaleEffect(isActive ? 1.2 : (appeared ? 1.0 : 0.5))
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Floating Center View

private struct FloatingCenterView: View {
    let viewModel: RadialMenuViewModel
    let onCreateTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: CGFloat = 0.3

    var body: some View {
        ZStack {
            // Outer glow for completed state
            if viewModel.isComplete {
                Circle()
                    .fill(Theme.Colors.liveGreen.opacity(glowOpacity))
                    .frame(width: 90, height: 90)
                    .blur(radius: 20)
            }

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
                        .frame(width: 64, height: 64)

                    // Gradient overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: viewModel.isComplete
                                    ? [Theme.Colors.liveGreen, Theme.Colors.primaryFallback]
                                    : [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    // Content
                    if viewModel.isComplete {
                        // Create icon with animation
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse, options: .repeating)
                    } else {
                        // Progress indicator
                        VStack(spacing: 2) {
                            // Progress dots
                            HStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { index in
                                    Circle()
                                        .fill(index < viewModel.currentStep
                                              ? Theme.Colors.liveGreen
                                              : Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                            }

                            Text(stepLabel)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }

                    // Outer ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: viewModel.isComplete
                                    ? [Theme.Colors.liveGreen.opacity(0.8), Theme.Colors.liveGreen.opacity(0.3)]
                                    : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 68, height: 68)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .scaleEffect(viewModel.isComplete ? pulseScale : 1.0)
            .disabled(!viewModel.isComplete)
        }
        .onAppear {
            if viewModel.isComplete {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.08
                    glowOpacity = 0.5
                }
            }
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.08
                    glowOpacity = 0.5
                }
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
