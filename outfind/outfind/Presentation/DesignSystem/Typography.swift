import SwiftUI

// MARK: - Typography

/// Typography system for Outfind
/// Uses Apple Dynamic Type text styles for accessibility and HIG compliance
/// All styles support Dynamic Type scaling automatically
enum Typography {
    // MARK: - Display / Large Title (~34 pt)

    /// App title, splash screens - uses largeTitle with semibold weight
    static let displayLarge: Font = .largeTitle.weight(.bold)
    static let displayMedium: Font = .largeTitle.weight(.semibold)
    static let displaySmall: Font = .largeTitle

    // MARK: - Headline / Title (~28 pt, ~22 pt, ~20 pt)

    /// Main screen titles - uses title with appropriate weights
    static let headlineLarge: Font = .title.weight(.bold)
    static let headlineMedium: Font = .title2.weight(.semibold)
    static let headlineSmall: Font = .title3.weight(.semibold)

    // MARK: - Title / Section Headers (~20 pt, ~17 pt)

    /// Section titles, card headers
    static let titleLarge: Font = .title3.weight(.semibold)
    static let titleMedium: Font = .headline
    static let titleSmall: Font = .subheadline.weight(.semibold)

    // MARK: - Body (~17 pt, ~15 pt, ~13 pt)

    /// Main body text, descriptions
    static let bodyLarge: Font = .body
    static let bodyMedium: Font = .callout
    static let bodySmall: Font = .footnote

    // MARK: - Label (~14 pt, ~12 pt, ~11 pt)

    /// Labels, tags, metadata
    static let labelLarge: Font = .subheadline.weight(.medium)
    static let labelMedium: Font = .footnote.weight(.medium)
    static let labelSmall: Font = .caption.weight(.medium)

    // MARK: - Caption (~12 pt)

    /// Captions, legal text, timestamps
    static let caption: Font = .caption
    static let captionMono: Font = .caption.monospaced()

    // MARK: - Special

    /// Timer displays - monospaced for fixed-width digits
    static let timer: Font = .system(.largeTitle, design: .monospaced).weight(.light)
    static let timerSmall: Font = .system(.title2, design: .monospaced).weight(.medium)
    static let code: Font = .system(.footnote, design: .monospaced)
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
