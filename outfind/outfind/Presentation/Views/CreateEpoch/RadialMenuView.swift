import SwiftUI

// MARK: - Radial Menu View

/// Minimalist radial menu for quick epoch creation
/// Tap to select, fast animations
struct RadialMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RadialMenuViewModel()

    // Gesture state
    @State private var dragAngle: Double = 0
    @State private var dragDistance: CGFloat = 0
    @GestureState private var isDragging = false

    // Animation state
    @State private var appearAnimation = false

    let onComplete: (EpochCreationData) -> Void
    let onDismiss: () -> Void

    private let menuRadius: CGFloat = 120
    private let segmentCount = 6

    var body: some View {
        ZStack {
            // Dimmed background - faster fade
            Color.black.opacity(appearAnimation ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMenu()
                }

            // Main radial menu - cleaner design
            ZStack {
                // Simple dark background
                Circle()
                    .fill(Color(hex: "1A1A1A").opacity(0.95))
                    .frame(width: menuRadius * 2 + 20, height: menuRadius * 2 + 20)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                Theme.Colors.liveGreen.opacity(0.3),
                                lineWidth: 1
                            )
                    }

                // Segments - simplified
                ForEach(Array(RadialSegment.allCases.enumerated()), id: \.element) { index, segment in
                    MinimalSegmentView(
                        segment: segment,
                        isActive: viewModel.activeSegment == segment,
                        isCompleted: isSegmentCompleted(segment)
                    )
                    .offset(x: menuRadius * 0.65 * CGFloat(cos(Double(index) * .pi / 3 - .pi / 2)),
                            y: menuRadius * 0.65 * CGFloat(sin(Double(index) * .pi / 3 - .pi / 2)))
                    .onTapGesture {
                        selectSegment(segment)
                    }
                }

                // Sub-options - inline display
                if let activeSegment = viewModel.activeSegment, viewModel.isShowingSubOptions {
                    QuickOptionsView(
                        segment: activeSegment,
                        onSelect: { index in
                            viewModel.selectOption(segment: activeSegment, optionIndex: index)
                            RadialHaptics.shared.selectionMade()
                            viewModel.isShowingSubOptions = false
                        }
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
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                appearAnimation = true
            }
            RadialHaptics.shared.menuAppear()
        }
    }

    // MARK: - Segment Selection

    private func selectSegment(_ segment: RadialSegment) {
        withAnimation(.easeOut(duration: 0.15)) {
            viewModel.activeSegment = segment
            viewModel.isShowingSubOptions = true
        }
        RadialHaptics.shared.segmentChange()
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

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? segment.color.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 40, height: 40)

                Image(systemName: segment.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? segment.color : .white.opacity(0.6))

                if isCompleted {
                    Circle()
                        .strokeBorder(Theme.Colors.liveGreen, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
            }

            Text(segment.displayName)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.5))
        }
        .scaleEffect(isActive ? 1.1 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Quick Options View

private struct QuickOptionsView: View {
    let segment: RadialSegment
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(segment.options.prefix(4).enumerated()), id: \.offset) { index, option in
                Button {
                    onSelect(index)
                } label: {
                    Text(option)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            Capsule()
                                .fill(segment.color.opacity(0.3))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "252525"))
        }
        .transition(.scale.combined(with: .opacity))
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
