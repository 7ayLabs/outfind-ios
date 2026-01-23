import SwiftUI
import PhotosUI

// MARK: - Unified Composer View

/// Nextdoor-style unified composer for creating epochs.
/// Clean interface with actionable icons for all epoch configuration.
struct UnifiedComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies
    @Environment(\.colorScheme) private var colorScheme

    // Content state
    @State private var title = ""
    @State private var description = ""
    @State private var selectedImage: UIImage?
    @State private var visibility: PostVisibility = .anyone

    // Epoch configuration
    @State private var startDate = Date().addingTimeInterval(3600)
    @State private var duration: TimeInterval = 3600
    @State private var useLocation = false
    @State private var locationRadius: Double = 500
    @State private var selectedCapability: EpochCapability = .presenceWithEphemeralData
    @State private var maxParticipants: Int = 0 // 0 = unlimited

    // UI state
    @State private var isCreating = false
    @State private var showImagePicker = false
    @State private var showLocationSheet = false
    @State private var showTimeSheet = false
    @State private var showCapacitySheet = false
    @State private var showCapabilitySheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Focus state for auto-keyboard
    @FocusState private var isTitleFocused: Bool

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

                    // Configuration summary pills
                    if hasConfiguration {
                        configurationSummary
                    }

                    Spacer()

                    // Bottom action bar with epoch configuration icons
                    actionBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }

                ToolbarItem(placement: .principal) {
                    visibilitySelector
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    createButton
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ComposerImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showLocationSheet) {
                LocationConfigSheet(
                    useLocation: $useLocation,
                    locationRadius: $locationRadius
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showTimeSheet) {
                TimeConfigSheet(
                    startDate: $startDate,
                    duration: $duration
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showCapacitySheet) {
                CapacityConfigSheet(maxParticipants: $maxParticipants)
                    .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showCapabilitySheet) {
                CapabilityConfigSheet(selectedCapability: $selectedCapability)
                    .presentationDetents([.medium])
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-focus title field to show keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTitleFocused = true
                }
            }
        }
    }

    private var hasConfiguration: Bool {
        useLocation || maxParticipants > 0 || selectedCapability != .presenceWithEphemeralData
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
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background {
                Capsule()
                    .fill(Theme.Colors.backgroundTertiary)
            }
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            createEpoch()
        } label: {
            if isCreating {
                ProgressView()
                    .tint(Theme.Colors.primaryFallback)
            } else {
                Text("Create")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canCreate ? Theme.Colors.primaryFallback : Theme.Colors.textTertiary)
            }
        }
        .disabled(!canCreate || isCreating)
    }

    private var canCreate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Text Input Area

    private var textInputArea: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Title input
            ZStack(alignment: .topLeading) {
                if title.isEmpty {
                    Text("What's happening?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)
                }

                TextField("", text: $title, axis: .vertical)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                    .lineLimit(2)
                    .focused($isTitleFocused)
            }

            // Description input
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Add details about your epoch...")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.horizontal, Theme.Spacing.md)
                }

                TextEditor(text: $description)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .frame(minHeight: 80)
            }
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
                    .frame(height: 180)
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
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Configuration Summary

    private var configurationSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                // Time pill
                configPill(
                    icon: "clock",
                    text: formatDuration(duration),
                    color: Theme.Colors.warning
                )

                // Location pill
                if useLocation {
                    configPill(
                        icon: "location.fill",
                        text: "\(Int(locationRadius))m",
                        color: Theme.Colors.info
                    )
                }

                // Capacity pill
                if maxParticipants > 0 {
                    configPill(
                        icon: "person.2.fill",
                        text: "\(maxParticipants) max",
                        color: Theme.Colors.success
                    )
                }

                // Capability pill
                if selectedCapability != .presenceWithEphemeralData {
                    configPill(
                        icon: capabilityIcon,
                        text: selectedCapability.shortName,
                        color: Theme.Colors.epochFinalized
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }

    private func configPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
        }
    }

    private var capabilityIcon: String {
        switch selectedCapability {
        case .presenceOnly: return "person.fill"
        case .presenceWithSignals: return "bubble.left.and.bubble.right.fill"
        case .presenceWithEphemeralData: return "photo.fill"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Location
            epochActionButton(
                icon: "location.fill",
                label: "Location",
                color: Theme.Colors.info,
                isActive: useLocation
            ) {
                showLocationSheet = true
            }

            // Time/Duration
            epochActionButton(
                icon: "clock.fill",
                label: "Time",
                color: Theme.Colors.warning,
                isActive: false
            ) {
                showTimeSheet = true
            }

            // Capacity
            epochActionButton(
                icon: "person.2.fill",
                label: "Capacity",
                color: Theme.Colors.success,
                isActive: maxParticipants > 0
            ) {
                showCapacitySheet = true
            }

            // Capability
            epochActionButton(
                icon: "shield.fill",
                label: "Privacy",
                color: Theme.Colors.epochFinalized,
                isActive: selectedCapability != .presenceWithEphemeralData
            ) {
                showCapabilitySheet = true
            }

            // Photo
            epochActionButton(
                icon: "photo.fill",
                label: "Photo",
                color: Theme.Colors.primaryFallback,
                isActive: selectedImage != nil
            ) {
                showImagePicker = true
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

    private func epochActionButton(
        icon: String,
        label: String,
        color: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isActive ? .white : color)
                    .frame(width: 48, height: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isActive ? color : color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                    }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? color : Theme.Colors.textSecondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Actions

    private func createEpoch() {
        guard canCreate else { return }

        isCreating = true

        Task {
            do {
                // Create epoch via repository
                // endDate would be: startDate.addingTimeInterval(duration)

                // Simulate network delay for MVP
                try await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Composer Image Picker

private struct ComposerImagePicker: UIViewControllerRepresentable {
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
        let parent: ComposerImagePicker

        init(_ parent: ComposerImagePicker) {
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

// MARK: - Location Config Sheet

private struct LocationConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var useLocation: Bool
    @Binding var locationRadius: Double

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.info)
                    .padding(.top, Theme.Spacing.lg)

                Text("Location Requirement")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Require participants to be within a specific area to join")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)

                // Toggle
                Toggle(isOn: $useLocation) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(Theme.Colors.info)
                        Text("Require Location")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .tint(Theme.Colors.info)
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.backgroundTertiary)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Radius slider
                if useLocation {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Radius")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Spacer()
                            Text("\(Int(locationRadius))m")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.info)
                        }

                        Slider(value: $locationRadius, in: 50...2000, step: 50)
                            .tint(Theme.Colors.info)

                        HStack {
                            Text("50m")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.textTertiary)
                            Spacer()
                            Text("2km")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(Theme.Colors.backgroundTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()
            }
            .animation(Theme.Animation.smooth, value: useLocation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.info)
                }
            }
        }
    }
}

// MARK: - Time Config Sheet

private struct TimeConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var duration: TimeInterval

    private let durationOptions: [(String, TimeInterval)] = [
        ("30m", 1800),
        ("1h", 3600),
        ("2h", 7200),
        ("4h", 14400),
        ("8h", 28800),
        ("24h", 86400)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                // Icon
                Image(systemName: "clock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.warning)
                    .padding(.top, Theme.Spacing.lg)

                Text("When & How Long")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                // Start time
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Start Time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    DatePicker(
                        "",
                        selection: $startDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Theme.Colors.warning)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Duration
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Duration")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Theme.Spacing.sm) {
                        ForEach(durationOptions, id: \.1) { option in
                            durationButton(title: option.0, value: option.1)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // End time display
                HStack {
                    Text("Ends at")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text(startDate.addingTimeInterval(duration), style: .time)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("on")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text(startDate.addingTimeInterval(duration), style: .date)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .fill(Theme.Colors.backgroundTertiary)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.warning)
                }
            }
        }
    }

    private func durationButton(title: String, value: TimeInterval) -> some View {
        Button {
            duration = value
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(duration == value ? .white : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(duration == value ? Theme.Colors.warning : Theme.Colors.backgroundTertiary)
                }
        }
    }
}

// MARK: - Capacity Config Sheet

private struct CapacityConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var maxParticipants: Int

    private let capacityOptions = [0, 5, 10, 25, 50, 100]

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.success)
                    .padding(.top, Theme.Spacing.lg)

                Text("Max Participants")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Limit how many people can join")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.sm) {
                    ForEach(capacityOptions, id: \.self) { count in
                        capacityButton(count: count)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.success)
                }
            }
        }
    }

    private func capacityButton(count: Int) -> some View {
        Button {
            maxParticipants = count
        } label: {
            Text(count == 0 ? "∞" : "\(count)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(maxParticipants == count ? .white : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                        .fill(maxParticipants == count ? Theme.Colors.success : Theme.Colors.backgroundTertiary)
                }
        }
    }
}

// MARK: - Capability Config Sheet

private struct CapabilityConfigSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCapability: EpochCapability

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.Colors.epochFinalized)
                    .padding(.top, Theme.Spacing.lg)

                Text("Privacy Level")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("Choose what participants can do")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.Colors.textSecondary)

                VStack(spacing: Theme.Spacing.sm) {
                    capabilityOption(.presenceOnly)
                    capabilityOption(.presenceWithSignals)
                    capabilityOption(.presenceWithEphemeralData)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.epochFinalized)
                }
            }
        }
    }

    private func capabilityOption(_ capability: EpochCapability) -> some View {
        Button {
            selectedCapability = capability
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: iconFor(capability))
                    .font(.system(size: 20))
                    .foregroundStyle(selectedCapability == capability ? Theme.Colors.epochFinalized : Theme.Colors.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(capability.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(capability.featureDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if selectedCapability == capability {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.Colors.epochFinalized)
                }
            }
            .padding(Theme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.backgroundTertiary)
                    .overlay {
                        if selectedCapability == capability {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                                .stroke(Theme.Colors.epochFinalized, lineWidth: 2)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private func iconFor(_ capability: EpochCapability) -> String {
        switch capability {
        case .presenceOnly: return "person.fill"
        case .presenceWithSignals: return "bubble.left.and.bubble.right.fill"
        case .presenceWithEphemeralData: return "photo.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    UnifiedComposerView()
        .environment(\.dependencies, .shared)
}

#Preview("Dark Mode") {
    UnifiedComposerView()
        .environment(\.dependencies, .shared)
        .preferredColorScheme(.dark)
}
