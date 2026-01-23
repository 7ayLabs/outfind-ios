import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: AppIcon?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: AppIcon? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    IconView(icon, size: .md, color: .white)
                }

                Text(title)
                    .font(Typography.titleMedium)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                Capsule()
                    .fill(Theme.Colors.primaryGradient)
                    .opacity(isDisabled ? 0.5 : 1.0)
            }
            .shadow(Theme.Shadow.md)
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: AppIcon?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: AppIcon? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    IconView(icon, size: .md, color: Theme.Colors.primaryFallback)
                }

                Text(title)
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .glassButton(style: .thin, isPressed: isPressed)
            .overlay {
                Capsule()
                    .strokeBorder(Theme.Colors.primaryFallback.opacity(0.3), lineWidth: 1.5)
            }
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Glass Button

struct GlassActionButton: View {
    let title: String
    let icon: AppIcon?
    let style: GlassStyle
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: AppIcon? = nil,
        style: GlassStyle = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                if let icon = icon {
                    IconView(icon, size: .md, color: Theme.Colors.textPrimary)
                }

                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .glassButton(style: style, isPressed: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: AppIcon
    let size: IconSize
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ icon: AppIcon,
        size: IconSize = .md,
        color: Color = Theme.Colors.textPrimary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            IconView(icon, size: size, color: color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: AppIcon
    let action: () -> Void

    @State private var isPressed = false

    init(_ icon: AppIcon, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            IconView(icon, size: .lg, color: .white)
                .frame(width: 56, height: 56)
                .background {
                    Circle()
                        .fill(Theme.Colors.primaryGradient)
                }
                .shadow(Theme.Shadow.lg)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(Theme.Animation.spring, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Back Button

struct BackButton: View {
    let action: () -> Void

    @State private var isPressed = false

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                IconView(.back, size: .md, color: Theme.Colors.primaryFallback)
                Text("Back")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.Animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Swipe Back Modifier

struct SwipeBackModifier: ViewModifier {
    let action: () -> Void

    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .updating($dragOffset) { value, state, _ in
                        if value.startLocation.x < 50 && value.translation.width > 0 {
                            state = value.translation.width
                        }
                    }
                    .onChanged { value in
                        if value.startLocation.x < 50 && value.translation.width > 0 {
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        if value.startLocation.x < 50 &&
                           value.translation.width > 100 &&
                           value.predictedEndTranslation.width > 150 {
                            action()
                        }
                        isDragging = false
                    }
            )
            .offset(x: isDragging ? min(dragOffset * 0.3, 50) : 0)
            .animation(Theme.Animation.quick, value: isDragging)
    }
}

extension View {
    func swipeBack(action: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(action: action))
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let icon: AppIcon?
    let isSelected: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: AppIcon? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xxs) {
                if let icon = icon {
                    IconView(icon, size: .sm, color: isSelected ? .white : Theme.Colors.textSecondary)
                }

                Text(title)
                    .font(Typography.labelMedium)
                    .foregroundStyle(isSelected ? .white : Theme.Colors.textSecondary)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                Capsule()
                    .fill(isSelected ? Theme.Colors.primaryFallback : Theme.Colors.backgroundTertiary)
            }
        }
        .animation(Theme.Animation.quick, value: isSelected)
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: Theme.Spacing.lg) {
        PrimaryButton("Connect Wallet", icon: .wallet) {}

        SecondaryButton("Learn More", icon: .info) {}

        GlassActionButton("Glass Action", icon: .sparkle) {}

        HStack {
            IconButton(.settings) {}
            IconButton(.share) {}
            IconButton(.refresh) {}
        }

        FloatingActionButton(.add) {}

        HStack {
            ChipButton("All", isSelected: true) {}
            ChipButton("Active", icon: .epochActive) {}
            ChipButton("Nearby", icon: .locationFill) {}
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
