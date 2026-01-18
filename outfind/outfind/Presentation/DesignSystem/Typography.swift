import SwiftUI

// MARK: - Typography

/// Typography system for Outfind
/// Uses SF Pro with semantic text styles
enum Typography {
    // MARK: - Display

    static let displayLarge = Font.system(size: 56, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 44, weight: .bold, design: .rounded)
    static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)

    // MARK: - Headline

    static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .default)
    static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .default)

    // MARK: - Title

    static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .default)

    // MARK: - Body

    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Label

    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Caption

    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMono = Font.system(size: 12, weight: .regular, design: .monospaced)

    // MARK: - Special

    static let timer = Font.system(size: 48, weight: .light, design: .monospaced)
    static let timerSmall = Font.system(size: 24, weight: .medium, design: .monospaced)
    static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
}

// MARK: - Text Style Modifier

struct TextStyleModifier: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat

    init(font: Font, color: Color = Theme.Colors.textPrimary, lineSpacing: CGFloat = 0) {
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
            .lineSpacing(lineSpacing)
    }
}

// MARK: - View Extensions

extension View {
    func textStyle(_ font: Font, color: Color = Theme.Colors.textPrimary) -> some View {
        modifier(TextStyleModifier(font: font, color: color))
    }

    // Convenience methods
    func displayLarge(_ color: Color = Theme.Colors.textPrimary) -> some View {
        textStyle(Typography.displayLarge, color: color)
    }

    func headlineLarge(_ color: Color = Theme.Colors.textPrimary) -> some View {
        textStyle(Typography.headlineLarge, color: color)
    }

    func headlineMedium(_ color: Color = Theme.Colors.textPrimary) -> some View {
        textStyle(Typography.headlineMedium, color: color)
    }

    func titleLarge(_ color: Color = Theme.Colors.textPrimary) -> some View {
        textStyle(Typography.titleLarge, color: color)
    }

    func titleMedium(_ color: Color = Theme.Colors.textPrimary) -> some View {
        textStyle(Typography.titleMedium, color: color)
    }

    func bodyLarge(_ color: Color = Theme.Colors.textPrimary) -> some View {
        textStyle(Typography.bodyLarge, color: color)
    }

    func bodyMedium(_ color: Color = Theme.Colors.textSecondary) -> some View {
        textStyle(Typography.bodyMedium, color: color)
    }

    func labelMedium(_ color: Color = Theme.Colors.textSecondary) -> some View {
        textStyle(Typography.labelMedium, color: color)
    }

    func caption(_ color: Color = Theme.Colors.textTertiary) -> some View {
        textStyle(Typography.caption, color: color)
    }
}

// MARK: - Text Extensions

extension Text {
    func style(_ font: Font, color: Color = Theme.Colors.textPrimary) -> Text {
        self.font(font).foregroundColor(color)
    }
}
