import SwiftUI

// MARK: - Explore Search Bar

/// Glass-styled search bar with filter icons for the Explore map view
struct ExploreSearchBar: View {
    @Binding var searchText: String
    let onFilterTap: () -> Void
    let onLocationTap: () -> Void
    var onViewModeTap: (() -> Void)? = nil
    var isMapMode: Bool = true

    @State private var isSearchFocused = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)

                TextField("Search epochs...", text: $searchText)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .focused($isFocused)
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs + 2)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                isFocused ? Theme.Colors.primaryFallback.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    }
            }
            .animation(.easeOut(duration: 0.2), value: isFocused)

            // View mode toggle (optional)
            if let onViewModeTap = onViewModeTap {
                MapIconButton(
                    icon: isMapMode ? "list.bullet" : "map",
                    isActive: false,
                    action: onViewModeTap
                )
            }

            // Filter button
            MapIconButton(
                icon: "slider.horizontal.3",
                isActive: false,
                action: onFilterTap
            )

            // Location button
            MapIconButton(
                icon: "location.fill",
                isActive: true,
                accentColor: Theme.Colors.primaryFallback,
                action: onLocationTap
            )
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Safe Area Wrapper

extension ExploreSearchBar {
    /// Wraps the search bar with proper safe area insets
    func withSafeArea() -> some View {
        GeometryReader { geometry in
            self
                .padding(.top, geometry.safeAreaInsets.top + Theme.Spacing.sm)
        }
    }
}

// MARK: - Map Icon Button

/// Circular icon button with glass background for map overlays
struct MapIconButton: View {
    let icon: String
    var isActive: Bool = false
    var accentColor: Color = Theme.Colors.textPrimary
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            triggerHaptic()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isActive ? accentColor : Theme.Colors.textPrimary)
                .frame(width: 40, height: 40)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        }
                }
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            ExploreSearchBar(
                searchText: .constant(""),
                onFilterTap: {},
                onLocationTap: {}
            )
            Spacer()
        }
    }
}
