import SwiftUI
import PhotosUI

// MARK: - Lapse Composer View

/// Composer for creating a "Lapse" - adding media to an existing epoch.
/// User selects an active epoch and adds photo/audio content.
struct LapseComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies
    @Environment(\.colorScheme) private var colorScheme

    // Content state
    @State private var caption = ""
    @State private var selectedImage: UIImage?
    @State private var selectedEpoch: Epoch?

    // Data state
    @State private var activeEpochs: [Epoch] = []
    @State private var isLoading = true

    // UI state
    @State private var isPosting = false
    @State private var showImagePicker = false
    @State private var showCameraCapture = false
    @State private var showAudioRecorder = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Focus
    @FocusState private var isCaptionFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if isLoading {
                    loadingView
                } else if activeEpochs.isEmpty {
                    noEpochsView
                } else {
                    contentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }

                ToolbarItem(placement: .principal) {
                    Text("Create Lapse")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    postButton
                }
            }
            .sheet(isPresented: $showImagePicker) {
                LapseImagePicker(selectedImage: $selectedImage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadActiveEpochs()
            }
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Post Button

    private var postButton: some View {
        Button {
            createLapse()
        } label: {
            if isPosting {
                ProgressView()
                    .tint(Theme.Colors.epochActive)
            } else {
                Text("Post")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canPost ? Theme.Colors.epochActive : Theme.Colors.textTertiary)
            }
        }
        .disabled(!canPost || isPosting)
    }

    private var canPost: Bool {
        selectedEpoch != nil && (selectedImage != nil || !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
            Text("Loading active epochs...")
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: - No Epochs View

    private var noEpochsView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No Active Epochs")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Join or create an epoch first to share a lapse")
                .font(.system(size: 15))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textOnAccent)
                    .frame(width: 120, height: 44)
                    .background {
                        Capsule()
                            .fill(Theme.Colors.primaryFallback)
                    }
            }
            .padding(.top, Theme.Spacing.md)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: 0) {
            // Epoch selector
            epochSelector

            Divider()
                .background(Theme.Colors.textTertiary.opacity(0.3))

            // Caption input
            captionInput

            // Image preview
            if selectedImage != nil {
                imagePreview
            }

            Spacer()

            // Media action bar
            mediaActionBar
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isCaptionFocused = true
            }
        }
    }

    // MARK: - Epoch Selector

    private var epochSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(activeEpochs) { epoch in
                    epochChip(epoch)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
        }
    }

    private func epochChip(_ epoch: Epoch) -> some View {
        let isSelected = selectedEpoch?.id == epoch.id

        return Button {
            withAnimation(Theme.Animation.quick) {
                selectedEpoch = epoch
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                // Live indicator
                Circle()
                    .fill(Theme.Colors.epochActive)
                    .frame(width: 8, height: 8)

                Text(epoch.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.Colors.textOnAccent : Theme.Colors.textPrimary)
                    .lineLimit(1)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background {
                Capsule()
                    .fill(isSelected ? Theme.Colors.epochActive : Theme.Colors.backgroundTertiary)
            }
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Caption Input

    private var captionInput: some View {
        ZStack(alignment: .topLeading) {
            if caption.isEmpty {
                Text("Add a caption...")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
            }

            TextEditor(text: $caption)
                .font(.system(size: 17))
                .foregroundStyle(Theme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.top, Theme.Spacing.sm)
                .frame(minHeight: 100)
                .focused($isCaptionFocused)
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

            Button {
                withAnimation(Theme.Animation.quick) {
                    selectedImage = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.textOnAccent)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Media Action Bar

    private var mediaActionBar: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Photo from library
            mediaButton(
                icon: "photo.fill",
                label: "Photo",
                color: Theme.Colors.epochActive
            ) {
                showImagePicker = true
            }

            // Camera
            mediaButton(
                icon: "camera.fill",
                label: "Camera",
                color: Theme.Colors.info
            ) {
                showCameraCapture = true
            }

            // Audio
            mediaButton(
                icon: "mic.fill",
                label: "Audio",
                color: Theme.Colors.warning
            ) {
                showAudioRecorder = true
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Rectangle()
                .fill(Theme.Colors.backgroundSecondary)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -4)
        }
    }

    private func mediaButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Actions

    private func loadActiveEpochs() async {
        isLoading = true
        do {
            let epochs = try await dependencies.epochRepository.fetchEpochs(filter: nil)
            let active = epochs.filter { $0.state == .active }

            await MainActor.run {
                if active.isEmpty {
                    // Use mock data for MVP
                    activeEpochs = Epoch.mockWithLocations().filter { $0.state == .active }
                } else {
                    activeEpochs = active
                }
                // Auto-select first epoch
                selectedEpoch = activeEpochs.first
                isLoading = false
            }
        } catch {
            await MainActor.run {
                activeEpochs = Epoch.mockWithLocations().filter { $0.state == .active }
                selectedEpoch = activeEpochs.first
                isLoading = false
            }
        }
    }

    private func createLapse() {
        guard canPost, let epoch = selectedEpoch else { return }

        isPosting = true

        Task {
            do {
                // Create lapse (media post tied to epoch)
                // This would upload media and create a post in the epoch

                // Simulate network delay for MVP
                try await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    isPosting = false
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

// MARK: - Lapse Image Picker

private struct LapseImagePicker: UIViewControllerRepresentable {
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
        let parent: LapseImagePicker

        init(_ parent: LapseImagePicker) {
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
    LapseComposerView()
        .environment(\.dependencies, .shared)
}

#Preview("Dark Mode") {
    LapseComposerView()
        .environment(\.dependencies, .shared)
        .preferredColorScheme(.dark)
}
