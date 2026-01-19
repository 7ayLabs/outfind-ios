import SwiftUI
import Combine

// MARK: - Radial Menu View Model

/// Manages state for the radial epoch creation menu
@Observable
final class RadialMenuViewModel {
    // MARK: - Selection State

    var selectedDuration: EpochDuration = .twoHours
    var selectedCapability: EpochCapability = .presenceWithSignals
    var selectedVisibility: EpochVisibility = .publicEpoch
    var selectedCategory: EpochCategory = .social
    var selectedLocation: RadialLocationOption = .current
    var suggestedTitles: [String] = []

    // MARK: - UI State

    var activeSegment: RadialSegment?
    var activeSubOption: Int?
    var dragPosition: CGPoint = .zero
    var isDragging = false
    var isShowingSubOptions = false
    var currentStep: Int = 0

    // MARK: - Completion State

    var isComplete: Bool {
        currentStep >= 4 // All required selections made
    }

    var completedSelections: [String] {
        var selections: [String] = []
        if currentStep > 0 { selections.append(selectedDuration.displayText) }
        if currentStep > 1 { selections.append(selectedCapability.displayName) }
        if currentStep > 2 { selections.append(selectedVisibility.displayText) }
        if currentStep > 3 { selections.append(selectedCategory.displayText) }
        return selections
    }

    // MARK: - Segment Detection

    func segmentAt(angle: Double) -> RadialSegment? {
        // Normalize angle to 0-360
        let normalizedAngle = angle < 0 ? angle + 360 : angle

        // Each segment is 60 degrees (6 segments)
        for segment in RadialSegment.allCases {
            let segmentStart = segment.startAngle
            let segmentEnd = segment.endAngle

            if segmentStart < segmentEnd {
                if normalizedAngle >= segmentStart && normalizedAngle < segmentEnd {
                    return segment
                }
            } else {
                // Handles wrap-around (e.g., 330-30 degrees)
                if normalizedAngle >= segmentStart || normalizedAngle < segmentEnd {
                    return segment
                }
            }
        }
        return nil
    }

    func subOptionIndex(distance: CGFloat, for segment: RadialSegment) -> Int? {
        guard distance > 80 else { return nil } // Minimum distance for sub-options

        let optionCount = segment.options.count
        let optionSpacing = 30.0 // Distance between sub-options
        let baseDistance = 100.0

        for i in 0..<optionCount {
            let optionDistance = baseDistance + Double(i) * optionSpacing
            if distance >= optionDistance - 15 && distance < optionDistance + 15 {
                return i
            }
        }
        return optionCount - 1 // Default to last option if far out
    }

    // MARK: - Selection Actions

    func selectOption(segment: RadialSegment, optionIndex: Int) {
        switch segment {
        case .duration:
            if optionIndex < EpochDuration.allCases.count {
                selectedDuration = EpochDuration.allCases[optionIndex]
                if currentStep == 0 { currentStep = 1 }
            }
        case .capability:
            let capabilities = EpochCapability.allCases.sorted { $0.rawValue < $1.rawValue }
            if optionIndex < capabilities.count {
                selectedCapability = capabilities[optionIndex]
                if currentStep == 1 { currentStep = 2 }
            }
        case .visibility:
            if optionIndex < EpochVisibility.allCases.count {
                selectedVisibility = EpochVisibility.allCases[optionIndex]
                if currentStep == 2 { currentStep = 3 }
            }
        case .category:
            if optionIndex < EpochCategory.allCases.count {
                selectedCategory = EpochCategory.allCases[optionIndex]
                if currentStep == 3 { currentStep = 4 }
            }
        case .location:
            if optionIndex < RadialLocationOption.allCases.count {
                selectedLocation = RadialLocationOption.allCases[optionIndex]
            }
        case .title:
            generateTitleSuggestions()
        }
    }

    func generateTitleSuggestions() {
        // Generate context-aware title suggestions
        suggestedTitles = [
            "\(selectedCategory.emoji) \(selectedCategory.rawValue.capitalized) Meetup",
            "Quick \(selectedDuration.shortText) Session",
            "\(selectedCategory.emoji) \(selectedVisibility.rawValue.capitalized) Hangout"
        ]
    }

    func reset() {
        selectedDuration = .twoHours
        selectedCapability = .presenceWithSignals
        selectedVisibility = .publicEpoch
        selectedCategory = .social
        selectedLocation = .current
        suggestedTitles = []
        activeSegment = nil
        activeSubOption = nil
        isDragging = false
        isShowingSubOptions = false
        currentStep = 0
    }
}

// MARK: - Radial Segment

enum RadialSegment: String, CaseIterable {
    case duration
    case capability
    case visibility
    case category
    case location
    case title

    var displayName: String {
        switch self {
        case .duration: return "Duration"
        case .capability: return "Type"
        case .visibility: return "Visibility"
        case .category: return "Category"
        case .location: return "Location"
        case .title: return "Title"
        }
    }

    var icon: String {
        switch self {
        case .duration: return "clock.fill"
        case .capability: return "sparkles"
        case .visibility: return "eye.fill"
        case .category: return "tag.fill"
        case .location: return "location.fill"
        case .title: return "textformat"
        }
    }

    var color: Color {
        switch self {
        case .duration: return Color(hex: "FF9500")
        case .capability: return Color(hex: "AF52DE")
        case .visibility: return Color(hex: "007AFF")
        case .category: return Theme.Colors.liveGreen
        case .location: return Color(hex: "FF3B30")
        case .title: return Theme.Colors.deepTeal
        }
    }

    var startAngle: Double {
        // Segments positioned from top (0°), each 60° wide
        // Offset by -30° to center each segment on its icon
        let index = Double(Self.allCases.firstIndex(of: self)!)
        let baseAngle = index * 60 - 30
        return baseAngle < 0 ? baseAngle + 360 : baseAngle
    }

    var endAngle: Double {
        let end = startAngle + 60
        return end >= 360 ? end - 360 : end
    }

    var options: [String] {
        switch self {
        case .duration:
            return EpochDuration.allCases.map { $0.displayText }
        case .capability:
            return EpochCapability.allCases
                .sorted { $0.rawValue < $1.rawValue }
                .map { $0.displayName }
        case .visibility:
            return EpochVisibility.allCases.map { $0.displayText }
        case .category:
            return EpochCategory.allCases.map { $0.displayText }
        case .location:
            return RadialLocationOption.allCases.map { $0.displayText }
        case .title:
            return ["Suggestion 1", "Suggestion 2", "Suggestion 3"]
        }
    }
}

// MARK: - Epoch Duration

enum EpochDuration: String, CaseIterable {
    case thirtyMinutes = "30m"
    case oneHour = "1h"
    case twoHours = "2h"
    case fourHours = "4h"
    case eightHours = "8h"
    case twentyFourHours = "24h"

    var displayText: String { rawValue }

    var shortText: String {
        switch self {
        case .thirtyMinutes: return "30min"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .fourHours: return "4 hours"
        case .eightHours: return "8 hours"
        case .twentyFourHours: return "24 hours"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .thirtyMinutes: return 1800
        case .oneHour: return 3600
        case .twoHours: return 7200
        case .fourHours: return 14400
        case .eightHours: return 28800
        case .twentyFourHours: return 86400
        }
    }
}

// MARK: - Epoch Visibility

enum EpochVisibility: String, CaseIterable {
    case publicEpoch = "public"
    case friends = "friends"
    case privateEpoch = "private"

    var displayText: String {
        switch self {
        case .publicEpoch: return "Public"
        case .friends: return "Friends"
        case .privateEpoch: return "Private"
        }
    }

    var icon: String {
        switch self {
        case .publicEpoch: return "globe"
        case .friends: return "person.2.fill"
        case .privateEpoch: return "lock.fill"
        }
    }
}

// MARK: - Epoch Category

enum EpochCategory: String, CaseIterable {
    case social
    case work
    case event
    case gaming
    case creative

    var displayText: String {
        rawValue.capitalized
    }

    var emoji: String {
        switch self {
        case .social: return "🎉"
        case .work: return "💼"
        case .event: return "🎪"
        case .gaming: return "🎮"
        case .creative: return "🎨"
        }
    }
}

// MARK: - Epoch Location

enum RadialLocationOption: String, CaseIterable {
    case current
    case custom
    case none

    var displayText: String {
        switch self {
        case .current: return "Current"
        case .custom: return "Custom"
        case .none: return "None"
        }
    }

    var icon: String {
        switch self {
        case .current: return "location.fill"
        case .custom: return "mappin"
        case .none: return "location.slash"
        }
    }
}
