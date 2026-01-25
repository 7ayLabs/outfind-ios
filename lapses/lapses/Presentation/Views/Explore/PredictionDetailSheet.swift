//
//  PredictionDetailSheet.swift
//  lapses
//
//  Prediction detail view with chart, stats, and voting
//

import SwiftUI

// MARK: - Time Period

private enum ChartTimePeriod: String, CaseIterable {
    case oneHour = "1H"
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case all = "All"
}

// MARK: - Prediction Detail Sheet

struct PredictionDetailSheet: View {
    let market: PredictionMarket
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedPeriod: ChartTimePeriod = .oneDay
    @State private var chartProgress: CGFloat = 0
    @State private var isFavorited = false
    @State private var showVoteSheet = false
    @State private var selectedVoteSide: PredictionSide = .yes
    @State private var descriptionExpanded = false

    // Chart data
    private var chartData: [CGFloat] {
        generateChartData(seed: market.id.hashValue, baseValue: market.yesPercentage)
    }

    private var priceChange: Double {
        let first = chartData.first ?? 50
        let last = chartData.last ?? 50
        return Double(last - first)
    }

    private var volumeFormatted: String {
        let value = market.totalPool * 3200
        if value >= 1_000_000 {
            return String(format: "$%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    header

                    // Price display
                    priceSection
                        .padding(.top, 20)
                        .padding(.horizontal, 20)

                    // Chart
                    chartSection
                        .padding(.top, 24)

                    // Time period tabs
                    timePeriodTabs
                        .padding(.top, 16)

                    // About section
                    aboutSection
                        .padding(.top, 28)
                        .padding(.horizontal, 20)

                    // Stats section
                    statsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    // Yes/No Stats buttons
                    voteStatsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    // Spacer for bottom button
                    Spacer(minLength: 100)
                }
            }
            .scrollIndicators(.hidden)

            // Bottom action
            bottomAction
        }
        .background(Theme.Colors.background)
        .onAppear {
            animateChart()
        }
        .sheet(isPresented: $showVoteSheet) {
            VoteConfirmSheet(
                market: market,
                side: selectedVoteSide
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Navigation bar
            HStack(spacing: 16) {
                // Back button
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                // Market icon + type
                HStack(spacing: 8) {
                    Image(systemName: market.predictionType.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.Colors.surface))

                    Text(market.predictionType.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer()

                // Actions
                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            isFavorited.toggle()
                        }
                    } label: {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(isFavorited ? .red : Theme.Colors.primaryFallback)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Price Section

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Epoch context
            HStack(spacing: 6) {
                Circle()
                    .fill(market.isActive ? Color.green : Theme.Colors.textTertiary)
                    .frame(width: 6, height: 6)
                Text(market.epochTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)

                if market.isActive {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                }
            }

            // Question
            Text(market.question)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Current percentage + change
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(Int(market.yesPercentage))%")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)

                // Change indicator
                HStack(spacing: 4) {
                    Image(systemName: priceChange >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(String(format: "%.1f%%", abs(priceChange)))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(priceChange >= 0 ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((priceChange >= 0 ? Color.green : Color.red).opacity(0.12))
                )
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        DetailChart(
            data: chartData,
            progress: chartProgress,
            color: .green
        )
        .frame(height: 180)
        .padding(.horizontal, 4)
    }

    // MARK: - Time Period Tabs

    private var timePeriodTabs: some View {
        HStack(spacing: 4) {
            ForEach(ChartTimePeriod.allCases, id: \.self) { period in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25)) {
                        selectedPeriod = period
                    }
                    animateChart()
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selectedPeriod == period ? Theme.Colors.background : Theme.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPeriod == period ? Theme.Colors.textPrimary : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(predictionDescription)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Theme.Colors.textSecondary)
                .lineSpacing(4)
                .lineLimit(descriptionExpanded ? nil : 3)

            Button {
                withAnimation(.spring(response: 0.3)) {
                    descriptionExpanded.toggle()
                }
            } label: {
                Text(descriptionExpanded ? "Show less" : "Read more")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryFallback)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var predictionDescription: String {
        "This prediction market is linked to the epoch \"\(market.epochTitle)\". Participants can vote on whether \(market.question.lowercased()) The market resolves based on verified on-chain presence data and epoch outcomes. All predictions are final and settled automatically when the epoch concludes."
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: 0) {
                statRow(icon: "chart.bar.fill", label: "Total Volume", value: volumeFormatted)
                Divider().background(Theme.Colors.surface)
                statRow(icon: "person.2.fill", label: "Participants", value: "\(market.totalVoters)")
                Divider().background(Theme.Colors.surface)
                statRow(icon: "clock.fill", label: "Time Remaining", value: timeRemainingFormatted)
                Divider().background(Theme.Colors.surface)
                statRow(icon: "calendar", label: "Resolution", value: resolutionDateFormatted)
                Divider().background(Theme.Colors.surface)
                statRow(icon: "arrow.up.right", label: "24h High", value: "\(Int(min(99, market.yesPercentage + 5)))%")
                Divider().background(Theme.Colors.surface)
                statRow(icon: "arrow.down.right", label: "24h Low", value: "\(Int(max(1, market.yesPercentage - 8)))%")
            }
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(.vertical, 14)
    }

    private var timeRemainingFormatted: String {
        let remaining = market.timeRemaining
        if remaining <= 0 { return "Ended" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 24 {
            return "\(hours / 24)d \(hours % 24)h"
        }
        return "\(hours)h \(minutes)m"
    }

    private var resolutionDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: market.endTime)
    }

    // MARK: - Vote Stats Section

    private var voteStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictions")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)

            HStack(spacing: 12) {
                // Yes card
                voteStatCard(
                    side: .yes,
                    percentage: market.yesPercentage,
                    voters: market.yesVoters,
                    odds: market.yesOdds,
                    color: .green
                )

                // No card
                voteStatCard(
                    side: .no,
                    percentage: market.noPercentage,
                    voters: market.noVoters,
                    odds: market.noOdds,
                    color: Color(white: 0.4)
                )
            }
        }
    }

    private func voteStatCard(side: PredictionSide, percentage: Double, voters: Int, odds: Double, color: Color) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedVoteSide = side
            showVoteSheet = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(side == .yes ? "Yes" : "No")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)

                    Spacer()

                    Text(String(format: "%.1fx", odds))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                // Percentage
                Text("\(Int(percentage))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textPrimary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.surface)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(percentage / 100))
                    }
                }
                .frame(height: 4)

                // Voters
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10, weight: .medium))
                    Text("\(voters) votes")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.Colors.surface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Action

    private var bottomAction: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [Theme.Colors.background.opacity(0), Theme.Colors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)

            // Button container
            HStack(spacing: 12) {
                // Yes button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedVoteSide = .yes
                    showVoteSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Yes")
                            .font(.system(size: 15, weight: .bold))
                        Text("\(Int(market.yesPercentage))%")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(Theme.Colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green)
                    )
                }

                // No button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    selectedVoteSide = .no
                    showVoteSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("No")
                            .font(.system(size: 15, weight: .bold))
                        Text("\(Int(market.noPercentage))%")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    }
                    .foregroundStyle(Theme.Colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(white: 0.3))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(Theme.Colors.background)
        }
    }

    // MARK: - Helpers

    private func animateChart() {
        chartProgress = 0
        guard !reduceMotion else {
            chartProgress = 1
            return
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            chartProgress = 1
        }
    }

    private func generateChartData(seed: Int, baseValue: Double) -> [CGFloat] {
        // Use overflow-safe addition with &+ operator
        let combinedSeed = UInt64(truncatingIfNeeded: seed.hashValue) &+ UInt64(truncatingIfNeeded: selectedPeriod.hashValue)
        var seededRandom = SeededRandomGenerator(seed: combinedSeed)
        var data: [CGFloat] = []
        var value = baseValue * 0.7

        let pointCount: Int
        switch selectedPeriod {
        case .oneHour: pointCount = 12
        case .oneDay: pointCount = 24
        case .oneWeek: pointCount = 35
        case .oneMonth: pointCount = 45
        case .all: pointCount = 60
        }

        for i in 0..<pointCount {
            let noise = (seededRandom.next() - 0.5) * 12
            let trend = sin(Double(i) * 0.2) * 4
            let momentum = (baseValue - value) * 0.03
            value = value + noise + trend + momentum
            value = max(5, min(95, value))
            data.append(CGFloat(value))
        }

        // Approach final value
        for _ in 0..<5 {
            value += (baseValue - value) * 0.3 + (seededRandom.next() - 0.5) * 2
            value = max(5, min(95, value))
            data.append(CGFloat(value))
        }

        return data
    }
}

// MARK: - Detail Chart

private struct DetailChart: View {
    let data: [CGFloat]
    let progress: CGFloat
    let color: Color

    @State private var endDotScale: CGFloat = 0
    @State private var endDotPulse: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Grid lines
                gridLines(height: height)

                // Gradient fill
                gradientFill(width: width, height: height)

                // Main line
                mainLine(width: width, height: height)

                // End dot
                endDot(width: width, height: height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.8)) {
                endDotScale = 1
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(1)) {
                endDotPulse = 1.5
            }
        }
    }

    private func gridLines(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { i in
                if i > 0 { Spacer() }
                Rectangle()
                    .fill(Theme.Colors.surface)
                    .frame(height: 1)
            }
        }
    }

    private func gradientFill(width: CGFloat, height: CGFloat) -> some View {
        let points = calculatePoints(width: width, height: height)

        return Path { path in
            guard points.count > 1 else { return }
            path.move(to: CGPoint(x: points[0].x, y: height))
            path.addLine(to: points[0])

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

            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: height))
            }
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [color.opacity(0.25), color.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .mask(
            Rectangle()
                .scaleEffect(x: progress, y: 1, anchor: .leading)
        )
    }

    private func mainLine(width: CGFloat, height: CGFloat) -> some View {
        let points = calculatePoints(width: width, height: height)

        return Path { path in
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
        .stroke(
            color,
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }

    private func endDot(width: CGFloat, height: CGFloat) -> some View {
        let points = calculatePoints(width: width, height: height)
        guard let lastPoint = points.last else { return AnyView(EmptyView()) }

        return AnyView(
            ZStack {
                // Pulse
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .frame(width: 16, height: 16)
                    .scaleEffect(endDotPulse)
                    .opacity(2 - endDotPulse)

                // Dot
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(endDotScale)
            }
            .position(lastPoint)
            .opacity(progress > 0.9 ? 1 : 0)
        )
    }

    private func calculatePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        data.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * width
            let y = height - (value / 100 * height * 0.85) - height * 0.075
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Seeded Random Generator

private struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1000) / 1000.0
    }
}

// MARK: - Vote Confirm Sheet

private struct VoteConfirmSheet: View {
    let market: PredictionMarket
    let side: PredictionSide
    @Environment(\.dismiss) private var dismiss

    // State
    @State private var selectedAmount: Double = 25
    @State private var sliderProgress: CGFloat = 0.05
    @State private var swipeOffset: CGFloat = 0
    @State private var isConfirming = false
    @State private var showSuccess = false

    private let maxAmount: Double = 500
    private let availableBalance: Double = 247.50
    private let quickAmounts: [Double] = [10, 25, 50, 100]

    // Computed
    private var potentialReturn: Double {
        let odds = side == .yes ? market.yesOdds : market.noOdds
        return selectedAmount * odds
    }

    private var probability: Double {
        side == .yes ? market.yesPercentage : market.noPercentage
    }

    private var canConfirm: Bool {
        selectedAmount > 0 && selectedAmount <= availableBalance
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                VStack(spacing: 32) {
                    amountDisplay
                    amountSlider
                    quickChips
                    statsRow
                }
                .padding(.top, 40)
                .padding(.horizontal, 20)

                Spacer()

                confirmSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }

            if showSuccess {
                successOverlay
            }
        }
    }

    // MARK: - Header

    private var sheetHeader: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.Colors.textTertiary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack(alignment: .center) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.Colors.surface))
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(side == .yes ? Color.green : Color.red.opacity(0.8))
                        .frame(width: 6, height: 6)
                    Text("\(Int(probability))%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.Colors.surface))

                Spacer()

                Text("\(String(format: "%.1fx", side == .yes ? market.yesOdds : market.noOdds))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(side == .yes ? Color.green : Color.red.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(side == .yes ? Color.green.opacity(0.3) : Color.red.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack(spacing: 12) {
                Text(market.question)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: market.predictionType.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textTertiary)
                    Text(market.epochTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text("•")
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text(side == .yes ? "Yes" : "No")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(side == .yes ? Color.green : Color.red.opacity(0.85))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("$")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text(String(format: "%.0f", selectedAmount))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25), value: selectedAmount)
        }
    }

    // MARK: - Amount Slider

    private var amountSlider: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let width = geo.size.width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Colors.surface)
                        .frame(height: 8)

                    Capsule()
                        .fill(side == .yes ? Color.green : Color.red.opacity(0.75))
                        .frame(width: max(20, width * sliderProgress), height: 8)

                    Circle()
                        .fill(Theme.Colors.textPrimary)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        .offset(x: max(0, min(width - 24, width * sliderProgress - 12)))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let progress = max(0, min(1, value.location.x / width))
                                    sliderProgress = progress
                                    selectedAmount = round(progress * maxAmount)
                                }
                        )
                }
            }
            .frame(height: 24)

            HStack {
                Text("$0")
                Spacer()
                Text("$\(Int(maxAmount))")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    // MARK: - Quick Chips

    private var quickChips: some View {
        HStack(spacing: 8) {
            ForEach(quickAmounts, id: \.self) { amount in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.25)) {
                        selectedAmount = amount
                        sliderProgress = amount / maxAmount
                    }
                } label: {
                    Text("$\(Int(amount))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selectedAmount == amount ? Theme.Colors.textOnAccent : Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedAmount == amount
                                      ? (side == .yes ? Color.green : Color.red.opacity(0.8))
                                      : Theme.Colors.surface)
                        )
                }
                .buttonStyle(.plain)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.25)) {
                    selectedAmount = min(availableBalance, maxAmount)
                    sliderProgress = selectedAmount / maxAmount
                }
            } label: {
                Text("MAX")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.surface, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Balance")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("$\(String(format: "%.0f", availableBalance))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Theme.Colors.surface)
                .frame(width: 1, height: 32)

            VStack(spacing: 4) {
                Text("Return")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("$\(String(format: "%.0f", potentialReturn))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(side == .yes ? Color.green : Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Theme.Colors.surface)
                .frame(width: 1, height: 32)

            VStack(spacing: 4) {
                Text("Profit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("+$\(String(format: "%.0f", potentialReturn - selectedAmount))")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.green)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.Colors.surface.opacity(0.5))
        )
    }

    // MARK: - Confirm Section

    private var confirmSection: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let width = geo.size.width
                let threshold = width * 0.65

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.Colors.surface)

                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            (side == .yes ? Color.green : Color.red.opacity(0.7)).opacity(0.2)
                        )
                        .frame(width: max(56, swipeOffset + 56))

                    Text(canConfirm ? "Slide to confirm" : "Insufficient funds")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .opacity(swipeOffset < threshold * 0.4 ? 1 : 0)

                    RoundedRectangle(cornerRadius: 24)
                        .fill(canConfirm ? (side == .yes ? Color.green : Color.red.opacity(0.85)) : Theme.Colors.textTertiary.opacity(0.5))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: swipeOffset > threshold ? "checkmark" : "arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textOnAccent)
                        )
                        .offset(x: swipeOffset + 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard canConfirm else { return }
                                    swipeOffset = max(0, min(width - 56, value.translation.width))
                                    if swipeOffset > threshold && !isConfirming {
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                        isConfirming = true
                                    } else if swipeOffset < threshold {
                                        isConfirming = false
                                    }
                                }
                                .onEnded { _ in
                                    guard canConfirm else { return }
                                    if swipeOffset > threshold {
                                        withAnimation(.spring(response: 0.25)) {
                                            swipeOffset = width - 56
                                        }
                                        confirm()
                                    } else {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            swipeOffset = 0
                                            isConfirming = false
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 56)
            .opacity(canConfirm ? 1 : 0.5)

            Text("Predictions are final and cannot be cancelled")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(side == .yes ? Color.green : Color.red.opacity(0.8))
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnAccent)
                }

                VStack(spacing: 6) {
                    Text("Confirmed")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.Colors.textOnAccent)

                    Text("$\(Int(selectedAmount)) on \(side == .yes ? "Yes" : "No")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textOnAccent.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Actions

    private func confirm() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.3)) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    PredictionDetailSheet(market: PredictionMarket.mockMarkets().first!)
}
