//
//  JourneysExploreSection.swift
//  lapses
//
//  Explore available journeys - divergent branch paths to join
//

import SwiftUI

// MARK: - Journey Filter

enum JourneyFilter: String, CaseIterable {
    case trending = "Trending"
    case new = "New"
    case ending = "Ending Soon"
    case highReward = "High Reward"

    var icon: String {
        switch self {
        case .trending: return "flame"
        case .new: return "sparkles"
        case .ending: return "clock"
        case .highReward: return "diamond"
        }
    }
}

// MARK: - Branch Node

struct BranchNode: Identifiable {
    let id: String
    let name: String
    let location: String
    let reward: Double
    let status: NodeStatus
    let children: [BranchNode]

    enum NodeStatus {
        case completed, active, available, locked

        var color: Color {
            switch self {
            case .completed: return .green
            case .active: return Theme.Colors.primaryFallback
            case .available: return .cyan
            case .locked: return Theme.Colors.textSecondary.opacity(0.3)
            }
        }
    }
}

// MARK: - Journey

struct Journey: Identifiable {
    let id: String
    let title: String
    let description: String
    let rootBranch: BranchNode
    let participantCount: Int
    let totalReward: Double
    let endDate: Date?
    let creatorAddress: String
    let category: String
    let sparklineData: [CGFloat]

    var nodeCount: Int {
        countNodes(rootBranch)
    }

    private func countNodes(_ node: BranchNode) -> Int {
        1 + node.children.reduce(0) { $0 + countNodes($1) }
    }

    var timeRemaining: String? {
        guard let end = endDate else { return nil }
        let remaining = end.timeIntervalSinceNow
        if remaining <= 0 { return "Ended" }
        let hours = Int(remaining / 3600)
        let days = hours / 24
        if days > 0 { return "\(days)d \(hours % 24)h" }
        return "\(hours)h"
    }
}

// MARK: - Journeys Section

struct JourneysExploreSection: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var journeys: [Journey] = []
    @State private var isLoading = true
    @State private var selectedFilter: JourneyFilter = .trending
    @State private var selectedJourney: Journey?
    @State private var sectionAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else {
                content
            }
        }
        .task { await loadData() }
        .sheet(item: $selectedJourney) { JourneyDetailSheet(journey: $0) }
    }

    private var content: some View {
        VStack(spacing: 20) {
            filterTabs
            featuredJourney
            journeyGrid
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(JourneyFilter.allCases, id: \.self) { filter in
                    filterTab(filter)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private func filterTab(_ filter: JourneyFilter) -> some View {
        let isSelected = selectedFilter == filter

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedFilter = filter
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(filter == .highReward && isSelected ? .yellow : (isSelected ? Theme.Colors.background : Theme.Colors.textSecondary))
                Text(filter.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Theme.Colors.textPrimary : Theme.Colors.surface)
            )
            .foregroundStyle(isSelected ? Theme.Colors.background : Theme.Colors.textSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Featured Journey

    @ViewBuilder
    private var featuredJourney: some View {
        if let featured = filteredJourneys.first {
            FeaturedJourneyCard(journey: featured) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                selectedJourney = featured
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    private var filteredJourneys: [Journey] {
        switch selectedFilter {
        case .trending:
            return journeys.sorted { $0.participantCount > $1.participantCount }
        case .new:
            return journeys
        case .ending:
            return journeys.filter { $0.endDate != nil }.sorted { ($0.endDate ?? .distantFuture) < ($1.endDate ?? .distantFuture) }
        case .highReward:
            return journeys.sorted { $0.totalReward > $1.totalReward }
        }
    }

    // MARK: - Journey Grid

    private var journeyGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore Journeys")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.md)

            LazyVStack(spacing: 0) {
                ForEach(Array(filteredJourneys.dropFirst().enumerated()), id: \.element.id) { index, journey in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedJourney = journey
                    } label: {
                        JourneyRow(journey: journey)
                    }
                    .buttonStyle(.plain)
                    .opacity(sectionAppeared ? 1 : 0)
                    .offset(x: sectionAppeared ? 0 : 20)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.04),
                        value: sectionAppeared
                    )

                    if index < filteredJourneys.dropFirst().count - 1 {
                        Divider()
                            .background(Theme.Colors.surface)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .onAppear {
            withAnimation { sectionAppeared = true }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.Colors.surfaceElevated)
                            .frame(width: 90, height: 32)
                            .shimmer(isActive: true)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.Colors.surfaceElevated)
                .frame(height: 200)
                .shimmer(isActive: true)
                .padding(.horizontal, Theme.Spacing.md)

            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(height: 80)
                    .shimmer(isActive: true)
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    private func loadData() async {
        try? await Task.sleep(nanoseconds: 400_000_000)
        await MainActor.run {
            journeys = Journey.mockJourneys()
            isLoading = false
        }
    }
}

// MARK: - Featured Journey Card

private struct FeaturedJourneyCard: View {
    let journey: Journey
    let onTap: () -> Void
    @State private var branchProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var categoryColor: Color {
        switch journey.category.lowercased() {
        case "art": return .purple
        case "events": return .orange
        case "wellness": return .green
        case "tech": return .cyan
        default: return Theme.Colors.primaryFallback
        }
    }

    private var percentChange: Double {
        calculatePercentChange(journey.sparklineData)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Top row: Category + Time
                HStack {
                    Text(journey.category.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(categoryColor)
                        .tracking(1)

                    if let time = journey.timeRemaining {
                        Text(time)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()
                }

                // Title
                Text(journey.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Sparkline + Value row
                HStack(spacing: 12) {
                    // Animated branch visualization
                    AnimatedBranchCanvas(node: journey.rootBranch, progress: branchProgress, categoryColor: categoryColor)
                        .frame(width: 80, height: 50)

                    // Sparkline
                    AnimatedMiniSparkline(data: journey.sparklineData, color: .green)
                        .frame(height: 36)

                    // Value + Percent
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatCurrency(journey.totalReward ))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)

                        HStack(spacing: 2) {
                            Image(systemName: "arrowtriangle.up.fill")
                                .font(.system(size: 8))
                            Text(String(format: "%.2f%%", abs(percentChange)))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.green)
                    }
                }

                // Bottom stats
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("\(journey.participantCount)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Text("joined")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)

                    HStack(spacing: 4) {
                        Text("\(journey.nodeCount)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Text("nodes")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.surfaceElevated)
            )
        }
        .buttonStyle(ExploreCardButtonStyle())
        .onAppear {
            guard !reduceMotion else {
                branchProgress = 1
                return
            }
            withAnimation(.easeOut(duration: 0.6)) {
                branchProgress = 1
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.8
            }
        }
    }
}

// MARK: - Journey Row

private struct JourneyRow: View {
    let journey: Journey
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var categoryColor: Color {
        switch journey.category.lowercased() {
        case "art": return .purple
        case "events": return .orange
        case "wellness": return .green
        case "tech": return .cyan
        default: return Theme.Colors.primaryFallback
        }
    }

    private var percentChange: Double {
        calculatePercentChange(journey.sparklineData)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(journey.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(journey.category.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(categoryColor)
                        .tracking(0.5)

                    if let time = journey.timeRemaining {
                        Text(time)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }

            Spacer()

            // Sparkline
            AnimatedMiniSparkline(data: journey.sparklineData, color: categoryColor)
                .frame(width: 60, height: 28)

            // Value + Percent
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(journey.totalReward ))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 7))
                    Text(String(format: "%.2f%%", abs(percentChange)))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.green)
            }
            .frame(minWidth: 55, alignment: .trailing)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onAppear {
            guard !reduceMotion else {
                progress = 1
                return
            }
            withAnimation(.easeOut(duration: 0.4)) {
                progress = 1
            }
        }
    }
}

// MARK: - Animated Branch Canvas

private struct AnimatedBranchCanvas: View {
    let node: BranchNode
    let progress: CGFloat
    let categoryColor: Color

    var body: some View {
        Canvas { context, size in
            drawBranch(
                context: &context,
                node: node,
                x: 12,
                y: size.height / 2,
                availableWidth: size.width - 24,
                height: size.height,
                progress: progress
            )
        }
    }

    private func drawBranch(
        context: inout GraphicsContext,
        node: BranchNode,
        x: CGFloat,
        y: CGFloat,
        availableWidth: CGFloat,
        height: CGFloat,
        progress: CGFloat
    ) {
        let nodeSize: CGFloat = 5
        let depth = maxDepth(node)
        let segmentWidth = availableWidth / CGFloat(max(depth, 1))
        let childCount = node.children.count

        // Node
        let nodeRect = CGRect(x: x - nodeSize/2, y: y - nodeSize/2, width: nodeSize, height: nodeSize)
        let nodeColor = node.status == .locked ? Theme.Colors.textSecondary.opacity(0.3) : categoryColor
        context.fill(Circle().path(in: nodeRect), with: .color(nodeColor.opacity(progress)))

        guard !node.children.isEmpty else { return }

        let spacing = height / CGFloat(childCount + 1)

        for (index, child) in node.children.enumerated() {
            let childY = spacing * CGFloat(index + 1)
            let childX = x + segmentWidth

            // Bezier curve
            var path = Path()
            path.move(to: CGPoint(x: x + nodeSize/2, y: y))

            let ctrl1 = CGPoint(x: x + segmentWidth * 0.5, y: y)
            let ctrl2 = CGPoint(x: x + segmentWidth * 0.5, y: childY)
            path.addCurve(to: CGPoint(x: childX - nodeSize/2, y: childY), control1: ctrl1, control2: ctrl2)

            let lineColor = child.status == .locked ? Theme.Colors.textSecondary.opacity(0.15) : categoryColor.opacity(0.4)
            context.stroke(path, with: .color(lineColor.opacity(progress)), lineWidth: 1.5)

            drawBranch(
                context: &context,
                node: child,
                x: childX,
                y: childY,
                availableWidth: availableWidth - segmentWidth,
                height: height,
                progress: progress
            )
        }
    }

    private func maxDepth(_ node: BranchNode) -> Int {
        if node.children.isEmpty { return 1 }
        return 1 + (node.children.map { maxDepth($0) }.max() ?? 0)
    }
}

// MARK: - Animated Mini Sparkline

private struct AnimatedMiniSparkline: View {
    let data: [CGFloat]
    let color: Color
    @State private var progress: CGFloat = 0
    @State private var dotScale: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = data.max() ?? 1
            let minVal = data.min() ?? 0
            let range = max(maxVal - minVal, 0.01)

            // Calculate smooth curve points
            let points: [CGPoint] = data.enumerated().map { index, value in
                let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
                let y = height - ((value - minVal) / range * height * 0.8) - height * 0.1
                return CGPoint(x: x, y: y)
            }

            ZStack {
                // Smooth curve line
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points[0])

                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let midX = (prev.x + curr.x) / 2

                        path.addCurve(
                            to: curr,
                            control1: CGPoint(x: midX, y: prev.y),
                            control2: CGPoint(x: midX, y: curr.y)
                        )
                    }
                }
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // End dot
                if let lastPoint = points.last {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .scaleEffect(dotScale)
                        .position(lastPoint)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else {
                progress = 1
                dotScale = 1
                return
            }
            withAnimation(.easeOut(duration: 0.6)) {
                progress = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.5)) {
                dotScale = 1
            }
        }
    }
}

// MARK: - Number Formatting

private func formatCurrency(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "$%.1fm", value / 1_000_000)
    } else if value >= 1_000 {
        return String(format: "$%.0fk", value / 1_000)
    } else {
        return String(format: "$%.0f", value)
    }
}

private func calculatePercentChange(_ data: [CGFloat]) -> Double {
    guard let first = data.first, let last = data.last, first > 0 else { return 0 }
    return ((last - first) / first) * 100
}

// MARK: - Journey Detail Sheet

private struct JourneyDetailSheet: View {
    let journey: Journey
    @Environment(\.dismiss) private var dismiss
    @State private var branchProgress: CGFloat = 0
    @State private var sparklineProgress: CGFloat = 0
    @State private var selectedNode: BranchNode?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var categoryColor: Color {
        switch journey.category.lowercased() {
        case "art": return .purple
        case "events": return .orange
        case "wellness": return .green
        case "tech": return .cyan
        default: return Theme.Colors.primaryFallback
        }
    }

    private var percentChange: Double {
        calculatePercentChange(journey.sparklineData)
    }

    // Simulated ATH (peak of sparkline data * total reward)
    private var athValue: Double {
        let peak = journey.sparklineData.max() ?? 1.0
        return journey.totalReward * Double(peak) * 1.2
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.textSecondary.opacity(0.3))
                        .frame(width: 36, height: 4)
                        .padding(.top, 8)

                    // Title + Category
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(journey.category.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(categoryColor)
                                .tracking(1)

                            if let time = journey.timeRemaining {
                                Text(time)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }

                        Text(journey.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Main Price + Sparkline Section
                    VStack(spacing: 16) {
                        // Large sparkline with price overlay
                        ZStack(alignment: .topLeading) {
                            DetailSparkline(data: journey.sparklineData, color: categoryColor, progress: sparklineProgress)
                                .frame(height: 100)

                            // Price overlay
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatCurrency(journey.totalReward))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                HStack(spacing: 4) {
                                    Image(systemName: "arrowtriangle.up.fill")
                                        .font(.system(size: 10))
                                    Text(String(format: "%.2f%%", abs(percentChange)))
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(.green)
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.horizontal, 20)

                        // ATH + Stats Row
                        HStack(spacing: 0) {
                            statBox(label: "ATH", value: formatCurrency(athValue), color: .green)
                            Divider().frame(height: 40)
                            statBox(label: "POOL", value: formatCurrency(journey.totalReward * 0.6), color: categoryColor)
                            Divider().frame(height: 40)
                            statBox(label: "JOINED", value: "\(journey.participantCount)", color: Theme.Colors.textPrimary)
                        }
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.Colors.surfaceElevated))
                        .padding(.horizontal, 20)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Colors.textSecondary)

                        Text(journey.description)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .lineSpacing(4)

                        HStack(spacing: 4) {
                            Text("by")
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Text(journey.creatorAddress)
                                .foregroundStyle(categoryColor)
                        }
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                    // Branch Path Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Journey Path")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.horizontal, 20)

                        InteractiveBranch(node: journey.rootBranch, progress: branchProgress, selected: $selectedNode)
                            .frame(height: 100)
                            .padding(.horizontal, 20)
                    }

                    // Selected node info
                    if let node = selectedNode {
                        nodeInfoCard(node)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }

                    // Join button
                    joinButton
                        .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .background(Theme.Colors.background)

            // Close button
            Button { dismiss() } label: {
                Circle()
                    .fill(Theme.Colors.surfaceElevated)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    )
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .onAppear {
            guard !reduceMotion else {
                branchProgress = 1
                sparklineProgress = 1
                return
            }
            withAnimation(.easeOut(duration: 0.8)) {
                sparklineProgress = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                branchProgress = 1
            }
        }
    }

    private func statBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.Colors.textSecondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private func nodeInfoCard(_ node: BranchNode) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(node.status.color)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 9))
                        Text(node.location)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                if node.reward > 0 {
                    Text(formatCurrency(node.reward))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(categoryColor)
                }
            }
            .padding(14)

            Divider().opacity(0.3)

            HStack {
                Text(statusText(node.status).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(node.status.color)
                    .tracking(0.8)

                Spacer()

                if node.status == .available {
                    Text("TAP TO START")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .tracking(0.8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.Colors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(node.status.color.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }

    private var joinButton: some View {
        Button {
            // Join journey
        } label: {
            HStack(spacing: 8) {
                Text("START JOURNEY")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1)

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(Theme.Colors.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor)
            )
        }
    }

    private func statusText(_ status: BranchNode.NodeStatus) -> String {
        switch status {
        case .completed: return "Completed"
        case .active: return "In Progress"
        case .available: return "Available"
        case .locked: return "Locked"
        }
    }
}

// MARK: - Detail Sparkline

private struct DetailSparkline: View {
    let data: [CGFloat]
    let color: Color
    let progress: CGFloat
    @State private var dotScale: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let maxVal = data.max() ?? 1
            let minVal = data.min() ?? 0
            let range = max(maxVal - minVal, 0.01)

            let points: [CGPoint] = data.enumerated().map { index, value in
                let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
                let y = height - ((value - minVal) / range * height * 0.7) - height * 0.15
                return CGPoint(x: x, y: y)
            }

            ZStack {
                // Gradient fill under curve
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: points[0])

                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let midX = (prev.x + curr.x) / 2
                        path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [color.opacity(0.25), color.opacity(0)], startPoint: .top, endPoint: .bottom)
                )
                .mask(Rectangle().scaleEffect(x: progress, y: 1, anchor: .leading))

                // Smooth curve line
                Path { path in
                    guard points.count > 1 else { return }
                    path.move(to: points[0])

                    for i in 1..<points.count {
                        let prev = points[i - 1]
                        let curr = points[i]
                        let midX = (prev.x + curr.x) / 2
                        path.addCurve(to: curr, control1: CGPoint(x: midX, y: prev.y), control2: CGPoint(x: midX, y: curr.y))
                    }
                }
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // End dot
                if let lastPoint = points.last {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale)
                        .position(lastPoint)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.7)) {
                dotScale = 1
            }
        }
    }
}

// MARK: - Interactive Branch

private struct InteractiveBranch: View {
    let node: BranchNode
    let progress: CGFloat
    @Binding var selected: BranchNode?

    var body: some View {
        GeometryReader { geo in
            NodeTreeView(
                node: node,
                x: 28,
                y: geo.size.height / 2,
                width: geo.size.width - 56,
                height: geo.size.height,
                progress: progress,
                selected: $selected
            )
        }
    }
}

private struct NodeTreeView: View {
    let node: BranchNode
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let progress: CGFloat
    @Binding var selected: BranchNode?

    var body: some View {
        let isSelected = selected?.id == node.id
        let depth = maxDepth(node)
        let segment = width / CGFloat(max(depth, 1))
        let childCount = node.children.count
        let spacing = height / CGFloat(max(childCount, 1) + 1)

        ZStack {
            ForEach(Array(node.children.enumerated()), id: \.element.id) { idx, child in
                let childY = spacing * CGFloat(idx + 1)
                let childX = x + segment

                LinePath(from: CGPoint(x: x, y: y), to: CGPoint(x: childX, y: childY), color: child.status.color, progress: progress)

                NodeTreeView(
                    node: child,
                    x: childX,
                    y: childY,
                    width: width - segment,
                    height: height,
                    progress: progress,
                    selected: $selected
                )
            }

            // Selection ring
            if isSelected {
                Circle()
                    .stroke(node.status.color.opacity(0.4), lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .position(x: x, y: y)
            }

            Circle()
                .fill(node.status.color)
                .frame(width: isSelected ? 18 : 14, height: isSelected ? 18 : 14)
                .scaleEffect(progress)
                .position(x: x, y: y)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selected = node
                }
        }
    }

    private func maxDepth(_ n: BranchNode) -> Int {
        if n.children.isEmpty { return 1 }
        return 1 + (n.children.map { maxDepth($0) }.max() ?? 0)
    }
}

private struct LinePath: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    let progress: CGFloat

    var body: some View {
        Path { p in
            p.move(to: from)
            let ctrl1 = CGPoint(x: (from.x + to.x) * 0.4, y: from.y)
            let ctrl2 = CGPoint(x: (from.x + to.x) * 0.6, y: to.y)
            p.addCurve(to: to, control1: ctrl1, control2: ctrl2)
        }
        .trim(from: 0, to: progress)
        .stroke(color.opacity(0.4), lineWidth: 1.5)
    }
}

// MARK: - Mock Data

extension Journey {
    static func mockJourneys() -> [Journey] {
        [
            Journey(
                id: "j1",
                title: "Art Discovery SF",
                description: "Explore San Francisco's vibrant art scene through a series of gallery visits and street art tours. Complete all nodes to earn the full reward.",
                rootBranch: BranchNode(
                    id: "r", name: "Start", location: "Union Square, SF", reward: 50, status: .available,
                    children: [
                        BranchNode(id: "b1", name: "SFMOMA", location: "151 3rd St, SF", reward: 75, status: .available, children: [
                            BranchNode(id: "b1a", name: "Modern Wing", location: "SFMOMA Floor 4", reward: 100, status: .locked, children: []),
                            BranchNode(id: "b1b", name: "Photography", location: "SFMOMA Floor 2", reward: 80, status: .locked, children: [])
                        ]),
                        BranchNode(id: "b2", name: "Street Art", location: "Clarion Alley, Mission", reward: 60, status: .available, children: [
                            BranchNode(id: "b2a", name: "Murals", location: "Balmy Alley, Mission", reward: 120, status: .locked, children: [])
                        ])
                    ]
                ),
                participantCount: 234,
                totalReward: 485,
                endDate: Date().addingTimeInterval(86400 * 3),
                creatorAddress: "0x1234...5678",
                category: "Art",
                sparklineData: [0.2, 0.4, 0.3, 0.6, 0.5, 0.8, 0.7, 0.95]
            ),
            Journey(
                id: "j2",
                title: "Crypto Conference Tour",
                description: "Attend major crypto events and prove your presence. Collect rewards at each event.",
                rootBranch: BranchNode(
                    id: "r2", name: "Begin", location: "Online Check-in", reward: 100, status: .available,
                    children: [
                        BranchNode(id: "c1", name: "ETH Denver", location: "Denver, CO", reward: 250, status: .available, children: []),
                        BranchNode(id: "c2", name: "Token2049", location: "Singapore", reward: 300, status: .locked, children: []),
                        BranchNode(id: "c3", name: "Devcon", location: "Bangkok, TH", reward: 500, status: .locked, children: [])
                    ]
                ),
                participantCount: 567,
                totalReward: 1150,
                endDate: Date().addingTimeInterval(86400 * 7),
                creatorAddress: "crypto.eth",
                category: "Events",
                sparklineData: [0.1, 0.15, 0.2, 0.35, 0.4, 0.6, 0.75, 0.92]
            ),
            Journey(
                id: "j3",
                title: "Sunset Yoga Series",
                description: "A peaceful journey through 4 sunset yoga sessions at different scenic locations.",
                rootBranch: BranchNode(
                    id: "r3", name: "Start", location: "Marina Green, SF", reward: 15, status: .available,
                    children: [
                        BranchNode(id: "y1", name: "Beach", location: "Baker Beach, SF", reward: 25, status: .available, children: []),
                        BranchNode(id: "y2", name: "Park", location: "Dolores Park, SF", reward: 25, status: .locked, children: []),
                        BranchNode(id: "y3", name: "Rooftop", location: "SFJAZZ Center", reward: 35, status: .locked, children: []),
                        BranchNode(id: "y4", name: "Mountain", location: "Twin Peaks, SF", reward: 50, status: .locked, children: [])
                    ]
                ),
                participantCount: 89,
                totalReward: 150,
                endDate: Date().addingTimeInterval(86400 * 14),
                creatorAddress: "yoga.dao",
                category: "Wellness",
                sparklineData: [0.4, 0.45, 0.5, 0.52, 0.55, 0.58, 0.62, 0.68]
            ),
            Journey(
                id: "j4",
                title: "Tech Meetup Marathon",
                description: "Network with developers at 6 different tech meetups.",
                rootBranch: BranchNode(
                    id: "r4", name: "Begin", location: "GitHub HQ, SF", reward: 40, status: .available,
                    children: [
                        BranchNode(id: "t1", name: "AI Summit", location: "Moscone Center, SF", reward: 80, status: .available, children: []),
                        BranchNode(id: "t2", name: "Web3 Builders", location: "Thiel Capital, SF", reward: 90, status: .locked, children: []),
                        BranchNode(id: "t3", name: "iOS Dev", location: "Apple Park, Cupertino", reward: 100, status: .locked, children: [])
                    ]
                ),
                participantCount: 345,
                totalReward: 310,
                endDate: Date().addingTimeInterval(86400 * 5),
                creatorAddress: "devs.eth",
                category: "Tech",
                sparklineData: [0.3, 0.35, 0.38, 0.42, 0.5, 0.55, 0.6, 0.72]
            )
        ]
    }
}

#Preview {
    ScrollView {
        JourneysExploreSection()
    }
    .background(Theme.Colors.background)
}
