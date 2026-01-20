import SwiftUI

// MARK: - App Tab Bar

/// Compact, animated bottom navigation bar
/// Floating glass design with centered create button
/// Long-press on center button triggers quick action menu
struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    let onCreateTap: () -> Void
    let onLongPressStart: (CGPoint) -> Void
    let onLongPressDrag: (CGPoint) -> Void
    let onLongPressEnd: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var isLongPressing = false
    @State private var createButtonFrame: CGRect = .zero

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
        .accessibilityIdentifier("AppTabBar")
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
        .accessibilityIdentifier("TabItem_\(tab.rawValue)")
        .accessibilityLabel(tab.title.isEmpty ? "Create" : tab.title)
    }

    // MARK: - Create Button

    private var createButton: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.frame(in: .global).midX,
                y: geometry.frame(in: .global).midY
            )

            ZStack {
                // Glass circle
                Circle()
                    .fill(.regularMaterial)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isLongPressing ? Theme.Colors.primaryFallback : createButtonBorderColor,
                                lineWidth: isLongPressing ? 2 : 1.5
                            )
                    }
                    .frame(width: createButtonSize, height: createButtonSize)
                    .scaleEffect(isLongPressing ? 1.1 : 1)

                // Icon
                Image(systemName: "circle.hexagongrid")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isLongPressing ? Theme.Colors.primaryFallback : createButtonIconColor)
            }
            .frame(width: createButtonSize, height: createButtonSize)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .contentShape(Circle())
            .gesture(
                LongPressGesture(minimumDuration: 0.2)
                    .sequenced(before: DragGesture(minimumDistance: 0))
                    .onChanged { value in
                        switch value {
                        case .first(true):
                            // Long press recognized
                            if !isLongPressing {
                                isLongPressing = true
                                RadialHaptics.shared.menuAppear()
                                onLongPressStart(center)
                            }
                        case .second(true, let drag):
                            // Dragging after long press
                            if let drag = drag {
                                onLongPressDrag(drag.location)
                            }
                        default:
                            break
                        }
                    }
                    .onEnded { value in
                        isLongPressing = false
                        onLongPressEnd()
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !isLongPressing {
                            onCreateTap()
                        }
                    }
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isLongPressing)
            .accessibilityIdentifier("CreateButton")
            .accessibilityLabel("Create, long press for options")
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
                onLongPressStart: { _ in },
                onLongPressDrag: { _ in },
                onLongPressEnd: {}
            )
        }
    }
}
