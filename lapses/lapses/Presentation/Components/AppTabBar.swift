import SwiftUI

// MARK: - App Tab Bar

/// Floating liquid glass navigation bar with B&W design
/// Create button at center opens composer
struct AppTabBar: View {
    @Binding var selectedTab: AppTab
    var onCreateTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let barHeight: CGFloat = 56
    private let createButtonSize: CGFloat = 44

    // MARK: - Adaptive Colors (Muted - Apple HIG)

    private var selectedColor: Color {
        Theme.Colors.textPrimary
    }

    private var unselectedColor: Color {
        Theme.Colors.textTertiary
    }

    private var createButtonColor: Color {
        Theme.Colors.textPrimary
    }

    private var createIconColor: Color {
        Theme.Colors.background
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left tabs
            tabItem(.home)
            tabItem(.explore)

            // Center create button
            createButton

            // Right tabs
            tabItem(.journeys)
            tabItem(.profile)
        }
        .frame(height: barHeight)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .accessibilityIdentifier("AppTabBar")
    }

    // MARK: - Tab Item

    private func tabItem(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if tab != .create {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = tab
                }
            }
        } label: {
            Image(systemName: tab.icon(isSelected: isSelected))
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(isSelected ? selectedColor : unselectedColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(TabItemButtonStyle())
        .accessibilityIdentifier("TabItem_\(tab.rawValue)")
        .accessibilityLabel(tab.title)
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button(action: onCreateTap) {
            ZStack {
                Circle()
                    .fill(createButtonColor)
                    .frame(width: createButtonSize, height: createButtonSize)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(createIconColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(CreateButtonStyle())
        .accessibilityIdentifier("CreateButton")
        .accessibilityLabel("Create")
    }
}

// MARK: - App Tab Enum

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case explore
    case create
    case journeys
    case profile

    var id: Int { rawValue }

    func icon(isSelected: Bool) -> String {
        switch self {
        case .home:
            return isSelected ? "house.fill" : "house"
        case .explore:
            return "magnifyingglass"
        case .create:
            return "plus"
        case .journeys:
            return isSelected ? "point.3.filled.connected.trianglepath.dotted" : "point.3.connected.trianglepath.dotted"
        case .profile:
            return isSelected ? "person.fill" : "person"
        }
    }

    var title: String {
        switch self {
        case .home: return "Home"
        case .explore: return "Explore"
        case .create: return "Create"
        case .journeys: return "Journeys"
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

// MARK: - Create Button Style

private struct CreateButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    ZStack {
        LinearGradient(
            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            AppTabBar(
                selectedTab: .constant(.home),
                onCreateTap: {}
            )
        }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        LinearGradient(
            colors: [Color.black, Color.gray.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            AppTabBar(
                selectedTab: .constant(.home),
                onCreateTap: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
