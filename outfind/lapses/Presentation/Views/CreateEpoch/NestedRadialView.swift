import SwiftUI

// MARK: - Nested Radial View

/// Clean vertical list of sub-options
/// Appears as a floating pill near the parent segment
struct NestedRadialView: View {
    let segment: MainRadialSegment
    let activeOptionIndex: Int?
    let onOptionSelected: (RadialSubOption) -> Void
    let onOptionHovered: (Int?) -> Void

    @State private var appeared = false

    var body: some View {
        let options = segment.subOptions

        VStack(spacing: 6) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                OptionRow(
                    option: option,
                    color: segment.accentColor,
                    isActive: activeOptionIndex == index,
                    index: index
                ) {
                    onOptionSelected(option)
                }
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        }
        .offset(nestedOffset)
        .scaleEffect(appeared ? 1 : 0.8, anchor: scaleAnchor)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }

    // Position based on parent segment angle
    private var nestedOffset: CGSize {
        switch segment {
        case .createEpoch:
            return CGSize(width: 0, height: -180)
        case .camera:
            return CGSize(width: -100, height: 80)
        case .microphone:
            return CGSize(width: 100, height: 80)
        }
    }

    private var scaleAnchor: UnitPoint {
        switch segment {
        case .createEpoch: return .bottom
        case .camera: return .topTrailing
        case .microphone: return .topLeading
        }
    }
}

// MARK: - Option Row

private struct OptionRow: View {
    let option: RadialSubOption
    let color: Color
    let isActive: Bool
    let index: Int
    let action: () -> Void

    @State private var appeared = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: option.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? color : .white)
                    .frame(width: 24)

                Text(option.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isActive ? color : .white)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(color)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? color.opacity(0.15) : .clear)
            }
        }
        .buttonStyle(OptionRowStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            withAnimation(
                .spring(response: 0.3, dampingFraction: 0.7)
                .delay(Double(index) * 0.03)
            ) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Option Row Style

private struct OptionRowStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        NestedRadialView(
            segment: .camera,
            activeOptionIndex: 1,
            onOptionSelected: { _ in },
            onOptionHovered: { _ in }
        )
    }
}
