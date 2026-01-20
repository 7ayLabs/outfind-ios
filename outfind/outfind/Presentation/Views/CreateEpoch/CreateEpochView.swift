import SwiftUI

// MARK: - Create Epoch View

/// View for creating a new epoch with all required fields
struct CreateEpochView: View {
    @Environment(\.coordinator) private var coordinator
    @Environment(\.dependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCapability: EpochCapability = .presenceWithEphemeralData
    @State private var startDate = Date().addingTimeInterval(3600)
    @State private var duration: TimeInterval = 3600
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var useLocation = false
    @State private var locationRadius: Double = 500

    // UI state
    @State private var currentStep = 0
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let durationOptions: [(String, TimeInterval)] = [
        ("30 min", 1800),
        ("1 hour", 3600),
        ("2 hours", 7200),
        ("4 hours", 14400),
        ("8 hours", 28800),
        ("24 hours", 86400)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ProgressBar(currentStep: currentStep, totalSteps: 3)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)

                    TabView(selection: $currentStep) {
                        basicInfoStep.tag(0)
                        timingStep.tag(1)
                        settingsStep.tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(Theme.Animation.smooth, value: currentStep)

                    navigationButtons
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Create Epoch"
        case 1: return "Set Timing"
        case 2: return "Configure"
        default: return "Create Epoch"
        }
    }

    fileprivate var endDate: Date {
        startDate.addingTimeInterval(duration)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return !title.isEmpty
        case 1: return startDate > Date()
        case 2: return true
        default: return true
        }
    }
}

// MARK: - Step Views

extension CreateEpochView {
    fileprivate var basicInfoStep: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        LiquidGlassOrb(size: 80, color: Theme.Colors.primaryFallback)
                        IconView(.add, size: .xl, color: Theme.Colors.primaryFallback)
                    }

                    Text("What's this epoch about?")
                        .font(Typography.headlineSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Give your epoch a name and description")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.lg)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Title")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    GlassTextField("Enter epoch title", text: $title, icon: .epoch)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Description")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    GlassTextEditor(
                        "Describe what will happen in this epoch...",
                        text: $description
                    )
                    .frame(minHeight: 120)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Tags (optional)")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    HStack {
                        GlassTextField("Add tag", text: $newTag, icon: nil)

                        Button {
                            addTag()
                        } label: {
                            IconView(.add, size: .md, color: Theme.Colors.primaryFallback)
                                .frame(width: 48, height: 48)
                                .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.md)
                        }
                        .disabled(newTag.isEmpty)
                    }

                    if !tags.isEmpty {
                        FlowLayout(spacing: Theme.Spacing.xs) {
                            ForEach(tags, id: \.self) { tag in
                                TagChip(tag: tag) {
                                    tags.removeAll { $0 == tag }
                                }
                            }
                        }
                        .padding(.top, Theme.Spacing.xs)
                    }
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    fileprivate var timingStep: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        LiquidGlassOrb(size: 80, color: Theme.Colors.epochScheduled)
                        IconView(.timer, size: .xl, color: Theme.Colors.epochScheduled)
                    }

                    Text("When should it happen?")
                        .font(Typography.headlineSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Set the start time and duration")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.lg)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Start Time")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    DatePicker(
                        "",
                        selection: $startDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(Theme.Colors.primaryFallback)
                    .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Duration")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Theme.Spacing.sm) {
                        ForEach(durationOptions, id: \.1) { option in
                            DurationOption(
                                title: option.0,
                                isSelected: duration == option.1
                            ) {
                                duration = option.1
                            }
                        }
                    }
                }

                VStack(spacing: Theme.Spacing.xs) {
                    HStack {
                        Text("Ends at")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Spacer()

                        Text(endDate, style: .date)
                            .font(Typography.titleSmall)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        +
                        Text(" at ")
                            .font(Typography.bodyMedium)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        +
                        Text(endDate, style: .time)
                            .font(Typography.titleSmall)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
                .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    fileprivate var settingsStep: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        LiquidGlassOrb(size: 80, color: Theme.Colors.epochActive)
                        IconView(.settings, size: .xl, color: Theme.Colors.epochActive)
                    }

                    Text("Configure capabilities")
                        .font(Typography.headlineSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text("Choose what participants can do")
                        .font(Typography.bodyMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.lg)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Epoch Capability")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    VStack(spacing: Theme.Spacing.sm) {
                        CapabilityOption(
                            capability: .presenceOnly,
                            isSelected: selectedCapability == .presenceOnly
                        ) {
                            selectedCapability = .presenceOnly
                        }

                        CapabilityOption(
                            capability: .presenceWithSignals,
                            isSelected: selectedCapability == .presenceWithSignals
                        ) {
                            selectedCapability = .presenceWithSignals
                        }

                        CapabilityOption(
                            capability: .presenceWithEphemeralData,
                            isSelected: selectedCapability == .presenceWithEphemeralData
                        ) {
                            selectedCapability = .presenceWithEphemeralData
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Location Requirement")
                        .font(Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    ToggleRow(
                        "Require Location",
                        subtitle: "Participants must be within a radius",
                        icon: .location,
                        isOn: $useLocation
                    )

                    if useLocation {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            HStack {
                                Text("Radius: \(Int(locationRadius))m")
                                    .font(Typography.bodyMedium)
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Spacer()
                            }

                            Slider(value: $locationRadius, in: 100...5000, step: 100)
                                .tint(Theme.Colors.primaryFallback)
                        }
                        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.md)
                    }
                }

                EpochSummaryCard(
                    title: title.isEmpty ? "Untitled Epoch" : title,
                    startDate: startDate,
                    endDate: endDate,
                    capability: selectedCapability,
                    tags: tags
                )

                Spacer(minLength: Theme.Spacing.xxl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }
}

// MARK: - Navigation & Actions

extension CreateEpochView {
    fileprivate var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            if currentStep > 0 {
                SecondaryButton("Back", icon: .back) {
                    withAnimation(Theme.Animation.smooth) {
                        currentStep -= 1
                    }
                }
            }

            if currentStep < 2 {
                PrimaryButton("Next", isDisabled: !canProceed) {
                    withAnimation(Theme.Animation.smooth) {
                        currentStep += 1
                    }
                }
            } else {
                PrimaryButton(
                    "Create Epoch",
                    icon: .epoch,
                    isLoading: isCreating,
                    isDisabled: !canProceed
                ) {
                    createEpoch()
                }
            }
        }
    }

    fileprivate func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !tags.contains(tag), tags.count < 5 else { return }
        tags.append(tag)
        newTag = ""
    }

    fileprivate func createEpoch() {
        isCreating = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                isCreating = false
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

private struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.backgroundTertiary)
                    .frame(height: 4)

                Capsule()
                    .fill(Theme.Colors.primaryGradient)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(Theme.Animation.smooth, value: currentStep)
            }
        }
        .frame(height: 4)
    }

    private var progress: CGFloat {
        CGFloat(currentStep + 1) / CGFloat(totalSteps)
    }
}

private struct DurationOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.titleSmall)
                .foregroundStyle(isSelected ? .white : Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .fill(isSelected ? Theme.Colors.primaryFallback : .clear)
                }
                .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.md)
        }
    }
}

private struct CapabilityOption: View {
    let capability: EpochCapability
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                IconView(icon, size: .lg, color: isSelected ? Theme.Colors.primaryFallback : Theme.Colors.textSecondary)

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(capability.displayName)
                        .font(Typography.titleSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(capability.featureDescription)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    IconView(.checkmarkCircleFill, size: .lg, color: Theme.Colors.primaryFallback)
                } else {
                    Circle()
                        .strokeBorder(Theme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .glassCard(style: isSelected ? .regular : .thin, cornerRadius: Theme.CornerRadius.md)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                        .strokeBorder(Theme.Colors.primaryFallback, lineWidth: 2)
                        .padding(-Theme.Spacing.md)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var icon: AppIcon {
        switch capability {
        case .presenceOnly: return .presence
        case .presenceWithSignals: return .signals
        case .presenceWithEphemeralData: return .media
        }
    }
}

private struct TagChip: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Text("#\(tag)")
                .font(Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textPrimary)

            Button(action: onRemove) {
                IconView(.close, size: .xs, color: Theme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background {
            Capsule()
                .fill(Theme.Colors.backgroundTertiary)
        }
    }
}

private struct EpochSummaryCard: View {
    let title: String
    let startDate: Date
    let endDate: Date
    let capability: EpochCapability
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Summary")
                .font(Typography.labelLarge)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    IconView(.epoch, size: .md, color: Theme.Colors.primaryFallback)
                    Text(title)
                        .font(Typography.titleSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                HStack {
                    IconView(.timer, size: .md, color: Theme.Colors.epochScheduled)
                    Text("\(startDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("→")
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text("\(endDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                HStack {
                    IconView(.signals, size: .md, color: Theme.Colors.epochActive)
                    Text(capability.displayName)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                if !tags.isEmpty {
                    HStack {
                        IconView(.star, size: .md, color: Theme.Colors.epochFinalized)
                        Text(tags.map { "#\($0)" }.joined(separator: " "))
                            .font(Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .glassCard(style: .thin, cornerRadius: Theme.CornerRadius.lg)
    }
}

// MARK: - Glass Text Editor

private struct GlassTextEditor: View {
    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.md)
            }

            TextEditor(text: $text)
                .font(Typography.bodyLarge)
                .foregroundStyle(Theme.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .focused($isFocused)
        }
        .frostedGlass(style: .thin, cornerRadius: Theme.CornerRadius.md)
        .overlay {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                .strokeBorder(
                    isFocused ? Theme.Colors.primaryFallback : .clear,
                    lineWidth: 2
                )
        }
        .animation(Theme.Animation.quick, value: isFocused)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let containerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX)
        }

        return (positions, CGSize(width: maxWidth, height: currentY + lineHeight))
    }
}

// MARK: - Preview

#Preview {
    CreateEpochView()
        .environment(\.dependencies, .shared)
        .environment(\.coordinator, AppCoordinator(dependencies: .shared))
}
