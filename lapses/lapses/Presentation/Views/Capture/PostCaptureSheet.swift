import SwiftUI

// MARK: - Post Capture Sheet

/// Clean modal sheet for post-capture actions
/// List-based options similar to native iOS share sheet
struct PostCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss

    let media: CapturedMedia
    let onEnterEpoch: () -> Void
    let onSendEphemeral: () -> Void
    let onCancel: () -> Void

    @State private var appeared = false
    @State private var selectedAction: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // Header
            Text("Share")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.bottom, 20)
                .accessibilityIdentifier("PostCaptureSheet_Title")

            // Media preview badge
            mediaBadge
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 20)

            // Options
            VStack(spacing: 0) {
                optionRow(
                    icon: "location.fill",
                    title: "Enter Epoch",
                    subtitle: "Join with this media",
                    color: Theme.Colors.primaryFallback,
                    index: 0
                ) {
                    selectAction(0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onEnterEpoch()
                    }
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 1)
                    .padding(.leading, 60)

                optionRow(
                    icon: "paperplane.fill",
                    title: "Send Ephemeral",
                    subtitle: "Share to an epoch",
                    color: Theme.Colors.info,
                    index: 1
                ) {
                    selectAction(1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onSendEphemeral()
                    }
                }
            }
            .padding(.top, 8)

            Spacer()

            // Cancel button
            Button {
                RadialHaptics.shared.dismiss()
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.gray.opacity(0.12))
                    }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .accessibilityIdentifier("PostCaptureSheet_Cancel")
        }
        .background(Color(uiColor: .systemBackground))
        .accessibilityIdentifier("PostCaptureSheet")
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Media Badge

    private var mediaBadge: some View {
        HStack(spacing: 12) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(mediaColor.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: media.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(mediaColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(media.typeDescription)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                if let detail = mediaDetail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.Colors.success)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.gray.opacity(0.08))
        }
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
    }

    private var mediaColor: Color {
        switch media {
        case .photo: return Theme.Colors.info
        case .video: return Theme.Colors.warning
        case .audio: return Theme.Colors.error
        }
    }

    private var mediaDetail: String? {
        switch media {
        case .photo(let data):
            let kb = data.count / 1024
            return "\(kb) KB"
        case .video:
            return "15s video"
        case .audio(_, let duration):
            return "\(Int(duration))s audio"
        }
    }

    // MARK: - Option Row

    private func optionRow(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        index: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            RadialHaptics.shared.selectionMade()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if selectedAction == index {
                    Color.gray.opacity(0.1)
                }
            }
        }
        .buttonStyle(PlainListRowStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.8).delay(Double(index) * 0.05),
            value: appeared
        )
        .accessibilityIdentifier("PostCaptureSheet_Option_\(title.replacingOccurrences(of: " ", with: ""))")
        .accessibilityLabel("\(title), \(subtitle)")
    }

    private func selectAction(_ index: Int) {
        withAnimation(.easeOut(duration: 0.1)) {
            selectedAction = index
        }
    }
}

// MARK: - Plain List Row Style

private struct PlainListRowStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    PostCaptureSheet(
        media: .photo(Data(count: 850 * 1024)),
        onEnterEpoch: {},
        onSendEphemeral: {},
        onCancel: {}
    )
}
