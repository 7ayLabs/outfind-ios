import SwiftUI

// MARK: - App Theme

/// Central theme configuration for Outfind
/// Supports dark/light mode with semantic color tokens
enum Theme {
    // MARK: - Color Palette

    enum Colors {
        // MARK: Primary

        static let primary = Color("Primary", bundle: nil)
        static let primaryVariant = Color("PrimaryVariant", bundle: nil)

        // Fallback colors when assets not available
        static var primaryFallback: Color {
            Color(hex: "178E77")
        }

        static var primaryVariantFallback: Color {
            Color(hex: "14A085")
        }

        // MARK: Semantic Colors

        static var background: Color {
            Color(light: .init(hex: "F2F2F7"), dark: .init(hex: "000000"))
        }

        static var backgroundSecondary: Color {
            Color(light: .init(hex: "FFFFFF"), dark: .init(hex: "1C1C1E"))
        }

        static var backgroundTertiary: Color {
            Color(light: .init(hex: "F2F2F7"), dark: .init(hex: "2C2C2E"))
        }

        static var surface: Color {
            Color(light: .init(hex: "FFFFFF"), dark: .init(hex: "1C1C1E"))
        }

        static var surfaceElevated: Color {
            Color(light: .init(hex: "FFFFFF"), dark: .init(hex: "2C2C2E"))
        }

        // MARK: Text Colors

        static var textPrimary: Color {
            Color(light: .init(hex: "000000"), dark: .init(hex: "FFFFFF"))
        }

        static var textSecondary: Color {
            Color(light: .init(hex: "3C3C43", opacity: 0.6), dark: .init(hex: "EBEBF5", opacity: 0.6))
        }

        static var textTertiary: Color {
            Color(light: .init(hex: "3C3C43", opacity: 0.3), dark: .init(hex: "EBEBF5", opacity: 0.3))
        }

        // MARK: Status Colors

        static var success: Color {
            Color(light: .init(hex: "34C759"), dark: .init(hex: "30D158"))
        }

        static var warning: Color {
            Color(light: .init(hex: "FF9500"), dark: .init(hex: "FF9F0A"))
        }

        static var error: Color {
            Color(light: .init(hex: "FF3B30"), dark: .init(hex: "FF453A"))
        }

        static var info: Color {
            Color(light: .init(hex: "007AFF"), dark: .init(hex: "0A84FF"))
        }

        // MARK: Epoch State Colors

        static var epochScheduled: Color {
            Color(light: .init(hex: "FF9500"), dark: .init(hex: "FF9F0A"))
        }

        static var epochActive: Color {
            Color(light: .init(hex: "34C759"), dark: .init(hex: "30D158"))
        }

        static var epochClosed: Color {
            Color(light: .init(hex: "8E8E93"), dark: .init(hex: "8E8E93"))
        }

        static var epochFinalized: Color {
            Color(light: .init(hex: "AF52DE"), dark: .init(hex: "BF5AF2"))
        }

        // MARK: Glass Effect Colors

        static var glassFill: Color {
            Color(light: .init(hex: "FFFFFF", opacity: 0.7), dark: .init(hex: "1C1C1E", opacity: 0.7))
        }

        static var glassBorder: Color {
            Color(light: .init(hex: "FFFFFF", opacity: 0.5), dark: .init(hex: "FFFFFF", opacity: 0.1))
        }

        static var glassHighlight: Color {
            Color(light: .init(hex: "FFFFFF", opacity: 0.8), dark: .init(hex: "FFFFFF", opacity: 0.15))
        }

        // MARK: Gradient

        static var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color(hex: "178E77"),
                    Color(hex: "14A085")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color(light: .init(hex: "F2F2F7"), dark: .init(hex: "000000")),
                    Color(light: .init(hex: "E5E5EA"), dark: .init(hex: "1C1C1E"))
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadow {
        static let sm = ShadowStyle(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        static let md = ShadowStyle(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let lg = ShadowStyle(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        static let glow = ShadowStyle(color: Colors.primaryFallback.opacity(0.3), radius: 20, x: 0, y: 0)
    }

    // MARK: - Animation (Optimized for 60fps)

    enum Animation {
        // Micro-interactions (buttons, toggles)
        static let micro: SwiftUI.Animation = .easeOut(duration: 0.1)

        // Quick feedback
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.15)

        // Standard transitions
        static let normal: SwiftUI.Animation = .easeInOut(duration: 0.2)

        // Smooth, polished transitions
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.3)

        // Interactive spring (snappy)
        static let spring: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.75)

        // Bouncy spring (playful)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.65)

        // Gentle spring (subtle)
        static let gentle: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.85)

        // Interactive (for gestures)
        static let interactive: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extensions

extension Color {
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - View Extensions

extension View {
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
