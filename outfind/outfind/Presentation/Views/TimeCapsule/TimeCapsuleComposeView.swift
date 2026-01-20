import SwiftUI

// MARK: - Time Capsule Compose View

/// View for creating a new time capsule message to your future self
struct TimeCapsuleComposeView: View {
    let epochId: UInt64
    let epochTitle: String
    let onSave: (TimeCapsule) -> Void
    let onDismiss: () -> Void

    @State private var messageText = ""
    @State private var title = ""
    @State private var isSaving = false
    @FocusState private var isMessageFocused: Bool

    private var canSave: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header illustration
                    headerSection

                    // Message input
                    messageSection

                    // Title input (optional)
                    titleSection

                    // Info card
                    infoCard
                }
                .padding()
            }
            .background(Theme.Colors.background)
            .navigationTitle("Future Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCapsule() }
                        .disabled(!canSave || isSaving)
                }
            }
        }
        .onAppear {
            isMessageFocused = true
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primaryFallback.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "envelope.badge.clock")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }

            VStack(spacing: Theme.Spacing.xxs) {
                Text("Write to Future You")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("This message will unlock when you return to \"\(epochTitle)\"")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Message Section

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Your Message")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)

            TextEditor(text: $messageText)
                .focused($isMessageFocused)
                .frame(minHeight: 150)
                .padding(Theme.Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.backgroundSecondary)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .strokeBorder(
                            isMessageFocused ? Theme.Colors.primaryFallback : Color.clear,
                            lineWidth: 2
                        )
                }
                .overlay(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("What do you want to remember about this moment?")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.textTertiary)
                            .padding(.horizontal, Theme.Spacing.sm + 5)
                            .padding(.vertical, Theme.Spacing.sm + 8)
                            .allowsHitTesting(false)
                    }
                }

            Text("\(messageText.count)/500")
                .font(.system(size: 12))
                .foregroundStyle(messageText.count > 500 ? Theme.Colors.error : Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Title (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)

            TextField("Give your message a title", text: $title)
                .textFieldStyle(.plain)
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.backgroundSecondary)
                }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.Colors.primaryFallback)

            Text("Your message stays encrypted until you attend this epoch again")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(Theme.Colors.primaryFallback.opacity(0.1))
        }
    }

    // MARK: - Actions

    private func saveCapsule() {
        guard canSave else { return }
        isSaving = true

        let capsule = TimeCapsule.forEpoch(
            authorId: "current-user", // Would get from auth
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            epochId: epochId,
            title: title.isEmpty ? nil : title
        )

        onSave(capsule)
    }
}

// MARK: - Preview

#Preview {
    TimeCapsuleComposeView(
        epochId: 1,
        epochTitle: "Coffee Shop Meetup",
        onSave: { _ in },
        onDismiss: {}
    )
}
