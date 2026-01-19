import UIKit

// MARK: - Radial Haptics

/// Haptic feedback manager for the radial menu
/// Provides distinct feedback patterns for different interactions
final class RadialHaptics {
    static let shared = RadialHaptics()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    // MARK: - Prepare Generators

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()
    }

    // MARK: - Menu Interactions

    /// Menu appears on screen
    func menuAppear() {
        impactMedium.impactOccurred()
    }

    /// Menu dismisses
    func dismiss() {
        impactLight.impactOccurred()
    }

    /// User drags to a different segment
    func segmentChange() {
        selection.selectionChanged()
    }

    /// User hovers over a sub-option
    func optionHover() {
        impactLight.impactOccurred(intensity: 0.5)
    }

    /// User selects an option (releases on sub-option)
    func selectionMade() {
        impactMedium.impactOccurred()
    }

    /// Epoch creation successful
    func success() {
        notification.notificationOccurred(.success)
    }

    /// Error or invalid action
    func error() {
        notification.notificationOccurred(.error)
    }

    /// Warning feedback
    func warning() {
        notification.notificationOccurred(.warning)
    }

    // MARK: - Advanced Patterns

    /// Tick pattern for progress (e.g., completing each step)
    func progressTick() {
        impactLight.impactOccurred(intensity: 0.7)
    }

    /// Double tap feeling
    func doubleTap() {
        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactLight.impactOccurred()
        }
    }

    /// Ramp up intensity (for long press activation)
    func rampUp(duration: TimeInterval = 0.3) {
        let steps = 5
        let interval = duration / Double(steps)

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) { [weak self] in
                let intensity = 0.3 + (0.7 * Double(i) / Double(steps - 1))
                self?.impactLight.impactOccurred(intensity: intensity)
            }
        }
    }

    /// Completion celebration pattern
    func celebrate() {
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.impactLight.impactOccurred()
        }
    }
}

// MARK: - Haptic Style

enum HapticStyle {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error

    func trigger() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - View Extension

import SwiftUI

extension View {
    /// Adds haptic feedback on tap
    func hapticFeedback(_ style: HapticStyle) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    style.trigger()
                }
        )
    }
}
