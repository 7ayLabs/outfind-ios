import SwiftUI

// MARK: - Onboarding View

/// Swipeable onboarding carousel with feature pages
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
            // Blur background
            OnboardingBackground()

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

                Text("Lapses")
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
                    .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .blur(radius: 25)

                // Icon container with glass effect
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)

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

// MARK: - Onboarding Background

private struct OnboardingBackground: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    // Animated blur orbs
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(orbColor(for: index))
                            .frame(width: orbSize(for: index), height: orbSize(for: index))
                            .blur(radius: 60)
                            .offset(orbOffset(for: index, in: geometry.size))
                    }
                }
            }
            .ignoresSafeArea()

            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }

    private func orbColor(for index: Int) -> Color {
        let colors: [Color] = [
            Theme.Colors.primaryFallback.opacity(0.3),
            Theme.Colors.primaryVariantFallback.opacity(0.25),
            Theme.Colors.epochActive.opacity(0.2),
            Theme.Colors.primaryFallback.opacity(0.2)
        ]
        return colors[index % colors.count]
    }

    private func orbSize(for index: Int) -> CGFloat {
        [200, 250, 180, 220][index % 4]
    }

    private func orbOffset(for index: Int, in size: CGSize) -> CGSize {
        let baseOffsets: [(CGFloat, CGFloat)] = [
            (size.width * 0.1, size.height * 0.15),
            (size.width * 0.75, size.height * 0.65),
            (size.width * 0.5, size.height * 0.35),
            (size.width * 0.2, size.height * 0.75)
        ]
        let base = baseOffsets[index % 4]
        let animOffset = CGFloat(index + 1) * 0.2

        return CGSize(
            width: base.0 + sin(phase * animOffset) * 30,
            height: base.1 + cos(phase * animOffset) * 25
        )
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
