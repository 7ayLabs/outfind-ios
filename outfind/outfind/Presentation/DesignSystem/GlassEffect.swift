import SwiftUI

// MARK: - Glass Effect Style

/// Liquid glass blur effect styles for Outfind UI
/// Uses native blur materials with vibrancy - no gray overlays
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
            return .bar
        }
    }

    // Blur radius for custom blur effects
    var blurRadius: CGFloat {
        switch self {
        case .ultraThin: return 8
        case .thin: return 12
        case .regular: return 20
        case .thick: return 30
        case .prominent: return 40
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
                ZStack {
                    // Pure blur background - no gray
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(style.material)

                    // Subtle highlight for depth
                    if showHighlight {
                        glassHighlight
                    }

                    // Thin border for definition
                    if showBorder {
                        glassBorder
                    }
                }
            }
    }

    private var glassHighlight: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.3),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .allowsHitTesting(false)
    }

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2),
                lineWidth: 0.5
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
                // Subtle top highlight only
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .overlay {
                // Very thin border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.15),
                        lineWidth: 0.5
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
