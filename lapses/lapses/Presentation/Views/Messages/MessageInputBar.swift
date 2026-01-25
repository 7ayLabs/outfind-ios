import SwiftUI

// MARK: - Message Input Bar

/// Input bar for composing and sending messages
/// Minimalist design inspired by modern messaging apps
struct MessageInputBar: View {
    @Binding var text: String
    let onSend: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Text field
            HStack(spacing: Theme.Spacing.xs) {
                TextField("Message...", text: $text, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1...4)
                    .focused($isFocused)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.Colors.backgroundTertiary)
            }

            // Send button
            Button(action: {
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                onSend()
            }) {
                ZStack {
                    Circle()
                        .fill(canSend ? Theme.Colors.primaryFallback : Theme.Colors.backgroundTertiary)
                        .frame(width: 36, height: 36)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSend ? Theme.Colors.textOnAccent : Theme.Colors.textTertiary)
                }
            }
            .disabled(!canSend)
            .animation(.easeOut(duration: 0.15), value: canSend)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.Colors.textOnAccent.opacity(0.08))
                        .frame(height: 0.5)
                }
        }
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        MessageInputBar(text: .constant("")) {
            // Send action
        }
    }
    .background(Theme.Colors.background)
}
