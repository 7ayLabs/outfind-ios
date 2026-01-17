import SwiftUI

// MARK: - Glass Text Field

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: AppIcon?
    let isSecure: Bool
    let keyboardType: UIKeyboardType

    @FocusState private var isFocused: Bool

    init(
        _ placeholder: String,
        text: Binding<String>,
        icon: AppIcon? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let icon = icon {
                IconView(icon, size: .md, color: isFocused ? Theme.Colors.primaryFallback : Theme.Colors.textTertiary)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Typography.bodyLarge)
            .foregroundStyle(Theme.Colors.textPrimary)
            .keyboardType(keyboardType)
            .focused($isFocused)

            if !text.isEmpty {
                IconButton(.close, size: .sm, color: Theme.Colors.textTertiary) {
                    text = ""
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 56)
        .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.md)
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .strokeBorder(
                    isFocused ? Theme.Colors.primaryFallback : .clear,
                    lineWidth: 2
                )
        }
        .animation(Theme.Animation.quick, value: isFocused)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            IconView(.search, size: .md, color: Theme.Colors.textTertiary)

            TextField(placeholder, text: $text)
                .font(Typography.bodyLarge)
                .foregroundStyle(Theme.Colors.textPrimary)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }

            if !text.isEmpty {
                IconButton(.close, size: .sm, color: Theme.Colors.textTertiary) {
                    text = ""
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 48)
        .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.full)
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    let icon: AppIcon?
    @Binding var isOn: Bool

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: AppIcon? = nil,
        isOn: Binding<Bool>
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._isOn = isOn
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            if let icon = icon {
                IconView(icon, size: .lg, color: Theme.Colors.primaryFallback)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.Colors.primaryFallback)
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
    }
}

// MARK: - Selection Row

struct SelectionRow: View {
    let title: String
    let subtitle: String?
    let icon: AppIcon?
    let isSelected: Bool
    let action: () -> Void

    init(
        _ title: String,
        subtitle: String? = nil,
        icon: AppIcon? = nil,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                if let icon = icon {
                    IconView(icon, size: .lg, color: isSelected ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(title)
                        .font(Typography.titleSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    IconView(.checkmarkCircleFill, size: .lg, color: Theme.Colors.primaryFallback)
                } else {
                    Circle()
                        .strokeBorder(Theme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stepper Row

struct StepperRow: View {
    let title: String
    let subtitle: String?
    @Binding var value: Int
    let range: ClosedRange<Int>

    init(
        _ title: String,
        subtitle: String? = nil,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) {
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.range = range
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                IconButton(.remove, size: .sm, color: value > range.lowerBound ? Theme.Colors.textPrimary : Theme.Colors.textTertiary) {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(Typography.titleMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(minWidth: 40)

                IconButton(.add, size: .sm, color: value < range.upperBound ? Theme.Colors.textPrimary : Theme.Colors.textTertiary) {
                    if value < range.upperBound {
                        value += 1
                    }
                }
                .disabled(value >= range.upperBound)
            }
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxs)
            .background {
                Capsule()
                    .fill(Theme.Colors.backgroundTertiary)
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
    }
}

// MARK: - Previews

#Preview("Inputs") {
    VStack(spacing: Theme.Spacing.lg) {
        GlassTextField("Enter address", text: .constant(""), icon: .wallet)

        GlassTextField("Password", text: .constant(""), icon: .lock, isSecure: true)

        SearchBar(text: .constant(""))

        ToggleRow("Notifications", subtitle: "Receive epoch updates", icon: .info, isOn: .constant(true))

        SelectionRow("Option 1", subtitle: "Description", icon: .checkmark, isSelected: true) {}

        StepperRow("Quantity", subtitle: "Select amount", value: .constant(5), range: 1...10)
    }
    .padding()
    .background(Theme.Colors.background)
}
