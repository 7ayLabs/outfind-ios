import SwiftUI

// MARK: - Glass Effect Style

/// Liquid glass effect styles for Outfind UI
enum GlassStyle {
    case regular
    case thin
    case thick
    case ultraThin
    case prominent

    var material: Material {
        switch self {
        case .regular:
            return .regularMaterial
        case .thin:
            return .thinMaterial
        case .thick:
            return .thickMaterial
        case .ultraThin:
            return .ultraThinMaterial
        case .prominent:
            return .ultraThickMaterial
        }
    }

    var opacity: Double {
        switch self {
        case .regular:
            return 0.8
        case .thin:
            return 0.6
        case .thick:
            return 0.9
        case .ultraThin:
            return 0.4
        case .prominent:
            return 0.95
        }
    }
}

// MARK: - Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    let style: GlassStyle
    let cornerRadius: CGFloat
    let padding: CGFloat
    let showBorder: Bool
    let showHighlight: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(style.material)
                    .overlay {
                        if showHighlight {
                            glassHighlight
                        }
                    }
                    .overlay {
                        if showBorder {
                            glassBorder
                        }
                    }
            }
            .shadow(Theme.Shadow.md)
    }

    private var glassHighlight: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.Colors.glassHighlight,
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .mask {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(lineWidth: cornerRadius)
                    .padding(cornerRadius / 2)
            }
            .allowsHitTesting(false)
    }

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Theme.Colors.glassBorder,
                        Theme.Colors.glassBorder.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Glass Button Modifier

struct GlassButtonModifier: ViewModifier {
    let style: GlassStyle
    let isPressed: Bool

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                Capsule()
                    .fill(style.material)
                    .overlay {
                        Capsule()
                            .strokeBorder(Theme.Colors.glassBorder, lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(Theme.Animation.quick, value: isPressed)
    }
}

// MARK: - Frosted Glass Background

struct FrostedGlassBackground: View {
    let style: GlassStyle
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(style.material)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark
                                    ? Color.white.opacity(0.08)
                                    : Color.white.opacity(0.5),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                colorScheme == .dark
                                    ? Color.white.opacity(0.15)
                                    : Color.white.opacity(0.6),
                                colorScheme == .dark
                                    ? Color.white.opacity(0.05)
                                    : Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - Liquid Glass Orb

struct LiquidGlassOrb: View {
    let size: CGFloat
    let color: Color

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(color.opacity(0.2))
                .blur(radius: size / 4)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // Main orb with glass effect
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.1),
                                    .clear
                                ],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: size
                            )
                        )
                }
                .overlay {
                    // Highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .scaleEffect(0.8)
                        .offset(x: -size * 0.1, y: -size * 0.1)
                }
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass card effect
    func glassCard(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = Theme.CornerRadius.lg,
        padding: CGFloat = Theme.Spacing.md,
        showBorder: Bool = true,
        showHighlight: Bool = true
    ) -> some View {
        modifier(GlassCardModifier(
            style: style,
            cornerRadius: cornerRadius,
            padding: padding,
            showBorder: showBorder,
            showHighlight: showHighlight
        ))
    }

    /// Apply glass button effect
    func glassButton(style: GlassStyle = .thin, isPressed: Bool = false) -> some View {
        modifier(GlassButtonModifier(style: style, isPressed: isPressed))
    }

    /// Apply frosted glass background
    func frostedGlass(style: GlassStyle = .regular, cornerRadius: CGFloat = Theme.CornerRadius.lg) -> some View {
        background {
            FrostedGlassBackground(style: style, cornerRadius: cornerRadius)
        }
    }
}
