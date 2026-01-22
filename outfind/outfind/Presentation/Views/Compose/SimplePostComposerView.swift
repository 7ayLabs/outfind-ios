import SwiftUI
import PhotosUI

// MARK: - Simple Post Composer View

/// Nextdoor-style post composer for creating epoch-scoped posts.
/// Replaces the complex 3-step CreateEpochView for simple posts.
struct SimplePostComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies

    // Post content
    @State private var postText = ""
    @State private var selectedImage: UIImage?
    @State private var visibility: PostVisibility = .anyone

    // UI state
    @State private var isPosting = false
    @State private var showImagePicker = false
    @State private var showVisibilityMenu = false
    @State private var showCreateEpoch = false
    @State private var showError = false
    @State private var errorMessage = ""

    /// Target epoch for the post (if posting to specific epoch)
    let targetEpochId: UInt64?

    /// Callback when post is created
    let onPost: ((EpochPost) -> Void)?

    init(
        targetEpochId: UInt64? = nil,
        onPost: ((EpochPost) -> Void)? = nil
    ) {
        self.targetEpochId = targetEpochId
        self.onPost = onPost
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Text input area
                    textInputArea

                    // Image preview (if selected)
                    if selectedImage != nil {
                        imagePreview
                    }

                    Spacer()

                    // Bottom action bar
                    actionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    visibilitySelector
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    postButton
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showCreateEpoch) {
                CreateEpochView()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Visibility Selector

    private var visibilitySelector: some View {
        Menu {
            ForEach(PostVisibility.allCases, id: \.self) { option in
                Button {
                    visibility = option
                } label: {
                    Label(option.rawValue, systemImage: option.iconName)
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: visibility.iconName)
                    .font(.system(size: 12, weight: .medium))

                Text(visibility.rawValue)
                    .font(.system(size: 14, weight: .medium))

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                Capsule()
                    .fill(Theme.Colors.backgroundTertiary)
            }
        }
    }

    // MARK: - Post Button

    private var postButton: some View {
        Button {
            createPost()
        } label: {
            Text("Post")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(canPost ? Theme.Colors.primaryFallback : Theme.Colors.textTertiary)
        }
        .disabled(!canPost || isPosting)
    }

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Text Input Area

    private var textInputArea: some View {
        ZStack(alignment: .topLeading) {
            if postText.isEmpty {
                Text("What's on your mind?")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
            }

            TextEditor(text: $postText)
                .font(.system(size: 17))
                .foregroundStyle(Theme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.top, Theme.Spacing.sm)
                .frame(minHeight: 150)
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        ZStack(alignment: .topTrailing) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
                    .padding(.horizontal, Theme.Spacing.md)
            }

            // Remove button
            Button {
                withAnimation(Theme.Animation.quick) {
                    selectedImage = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Emoji/Mood
            actionButton(icon: "face.smiling", color: Theme.Colors.warning) {
                // Show emoji picker
            }

            // Tag/Mention
            actionButton(icon: "tag", color: Theme.Colors.info) {
                // Show tag picker
            }

            // Calendar/Event (Creates epoch)
            actionButton(icon: "calendar", color: Theme.Colors.primaryFallback) {
                showCreateEpoch = true
            }

            // Photo
            actionButton(icon: "photo", color: Theme.Colors.success) {
                showImagePicker = true
            }

            // Info
            actionButton(icon: "info.circle", color: Theme.Colors.error) {
                // Show info/help
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Rectangle()
                .fill(Theme.Colors.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
        }
    }

    private func actionButton(
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Actions

    private func createPost() {
        guard canPost else { return }

        isPosting = true

        Task {
            do {
                // Create post entity
                let newPost = EpochPost(
                    id: UUID(),
                    epochId: targetEpochId ?? 1, // Default to epoch 1 for MVP
                    author: PostAuthor(
                        id: UUID().uuidString,
                        name: "You", // Would come from current user
                        handle: "@you",
                        avatarURL: nil,
                        locationName: "Your Location"
                    ),
                    content: postText.trimmingCharacters(in: .whitespacesAndNewlines),
                    imageURLs: [], // Would upload image and get URL
                    isVideo: false,
                    videoURL: nil,
                    sectionType: .nearby,
                    location: nil,
                    createdAt: Date(),
                    postType: .post,
                    epochName: nil,
                    participantCount: nil,
                    reactionCount: 0,
                    commentCount: 0,
                    shareCount: 0,
                    hasLiked: false,
                    isSaved: false,
                    savedAt: nil,
                    reactions: [:],
                    userReaction: nil,
                    journeyCount: 0,
                    hasFutureMessages: false,
                    journeyId: nil
                )

                // Save via repository
                // let savedPost = try await dependencies.postRepository.createPost(newPost)

                // Simulate delay
                try await Task.sleep(nanoseconds: 500_000_000)

                await MainActor.run {
                    isPosting = false
                    onPost?(newPost)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPosting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Image Picker

private struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let result = results.first else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SimplePostComposerView()
        .environment(\.dependencies, .shared)
}
