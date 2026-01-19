import SwiftUI

// MARK: - Radial Menu View

/// Minimalist radial menu for quick epoch creation
/// Press and drag to select, releases commit selection
/// Sub-options extend outward from each segment following finger direction
struct RadialMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RadialMenuViewModel()

    // Gesture state
    @State private var dragLocation: CGPoint = .zero
    @State private var menuCenter: CGPoint = .zero
    @State private var screenSize: CGSize = .zero
    @State private var hasProcessedInitialDrag = false

    // Preview mode - shows sub-options via tap (no selection)
    @State private var previewSegment: RadialSegment?

    // Animation state
    @State private var appearAnimation = false

    // Posting state
    @State private var isPosting = false
    @State private var postingComplete = false
    @State private var postingError: String?

    // Initial drag from navbar (for continuous gesture)
    var initialDragLocation: CGPoint?

    let onComplete: (EpochCreationData) -> Void
    let onDismiss: () -> Void

    private let menuRadius: CGFloat = 120
    private let subOptionStartDistance: CGFloat = 140
    private let subOptionSpacing: CGFloat = 44
    private let screenPadding: CGFloat = 60

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let size = geometry.size

            ZStack {
                // Blur background - subtle
                BlurBackgroundView(isVisible: appearAnimation)

                // Posting overlay
                if isPosting || postingComplete {
                    PostingBannerView(
                        isPosting: isPosting,
                        isComplete: postingComplete,
                        error: postingError,
                        onDismiss: { dismissMenu() }
                    )
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(100)
                } else {
                    // Main radial menu
                    ZStack {
                        // Segments layer
                        ForEach(Array(RadialSegment.allCases.enumerated()), id: \.element) { index, segment in
                            let isActive = viewModel.activeSegment == segment || previewSegment == segment
                            let isShowingOptions = viewModel.isShowingSubOptions || previewSegment != nil
                            let showingOtherSubOptions = isShowingOptions && !isActive

                            MinimalSegmentView(
                                segment: segment,
                                isActive: isActive,
                                isCompleted: isSegmentCompleted(segment),
                                isHovered: viewModel.isDragging && viewModel.activeSegment == segment && !viewModel.isShowingSubOptions
                            )
                            .offset(segmentOffset(index: index))
                            .opacity(showingOtherSubOptions ? 0.25 : 1.0)
                            .scaleEffect(isActive && isShowingOptions ? 1.15 : 1.0)
                            .zIndex(isActive ? 10 : 1)
                            .onTapGesture {
                                // Tap to preview sub-options (no selection)
                                handleSegmentTap(segment)
                            }
                        }

                        // Sub-options layer - show for both drag mode and tap/preview mode
                        let displaySegment = viewModel.activeSegment ?? previewSegment
                        let showOptions = viewModel.isShowingSubOptions || previewSegment != nil

                        if let activeSegment = displaySegment, showOptions {
                            let segmentIndex = RadialSegment.allCases.firstIndex(of: activeSegment) ?? 0
                            let segmentAngle = Double(segmentIndex) * .pi / 3 - .pi / 2
                            let shouldCenter = shouldCenterSubOptions(
                                segmentIndex: segmentIndex,
                                optionCount: min(activeSegment.options.count, 6),
                                screenSize: size,
                                center: center
                            )
                            // In preview mode, no option is active
                            let activeOption = previewSegment != nil ? nil : viewModel.activeSubOption

                            if shouldCenter {
                                // Centered sub-options when they would go off-screen
                                CenteredSubOptionsView(
                                    segment: activeSegment,
                                    activeSubOption: activeOption,
                                    onOptionTap: { optionIndex in
                                        handleSubOptionTap(segment: activeSegment, optionIndex: optionIndex)
                                    }
                                )
                                .zIndex(25)
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                            } else {
                                // Radial sub-options extending outward
                                ForEach(Array(activeSegment.options.prefix(6).enumerated()), id: \.offset) { optionIndex, option in
                                    let isOptionActive = activeOption == optionIndex
                                    let distance = subOptionStartDistance + CGFloat(optionIndex) * subOptionSpacing

                                    SubOptionPill(
                                        text: option,
                                        isActive: isOptionActive,
                                        index: optionIndex
                                    )
                                    .offset(
                                        x: distance * CGFloat(cos(segmentAngle)),
                                        y: distance * CGFloat(sin(segmentAngle))
                                    )
                                    .zIndex(isOptionActive ? 30 : 20)
                                    .onTapGesture {
                                        handleSubOptionTap(segment: activeSegment, optionIndex: optionIndex)
                                    }
                                }
                            }
                        }

                        // Center orb
                        MinimalCenterView(
                            viewModel: viewModel,
                            onCreateTap: createEpoch
                        )
                        .opacity((viewModel.isShowingSubOptions || previewSegment != nil) ? 0.3 : 1.0)
                        .scaleEffect(viewModel.isShowingSubOptions ? 0.9 : 1.0)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.6)
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
                screenSize = size
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    appearAnimation = true
                }
                RadialHaptics.shared.menuAppear()

                // Only mark as dragging if initial location provided
                // Don't auto-select - wait for actual gesture input
                if initialDragLocation != nil {
                    hasProcessedInitialDrag = true
                    viewModel.isDragging = true
                }
            }
        }
    }

    // MARK: - Check if sub-options would go off-screen

    private func shouldCenterSubOptions(segmentIndex: Int, optionCount: Int, screenSize: CGSize, center: CGPoint) -> Bool {
        let segmentAngle = Double(segmentIndex) * .pi / 3 - .pi / 2
        let maxDistance = subOptionStartDistance + CGFloat(optionCount - 1) * subOptionSpacing + 60

        // Calculate the furthest point the sub-options would reach
        let endX = center.x + maxDistance * CGFloat(cos(segmentAngle))
        let endY = center.y + maxDistance * CGFloat(sin(segmentAngle))

        // Check if it would go off any edge
        let wouldGoOffLeft = endX < screenPadding
        let wouldGoOffRight = endX > screenSize.width - screenPadding
        let wouldGoOffTop = endY < screenPadding
        let wouldGoOffBottom = endY > screenSize.height - screenPadding

        return wouldGoOffLeft || wouldGoOffRight || wouldGoOffTop || wouldGoOffBottom
    }

    // MARK: - Segment Positioning

    private func segmentOffset(index: Int) -> CGSize {
        let angle = Double(index) * .pi / 3 - .pi / 2
        return CGSize(
            width: menuRadius * 0.75 * CGFloat(cos(angle)),
            height: menuRadius * 0.75 * CGFloat(sin(angle))
        )
    }

    // MARK: - Tap Handling (Preview Mode)

    private func handleSegmentTap(_ segment: RadialSegment) {
        // Clear drag state
        viewModel.isDragging = false
        viewModel.activeSegment = nil
        viewModel.activeSubOption = nil
        viewModel.isShowingSubOptions = false

        // Toggle preview for this segment
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if previewSegment == segment {
                previewSegment = nil
            } else {
                previewSegment = segment
            }
        }
        RadialHaptics.shared.segmentChange()
    }

    private func handleSubOptionTap(segment: RadialSegment, optionIndex: Int) {
        // Select the option via tap
        viewModel.selectOption(segment: segment, optionIndex: optionIndex)
        RadialHaptics.shared.selectionMade()

        // Clear preview mode
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            previewSegment = nil
        }

        // Check if all selections complete
        if viewModel.isComplete {
            RadialHaptics.shared.celebrate()
        }
    }

    // MARK: - Gesture Handling

    private func handleDragChanged(_ location: CGPoint, center: CGPoint) {
        // Clear preview mode when dragging starts
        if previewSegment != nil {
            previewSegment = nil
        }

        if !viewModel.isDragging {
            viewModel.isDragging = true
        }

        dragLocation = location

        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)

        // Angle from top (0°) clockwise
        var angle = atan2(dx, -dy) * 180 / .pi
        if angle < 0 { angle += 360 }

        let minDistance: CGFloat = 30
        let segmentThreshold: CGFloat = 55
        let subOptionThreshold: CGFloat = subOptionStartDistance - 20

        if distance <= minDistance {
            // Center zone - clear all
            if viewModel.activeSegment != nil || viewModel.isShowingSubOptions {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.activeSegment = nil
                    viewModel.activeSubOption = nil
                    viewModel.isShowingSubOptions = false
                }
            }
            return
        }

        // Detect which segment based on angle
        if let segment = viewModel.segmentAt(angle: angle) {
            let previousSegment = viewModel.activeSegment

            // Segment changed
            if previousSegment != segment {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.activeSegment = segment
                    viewModel.activeSubOption = nil
                    viewModel.isShowingSubOptions = false
                }
                RadialHaptics.shared.segmentChange()
            }

            // Show sub-options when past threshold
            if distance > subOptionThreshold {
                if !viewModel.isShowingSubOptions {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.isShowingSubOptions = true
                    }
                }

                // Calculate which sub-option based on distance
                let optionCount = min(segment.options.count, 6)
                let distanceIntoOptions = distance - subOptionStartDistance + (subOptionSpacing / 2)
                let optionIndex = max(0, Int(distanceIntoOptions / subOptionSpacing))
                let clampedIndex = min(optionCount - 1, optionIndex)

                if viewModel.activeSubOption != clampedIndex {
                    withAnimation(.easeOut(duration: 0.15)) {
                        viewModel.activeSubOption = clampedIndex
                    }
                    RadialHaptics.shared.optionHover()
                }
            } else if distance > segmentThreshold && distance <= subOptionThreshold {
                // In segment zone but not yet in sub-options
                if viewModel.isShowingSubOptions {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.isShowingSubOptions = false
                        viewModel.activeSubOption = nil
                    }
                }
            }
        }
    }

    private func handleDragEnded() {
        viewModel.isDragging = false

        if let segment = viewModel.activeSegment,
           let optionIndex = viewModel.activeSubOption {
            // Valid selection
            viewModel.selectOption(segment: segment, optionIndex: optionIndex)
            RadialHaptics.shared.selectionMade()

            if viewModel.isComplete {
                RadialHaptics.shared.celebrate()
            }
        } else if viewModel.activeSegment == nil {
            RadialHaptics.shared.dismiss()
            dismissMenu()
            return
        }

        // Reset hover state
        withAnimation(.easeOut(duration: 0.2)) {
            viewModel.activeSegment = nil
            viewModel.activeSubOption = nil
            viewModel.isShowingSubOptions = false
        }
    }

    // MARK: - Helpers

    private func isSegmentCompleted(_ segment: RadialSegment) -> Bool {
        switch segment {
        case .duration: return viewModel.currentStep > 0
        case .capability: return viewModel.currentStep > 1
        case .visibility: return viewModel.currentStep > 2
        case .category: return viewModel.currentStep > 3
        case .location: return true
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

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPosting = true
        }

        Task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    RadialHaptics.shared.celebrate()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isPosting = false
                        postingComplete = true
                    }
                }
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

// MARK: - Glass Bubble Background

private struct BlurBackgroundView: View {
    let isVisible: Bool

    var body: some View {
        ZStack {
            // Clear glass blur - light material for transparency
            if isVisible {
                VisualEffectBlur(blurStyle: .systemThinMaterial)
                    .opacity(0.95)
            }

            // Very subtle dark tint for contrast
            Color.black
                .opacity(isVisible ? 0.1 : 0)

            // Glass shine effect
            if isVisible {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear,
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Posting Banner

private struct PostingBannerView: View {
    let isPosting: Bool
    let isComplete: Bool
    let error: String?
    let onDismiss: () -> Void

    @State private var rotation = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isComplete ? 0.9 : 0.12))
                        .frame(width: 72, height: 72)

                    if isPosting {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(rotation ? 360 : 0))
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

                VStack(spacing: 6) {
                    Text(isComplete ? "Epoch Live!" : (error != nil ? "Oops!" : "Creating..."))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    if isComplete {
                        Text("Your epoch is now live")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                if error != nil {
                    Button { onDismiss() } label: {
                        Text("Try Again")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                }
            }
            .padding(28)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                rotation = true
            }
        }
    }
}

// MARK: - Minimal Segment View

private struct MinimalSegmentView: View {
    let segment: RadialSegment
    let isActive: Bool
    let isCompleted: Bool
    let isHovered: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 50, height: 50)
                .opacity(isActive ? 1 : 0.6)

            if isActive {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 50, height: 50)
            }

            Image(systemName: segment.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.5))

            if isCompleted && !isActive {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 14, height: 14)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    .offset(x: 16, y: -16)
            }

            if isHovered {
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 56, height: 56)
            }

            Text(segment.displayName)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isActive ? .white.opacity(0.8) : .white.opacity(0.4))
                .offset(y: 36)
        }
        .scaleEffect(isHovered ? 1.15 : (isActive ? 1.05 : 1.0))
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isActive)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Centered Sub-Options View (when radial would go off-screen)

private struct CenteredSubOptionsView: View {
    let segment: RadialSegment
    let activeSubOption: Int?
    var onOptionTap: ((Int) -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            // Segment title
            Text(segment.displayName.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.5)

            // Options list
            VStack(spacing: 4) {
                ForEach(Array(segment.options.prefix(6).enumerated()), id: \.offset) { index, option in
                    CenteredOptionRow(
                        text: option,
                        isActive: activeSubOption == index,
                        index: index
                    )
                    .onTapGesture {
                        onOptionTap?(index)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Centered Option Row

private struct CenteredOptionRow: View {
    let text: String
    let isActive: Bool
    let index: Int

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.white : Color.white.opacity(0.2))
                .frame(width: 5, height: 5)

            Text(text)
                .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .white : .white.opacity(0.6))

            Spacer()

            if isActive {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.12))
            }
        }
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.2, dampingFraction: 0.75), value: isActive)
        .onAppear {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7).delay(Double(index) * 0.025)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Sub-Option Pill

private struct SubOptionPill: View {
    let text: String
    let isActive: Bool
    let index: Int

    @State private var appeared = false

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: isActive ? .semibold : .regular))
            .foregroundStyle(isActive ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(isActive ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
            }
            .overlay {
                if isActive {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                }
            }
            .scaleEffect(isActive ? 1.1 : (appeared ? 1.0 : 0.7))
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isActive)
            .onAppear {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7).delay(Double(index) * 0.04)) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}

// MARK: - Minimal Center View

private struct MinimalCenterView: View {
    let viewModel: RadialMenuViewModel
    let onCreateTap: () -> Void

    @State private var pulse: CGFloat = 1.0

    var body: some View {
        Button(action: {
            if viewModel.isComplete { onCreateTap() }
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)

                if viewModel.isComplete {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 56, height: 56)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)
                } else {
                    Text("\(viewModel.currentStep)/4")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Circle()
                    .strokeBorder(Color.white.opacity(viewModel.isComplete ? 0.6 : 0.15), lineWidth: 2)
                    .frame(width: 60, height: 60)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(viewModel.isComplete ? pulse : 1.0)
        .disabled(!viewModel.isComplete)
        .onChange(of: viewModel.isComplete) { _, done in
            if done {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = 1.06
                }
            }
        }
    }
}

// MARK: - Data

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
        Theme.Colors.background.ignoresSafeArea()
        RadialMenuView(initialDragLocation: nil, onComplete: { _ in }, onDismiss: {})
    }
}
