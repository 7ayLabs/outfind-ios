import SwiftUI

// MARK: - Onboarding View

/// Netflix-style swipeable onboarding carousel with feature pages
struct OnboardingView: View {
    @Environment(\.coordinator) private var coordinator

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: .shield,
            title: "Privacy First",
            description: "Your data vanishes when epochs end. No traces, no tracking, no data mining."
        ),
        OnboardingPage(
            icon: .epoch,
            title: "Time-Bound Communities",
            description: "Join ephemeral gatherings that exist only in the moment. When time's up, everything disappears."
        ),
        OnboardingPage(
            icon: .chain,
            title: "Cryptographic Proof",
            description: "Your presence is verified on-chain. Prove you were there without revealing who you are."
        )
    ]

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with logo and help
                headerView
                    .padding(.top, Theme.Spacing.sm)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                pageIndicator
                    .padding(.bottom, Theme.Spacing.lg)

                // Sign in button
                PrimaryButton("Sign In") {
                    coordinator.showLogin()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Logo
            HStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primaryFallback.opacity(0.15))
                        .frame(width: 28, height: 28)

                    IconView(.locationCircle, size: .sm, color: Theme.Colors.primaryFallback)
                }

                Text("outfind")
                    .font(Typography.titleSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            Spacer()

            // Help link
            Button {
                // TODO: Show help
            } label: {
                Text("Help")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    // MARK: - Page View

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                // Background glow
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)

                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .fill(.ultraThinMaterial)
                        .frame(width: 140, height: 140)

                    IconView(page.icon, size: .xxl, color: Theme.Colors.primaryFallback)
                }
            }

            Spacer()
                .frame(height: Theme.Spacing.xl)

            // Title
            Text(page.title)
                .font(Typography.headlineLarge)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)

            Spacer()
                .frame(height: Theme.Spacing.sm)

            // Description
            Text(page.description)
                .font(Typography.bodyLarge)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage
                          ? Theme.Colors.primaryFallback
                          : Theme.Colors.textTertiary.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .animation(Theme.Animation.quick, value: currentPage)
            }
        }
    }
}

// MARK: - Onboarding Page Model

private struct OnboardingPage {
    let icon: AppIcon
    let title: String
    let description: String
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
