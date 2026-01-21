import SwiftUI

// MARK: - Section Header

/// Reusable section header with title, optional dismiss button, and optional trailing action.
/// Used throughout the home feed for consistent section styling.
struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var showDismiss: Bool = false
    var trailingIcon: AppIcon?
    var trailingText: String?
    var onDismiss: (() -> Void)?
    var onTrailingAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                // Trailing action (See all, Filter, etc.)
                if let trailingText = trailingText {
                    Button {
                        onTrailingAction?()
                    } label: {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Text(trailingText)
                                .font(.system(size: 14, weight: .semibold))

                            if let icon = trailingIcon {
                                IconView(icon, size: .sm, color: Theme.Colors.primaryFallback)
                            }
                        }
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    }
                } else if let icon = trailingIcon {
                    Button {
                        onTrailingAction?()
                    } label: {
                        IconView(icon, size: .md, color: Theme.Colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background {
                                Circle()
                                    .fill(Theme.Colors.backgroundTertiary)
                            }
                    }
                }

                // Dismiss button
                if showDismiss {
                    Button {
                        withAnimation(Theme.Animation.smooth) {
                            onDismiss?()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .frame(width: 28, height: 28)
                            .background {
                                Circle()
                                    .fill(Theme.Colors.backgroundTertiary)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Convenience Initializers

extension SectionHeader {
    /// Section header with title only
    init(_ title: String) {
        self.title = title
        self.subtitle = nil
        self.showDismiss = false
        self.trailingIcon = nil
        self.trailingText = nil
        self.onDismiss = nil
        self.onTrailingAction = nil
    }

    /// Section header with title and subtitle
    init(_ title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        self.showDismiss = false
        self.trailingIcon = nil
        self.trailingText = nil
        self.onDismiss = nil
        self.onTrailingAction = nil
    }

    /// Section header with dismiss button
    static func dismissable(
        _ title: String,
        subtitle: String? = nil,
        onDismiss: @escaping () -> Void
    ) -> SectionHeader {
        SectionHeader(
            title: title,
            subtitle: subtitle,
            showDismiss: true,
            onDismiss: onDismiss
        )
    }

    /// Section header with "See all" action
    static func withSeeAll(
        _ title: String,
        subtitle: String? = nil,
        onSeeAll: @escaping () -> Void
    ) -> SectionHeader {
        SectionHeader(
            title: title,
            subtitle: subtitle,
            showDismiss: false,
            trailingText: "See all",
            onTrailingAction: onSeeAll
        )
    }

    /// Section header with filter icon
    static func withFilter(
        _ title: String,
        subtitle: String? = nil,
        onFilter: @escaping () -> Void
    ) -> SectionHeader {
        SectionHeader(
            title: title,
            subtitle: subtitle,
            showDismiss: false,
            trailingIcon: .filter,
            onTrailingAction: onFilter
        )
    }
}

// MARK: - Preview

#Preview("Basic") {
    VStack(spacing: Theme.Spacing.lg) {
        SectionHeader("Local Epochs")

        SectionHeader("Happening Now", subtitle: "Join live epochs nearby")

        SectionHeader.dismissable("Local Epochs") {
            print("Dismissed")
        }

        SectionHeader.withSeeAll("Upcoming Events") {
            print("See all")
        }

        SectionHeader.withFilter("All epochs near you") {
            print("Filter")
        }
    }
    .padding(.vertical)
    .background(Theme.Colors.background)
}
