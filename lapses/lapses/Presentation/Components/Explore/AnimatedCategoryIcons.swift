//
//  AnimatedCategoryIcons.swift
//  lapses
//
//  Animated Web3-themed icons for Explore category tabs
//

import SwiftUI

// MARK: - Web3 Colors

private enum Web3Colors {
    static let gold = Color(red: 0.95, green: 0.75, blue: 0.25)
    static let amber = Color(red: 0.85, green: 0.55, blue: 0.15)
    static let emerald = Color(red: 0.2, green: 0.8, blue: 0.5)
    static let mint = Color(red: 0.4, green: 0.9, blue: 0.6)
    static let violet = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let purple = Color(red: 0.5, green: 0.3, blue: 0.8)
    static let cyan = Color(red: 0.3, green: 0.7, blue: 0.9)
    static let blue = Color(red: 0.25, green: 0.5, blue: 0.85)
    static let orange = Color(red: 0.95, green: 0.6, blue: 0.2)
    static let coral = Color(red: 0.9, green: 0.45, blue: 0.35)
}

// MARK: - Animated Lapsers Icon (Stacked Coins)

struct AnimatedLapsersIcon: View {
    let isActive: Bool
    let size: CGFloat

    @State private var coinOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var primaryColor: Color {
        isActive ? Web3Colors.gold : Theme.Colors.textTertiary
    }

    private var secondaryColor: Color {
        isActive ? Web3Colors.amber : Theme.Colors.textTertiary.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Bottom coin (shadow)
            Circle()
                .fill(secondaryColor.opacity(0.35))
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(y: 3)

            // Middle coin
            Circle()
                .fill(
                    LinearGradient(
                        colors: [secondaryColor, secondaryColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(y: 1.5)

            // Top coin
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.55, height: size * 0.55)

                // Inner ring detail
                Circle()
                    .stroke(primaryColor.opacity(0.6), lineWidth: 1)
                    .frame(width: size * 0.35, height: size * 0.35)

                // Center dot
                Circle()
                    .fill(primaryColor.opacity(0.8))
                    .frame(width: size * 0.12, height: size * 0.12)
            }
            .offset(y: -coinOffset)
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion && isActive else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                coinOffset = 1.5
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    coinOffset = 1.5
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    coinOffset = 0
                }
            }
        }
    }
}

// MARK: - Animated Chart Icon (Predictions)

struct AnimatedChartIcon: View {
    let isActive: Bool
    let size: CGFloat

    @State private var progress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let chartPoints: [CGFloat] = [0.3, 0.5, 0.35, 0.7, 0.55, 0.85, 0.6]

    private var primaryColor: Color {
        isActive ? Web3Colors.emerald : Theme.Colors.textTertiary
    }

    private var secondaryColor: Color {
        isActive ? Web3Colors.mint : Theme.Colors.textTertiary.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Background bars
            HStack(spacing: size * 0.08) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(primaryColor.opacity(isActive ? 0.15 : 0.1))
                        .frame(width: size * 0.1, height: size * CGFloat([0.3, 0.5, 0.4, 0.6][i]))
                }
            }
            .frame(width: size, height: size, alignment: .bottom)

            // Chart line
            ChartPath(points: chartPoints, progress: reduceMotion ? 1 : progress)
                .stroke(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )

            // Pulse dot at end
            if progress > 0.9 || reduceMotion {
                Circle()
                    .fill(primaryColor)
                    .frame(width: 4, height: 4)
                    .scaleEffect(pulseScale)
                    .position(x: size * 0.9, y: size * (1 - chartPoints.last! * 0.7) - size * 0.15)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else {
                progress = 1
                return
            }
            withAnimation(.easeOut(duration: 0.8)) {
                progress = 1
            }
            if isActive {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true).delay(0.8)) {
                    pulseScale = 1.5
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    pulseScale = 1.5
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseScale = 1
                }
            }
        }
    }
}

// MARK: - Animated Path Icon (Journeys)

struct AnimatedPathIcon: View {
    let isActive: Bool
    let size: CGFloat

    @State private var activeNode: Int = 0
    @State private var pathProgress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let nodeCount = 4

    private var primaryColor: Color {
        isActive ? Web3Colors.violet : Theme.Colors.textTertiary
    }

    private var secondaryColor: Color {
        isActive ? Web3Colors.purple : Theme.Colors.textTertiary.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Connecting lines
            JourneyPathShape(nodeCount: nodeCount, progress: reduceMotion ? 1 : pathProgress)
                .stroke(
                    LinearGradient(
                        colors: [primaryColor.opacity(0.5), secondaryColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 2])
                )

            // Nodes
            ForEach(0..<nodeCount, id: \.self) { index in
                let position = nodePosition(for: index)
                let isNodeActive = reduceMotion ? true : (index <= activeNode)

                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            isNodeActive ? primaryColor : Theme.Colors.textTertiary.opacity(0.3),
                            lineWidth: 1
                        )
                        .frame(width: index == 0 ? 8 : 6, height: index == 0 ? 8 : 6)

                    // Inner fill
                    Circle()
                        .fill(
                            isNodeActive
                                ? LinearGradient(colors: [primaryColor, secondaryColor], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Theme.Colors.textTertiary.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: index == 0 ? 5 : 4, height: index == 0 ? 5 : 4)
                }
                .position(position)
            }

            // Branch indicator
            if isActive {
                BranchIndicator()
                    .stroke(
                        LinearGradient(colors: [primaryColor.opacity(0.6), secondaryColor.opacity(0.4)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1
                    )
                    .frame(width: size * 0.25, height: size * 0.2)
                    .position(x: size * 0.78, y: size * 0.38)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else {
                pathProgress = 1
                activeNode = nodeCount - 1
                return
            }
            animateNodes()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !reduceMotion {
                activeNode = 0
                pathProgress = 0
                animateNodes()
            }
        }
    }

    private func nodePosition(for index: Int) -> CGPoint {
        let positions: [(CGFloat, CGFloat)] = [
            (0.15, 0.7),
            (0.35, 0.45),
            (0.6, 0.55),
            (0.85, 0.3)
        ]
        return CGPoint(x: size * positions[index].0, y: size * positions[index].1)
    }

    private func animateNodes() {
        for i in 0..<nodeCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    activeNode = i
                    pathProgress = CGFloat(i + 1) / CGFloat(nodeCount)
                }
            }
        }
    }
}

// MARK: - Animated Cube Icon (NFTs)

struct AnimatedCubeIcon: View {
    let isActive: Bool
    let size: CGFloat

    @State private var rotation: Double = 0
    @State private var floatOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var primaryColor: Color {
        isActive ? Web3Colors.cyan : Theme.Colors.textTertiary
    }

    private var secondaryColor: Color {
        isActive ? Web3Colors.blue : Theme.Colors.textTertiary.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Back face (shadow)
            HexagonShape()
                .fill(secondaryColor.opacity(0.25))
                .frame(width: size * 0.75, height: size * 0.75)
                .offset(x: 1.5, y: 1.5)

            // Front face
            HexagonShape()
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.75, height: size * 0.75)

            // Inner detail
            HexagonShape()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), primaryColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: size * 0.45, height: size * 0.45)
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0.2, y: 1, z: 0))
        .offset(y: floatOffset)
        .onAppear {
            guard !reduceMotion && isActive else { return }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                rotation = 12
                floatOffset = -1.5
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    rotation = 12
                    floatOffset = -1.5
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    rotation = 0
                    floatOffset = 0
                }
            }
        }
    }
}

// MARK: - Animated Leaderboard Icon

struct AnimatedLeaderboardIcon: View {
    let isActive: Bool
    let size: CGFloat

    @State private var barHeights: [CGFloat] = [0.35, 0.6, 0.45]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let targetHeights: [CGFloat] = [0.45, 0.8, 0.55]

    private var primaryColor: Color {
        isActive ? Web3Colors.orange : Theme.Colors.textTertiary
    }

    private var accentColor: Color {
        isActive ? Web3Colors.coral : Theme.Colors.textTertiary.opacity(0.7)
    }

    private var goldColor: Color {
        isActive ? Web3Colors.gold : Theme.Colors.textTertiary.opacity(0.8)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: size * 0.08) {
            // Left bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    LinearGradient(
                        colors: [primaryColor, accentColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: size * 0.2,
                    height: size * (reduceMotion ? targetHeights[0] : barHeights[0])
                )

            // Center bar (winner)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    LinearGradient(
                        colors: [goldColor, primaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: size * 0.2,
                    height: size * (reduceMotion ? targetHeights[1] : barHeights[1])
                )

            // Right bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    LinearGradient(
                        colors: [accentColor, primaryColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: size * 0.2,
                    height: size * (reduceMotion ? targetHeights[2] : barHeights[2])
                )
        }
        .frame(width: size, height: size, alignment: .bottom)
        .onAppear {
            guard !reduceMotion && isActive else { return }
            animateBars()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue && !reduceMotion {
                animateBars()
            }
        }
    }

    private func animateBars() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            barHeights = targetHeights
        }

        if isActive {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.5)) {
                barHeights = [0.4, 0.85, 0.5]
            }
        }
    }
}

// MARK: - Helper Shapes

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct ChartPath: Shape {
    let points: [CGFloat]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        let stepX = rect.width / CGFloat(points.count - 1)
        let visiblePoints = Int(CGFloat(points.count) * progress)

        for (index, point) in points.prefix(max(1, visiblePoints)).enumerated() {
            let x = CGFloat(index) * stepX + rect.minX
            let y = rect.height - (point * rect.height * 0.7) - rect.height * 0.15

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

private struct JourneyPathShape: Shape {
    let nodeCount: Int
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let positions: [(CGFloat, CGFloat)] = [
            (0.15, 0.7),
            (0.35, 0.45),
            (0.6, 0.55),
            (0.85, 0.3)
        ]

        let visibleNodes = Int(CGFloat(nodeCount) * progress)

        for i in 0..<min(visibleNodes, positions.count - 1) {
            let start = CGPoint(x: rect.width * positions[i].0, y: rect.height * positions[i].1)
            let end = CGPoint(x: rect.width * positions[i + 1].0, y: rect.height * positions[i + 1].1)

            if i == 0 {
                path.move(to: start)
            }
            path.addLine(to: end)
        }

        return path
    }
}

private struct BranchIndicator: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.move(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.7))
        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 32) {
            VStack {
                AnimatedLapsersIcon(isActive: true, size: 24)
                Text("Lapsers").font(.caption)
            }
            VStack {
                AnimatedChartIcon(isActive: true, size: 24)
                Text("Predictions").font(.caption)
            }
            VStack {
                AnimatedPathIcon(isActive: true, size: 24)
                Text("Journeys").font(.caption)
            }
            VStack {
                AnimatedCubeIcon(isActive: true, size: 24)
                Text("NFTs").font(.caption)
            }
            VStack {
                AnimatedLeaderboardIcon(isActive: true, size: 24)
                Text("Leaderboard").font(.caption)
            }
        }

        Divider()

        HStack(spacing: 32) {
            VStack {
                AnimatedLapsersIcon(isActive: false, size: 24)
                Text("Inactive").font(.caption)
            }
            VStack {
                AnimatedChartIcon(isActive: false, size: 24)
                Text("Inactive").font(.caption)
            }
            VStack {
                AnimatedPathIcon(isActive: false, size: 24)
                Text("Inactive").font(.caption)
            }
            VStack {
                AnimatedCubeIcon(isActive: false, size: 24)
                Text("Inactive").font(.caption)
            }
            VStack {
                AnimatedLeaderboardIcon(isActive: false, size: 24)
                Text("Inactive").font(.caption)
            }
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
