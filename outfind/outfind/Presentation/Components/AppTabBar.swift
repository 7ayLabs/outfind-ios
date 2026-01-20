import SwiftUI

// MARK: - App Tab Bar

/// Compact, animated bottom navigation bar
/// Floating glass design with centered create button
/// Adaptive for light and dark mode
struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    let onCreateTap: () -> Void
    let onCreateDrag: (CGPoint) -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var pressedTab: AppTab?

    private let barHeight: CGFloat = 52
    private let createButtonSize: CGFloat = 44

    // MARK: - Adaptive Colors

    private var selectedColor: Color {
        colorScheme == .dark ? .white : Theme.Colors.textPrimary
    }

    private var unselectedColor: Color {
        colorScheme == .dark ? .white.opacity(0.4) : Theme.Colors.textTertiary
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var createButtonBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }

    private var createButtonIconColor: Color {
        colorScheme == .dark ? .white : Theme.Colors.primaryFallback
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left tabs
            tabItem(.home)
            tabItem(.explore)

            // Center create button
            createButton
                .frame(width: 60)

            // Right tabs
            tabItem(.messages)
            tabItem(.profile)
        }
        .frame(height: barHeight)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 12, x: 0, y: 4)
                .overlay {
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: 1)
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Item

    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 2) {
                // Only apply bounce effect to the selected tab
                if isSelected {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .symbolEffect(.bounce, value: selectedTab)
                } else {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .regular))
                }

                Text(tab.title)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(isSelected ? selectedColor : unselectedColor)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabItemButtonStyle())
    }

    // MARK: - Create Button

    private var createButton: some View {
        GeometryReader { geometry in
            ZStack {
                // Glass circle
                Circle()
                    .fill(.regularMaterial)
                    .overlay {
                        Circle()
                            .strokeBorder(createButtonBorderColor, lineWidth: 1.5)
                    }
                    .frame(width: createButtonSize, height: createButtonSize)

                // Icon
                Image(systemName: "circle.hexagongrid")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(createButtonIconColor)
            }
            .frame(width: createButtonSize, height: createButtonSize)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        let globalLocation = CGPoint(
                            x: geometry.frame(in: .global).midX + value.translation.width,
                            y: geometry.frame(in: .global).midY + value.translation.height
                        )
                        onCreateDrag(globalLocation)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded { onCreateTap() }
            )
        }
        .frame(height: barHeight)
    }
}

// MARK: - App Tab Enum

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case explore
    case create
    case messages
    case profile

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home: return "circle.grid.3x3"
        case .explore: return "magnifyingglass"
        case .create: return "circle.hexagongrid"
        case .messages: return "bubble.left.and.bubble.right"
        case .profile: return "person.circle"
        }
    }

    var title: String {
        switch self {
        case .home: return "Epochs"
        case .explore: return "Explore"
        case .create: return ""
        case .messages: return "Signals"
        case .profile: return "Profile"
        }
    }
}

// MARK: - Tab Item Button Style

private struct TabItemButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        VStack {
            Spacer()
            AppTabBar(
                selectedTab: .constant(.home),
                onCreateTap: {},
                onCreateDrag: { _ in }
            )
        }
    }
}
