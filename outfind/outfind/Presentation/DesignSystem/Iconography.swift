import SwiftUI

// MARK: - App Icons

/// Minimalist SF Symbol iconography for Outfind
/// Clean, lightweight icons with consistent design language
enum AppIcon: String {
    // MARK: - Navigation (Thin, clean lines)

    case back = "chevron.left"
    case forward = "chevron.right"
    case close = "xmark"
    case menu = "line.3.horizontal"
    case more = "ellipsis"
    case search = "magnifyingglass"

    // MARK: - Wallet & Auth (Simple outlines)

    case wallet = "creditcard"
    case walletConnect = "link"
    case qrCode = "qrcode"
    case key = "key"
    case fingerprint = "touchid"
    case faceId = "faceid"

    // MARK: - Epoch (Clean icons)

    case epoch = "clock"
    case epochActive = "clock.fill"
    case epochScheduled = "clock.badge"
    case epochClosed = "clock.badge.xmark"
    case epochFinalized = "checkmark.seal"
    case timer = "timer"
    case hourglass = "hourglass"

    // MARK: - Presence (Clean person icons)

    case presence = "person"
    case presenceDeclared = "person.badge.clock"
    case presenceValidated = "person.badge.checkmark"
    case presenceSlashed = "person.slash"
    case participants = "person.2"
    case participantsCircle = "person.2.circle"

    // MARK: - Location & Discovery (Minimal)

    case location = "location"
    case locationFill = "location.fill"
    case locationCircle = "location.circle"
    case map = "map"
    case mapPin = "mappin"
    case mapPinCircle = "mappin.circle"
    case radar = "wifi"
    case nearby = "antenna.radiowaves.left.and.right"

    // MARK: - Status (Simple shapes)

    case checkmark = "checkmark"
    case checkmarkCircle = "checkmark.circle"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case warning = "exclamationmark.triangle"
    case error = "xmark.circle"
    case info = "info.circle"
    case question = "questionmark.circle"

    // MARK: - Actions (Clean strokes)

    case add = "plus"
    case addCircle = "plus.circle"
    case remove = "minus"
    case share = "square.and.arrow.up"
    case copy = "doc.on.doc"
    case refresh = "arrow.clockwise"
    case settings = "gearshape"

    // MARK: - Capability Icons (Minimal)

    case presenceOnly = "person.fill"
    case signals = "bubble.left.and.bubble.right"
    case media = "photo"
    case camera = "camera"
    case microphone = "mic"

    // MARK: - Misc (Clean)

    case shield = "shield"
    case shieldCheck = "shield.checkered"
    case lock = "lock"
    case unlock = "lock.open"
    case globe = "globe"
    case chain = "link.circle"
    case sparkle = "sparkle"
    case bolt = "bolt"
    case star = "star"
    case heart = "heart"

    // MARK: - Social Auth

    case google = "globe.americas"
    case apple = "apple.logo"

    // MARK: - View

    var image: Image {
        Image(systemName: rawValue)
    }

    func image(size: IconSize = .md) -> some View {
        Image(systemName: rawValue)
            .font(.system(size: size.pointSize, weight: size.weight))
    }
}

// MARK: - Icon Size

enum IconSize {
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl

    var pointSize: CGFloat {
        switch self {
        case .xs: return 11
        case .sm: return 14
        case .md: return 18
        case .lg: return 22
        case .xl: return 28
        case .xxl: return 40
        }
    }

    // Lighter weights for minimalist look
    var weight: Font.Weight {
        switch self {
        case .xs: return .light
        case .sm: return .light
        case .md: return .regular
        case .lg: return .regular
        case .xl: return .medium
        case .xxl: return .medium
        }
    }
}

// MARK: - Icon View

struct IconView: View {
    let icon: AppIcon
    let size: IconSize
    let color: Color

    init(_ icon: AppIcon, size: IconSize = .md, color: Color = Theme.Colors.textPrimary) {
        self.icon = icon
        self.size = size
        self.color = color
    }

    var body: some View {
        icon.image(size: size)
            .foregroundStyle(color)
    }
}

// MARK: - Animated Icon

struct AnimatedIcon: View {
    let icon: AppIcon
    let size: IconSize
    let color: Color
    let isAnimating: Bool

    init(_ icon: AppIcon, size: IconSize = .md, color: Color = Theme.Colors.textPrimary, isAnimating: Bool = false) {
        self.icon = icon
        self.size = size
        self.color = color
        self.isAnimating = isAnimating
    }

    var body: some View {
        IconView(icon, size: size, color: color)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .animation(
                isAnimating
                    ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                    : .default,
                value: isAnimating
            )
    }
}

// MARK: - Status Icon

struct StatusIcon: View {
    enum Status {
        case success
        case warning
        case error
        case info
        case loading

        var icon: AppIcon {
            switch self {
            case .success: return .checkmarkCircleFill
            case .warning: return .warning
            case .error: return .error
            case .info: return .info
            case .loading: return .hourglass
            }
        }

        var color: Color {
            switch self {
            case .success: return Theme.Colors.success
            case .warning: return Theme.Colors.warning
            case .error: return Theme.Colors.error
            case .info: return Theme.Colors.info
            case .loading: return Theme.Colors.textSecondary
            }
        }
    }

    let status: Status
    let size: IconSize

    init(_ status: Status, size: IconSize = .md) {
        self.status = status
        self.size = size
    }

    var body: some View {
        IconView(status.icon, size: size, color: status.color)
    }
}

// MARK: - Epoch State Icon

struct EpochStateIcon: View {
    let state: EpochState
    let size: IconSize

    init(_ state: EpochState, size: IconSize = .md) {
        self.state = state
        self.size = size
    }

    var body: some View {
        IconView(icon, size: size, color: color)
    }

    private var icon: AppIcon {
        switch state {
        case .none: return .epoch
        case .scheduled: return .epochScheduled
        case .active: return .epochActive
        case .closed: return .epochClosed
        case .finalized: return .epochFinalized
        }
    }

    private var color: Color {
        switch state {
        case .none: return Theme.Colors.textTertiary
        case .scheduled: return Theme.Colors.epochScheduled
        case .active: return Theme.Colors.epochActive
        case .closed: return Theme.Colors.epochClosed
        case .finalized: return Theme.Colors.epochFinalized
        }
    }
}

// MARK: - Presence State Icon

struct PresenceStateIcon: View {
    let state: PresenceState
    let size: IconSize

    init(_ state: PresenceState, size: IconSize = .md) {
        self.state = state
        self.size = size
    }

    var body: some View {
        IconView(icon, size: size, color: color)
    }

    private var icon: AppIcon {
        switch state {
        case .none: return .presence
        case .declared: return .presenceDeclared
        case .validated: return .presenceValidated
        case .finalized: return .presenceValidated
        case .slashed: return .presenceSlashed
        }
    }

    private var color: Color {
        switch state {
        case .none: return Theme.Colors.textTertiary
        case .declared: return Theme.Colors.warning
        case .validated: return Theme.Colors.success
        case .finalized: return Theme.Colors.epochFinalized
        case .slashed: return Theme.Colors.error
        }
    }
}
