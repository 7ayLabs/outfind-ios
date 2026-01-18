import SwiftUI

// MARK: - App Icons

/// Centralized SF Symbol iconography for Outfind
/// Minimalist icon system with consistent sizing
enum AppIcon: String {
    // MARK: - Navigation

    case back = "chevron.left"
    case forward = "chevron.right"
    case close = "xmark"
    case menu = "line.3.horizontal"
    case more = "ellipsis"
    case search = "magnifyingglass"

    // MARK: - Wallet & Auth

    case wallet = "wallet.pass"
    case walletConnect = "link.circle"
    case qrCode = "qrcode"
    case key = "key"
    case fingerprint = "touchid"
    case faceId = "faceid"

    // MARK: - Epoch

    case epoch = "clock.circle"
    case epochActive = "clock.badge.checkmark"
    case epochScheduled = "clock.badge"
    case epochClosed = "clock.badge.xmark"
    case epochFinalized = "checkmark.seal"
    case timer = "timer"
    case hourglass = "hourglass"

    // MARK: - Presence

    case presence = "person.crop.circle"
    case presenceDeclared = "person.crop.circle.badge"
    case presenceValidated = "person.crop.circle.badge.checkmark"
    case presenceSlashed = "person.crop.circle.badge.xmark"
    case participants = "person.2"
    case participantsCircle = "person.2.circle"

    // MARK: - Location & Discovery

    case location = "location"
    case locationFill = "location.fill"
    case locationCircle = "location.circle"
    case map = "map"
    case mapPin = "mappin"
    case mapPinCircle = "mappin.circle"
    case radar = "scope"
    case nearby = "antenna.radiowaves.left.and.right"

    // MARK: - Status

    case checkmark = "checkmark"
    case checkmarkCircle = "checkmark.circle"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case warning = "exclamationmark.triangle"
    case error = "xmark.circle"
    case info = "info.circle"
    case question = "questionmark.circle"

    // MARK: - Actions

    case add = "plus"
    case addCircle = "plus.circle"
    case remove = "minus"
    case share = "square.and.arrow.up"
    case copy = "doc.on.doc"
    case refresh = "arrow.clockwise"
    case settings = "gearshape"

    // MARK: - Capability Icons

    case presenceOnly = "person.badge.clock"
    case signals = "bubble.left.and.bubble.right"
    case media = "photo.on.rectangle"
    case camera = "camera"
    case microphone = "mic"

    // MARK: - Misc

    case shield = "shield"
    case shieldCheck = "shield.checkered"
    case lock = "lock"
    case unlock = "lock.open"
    case globe = "globe"
    case chain = "link"
    case sparkle = "sparkle"
    case bolt = "bolt"
    case star = "star"
    case heart = "heart"

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
        case .xs: return 12
        case .sm: return 16
        case .md: return 20
        case .lg: return 24
        case .xl: return 32
        case .xxl: return 48
        }
    }

    var weight: Font.Weight {
        switch self {
        case .xs, .sm: return .regular
        case .md, .lg: return .medium
        case .xl, .xxl: return .semibold
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
