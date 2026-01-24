//
//  AnimatedSparkline.swift
//  lapses
//
//  Animated sparkline chart for token price visualization
//

import SwiftUI

// MARK: - Animated Sparkline

struct AnimatedSparkline: View {
    let data: [Double]
    let isPositive: Bool
    let width: CGFloat
    let height: CGFloat

    @State private var progress: CGFloat = 0
    @State private var dotScale: CGFloat = 0
    @State private var dotPulse: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var color: Color {
        isPositive ? .green : .red
    }

    var body: some View {
        ZStack {
            // Gradient fill under the line
            SparklineFillShape(data: data, progress: reduceMotion ? 1 : progress)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Main line
            SparklineShape(data: data, progress: reduceMotion ? 1 : progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )

            // End dot
            if progress > 0.9 || reduceMotion {
                endDot
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            guard !reduceMotion else {
                progress = 1
                dotScale = 1
                return
            }
            withAnimation(.easeOut(duration: 0.8)) {
                progress = 1
            }
            withAnimation(.spring(response: 0.4).delay(0.7)) {
                dotScale = 1
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true).delay(1)) {
                dotPulse = 1.5
            }
        }
    }

    private var endDot: some View {
        let lastPoint = calculateLastPoint()

        return ZStack {
            // Pulse ring
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 1.5)
                .frame(width: 8, height: 8)
                .scaleEffect(dotPulse)
                .opacity(2 - dotPulse)

            // Solid dot
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .scaleEffect(dotScale)
        }
        .position(lastPoint)
    }

    private func calculateLastPoint() -> CGPoint {
        guard let lastValue = data.last, !data.isEmpty else {
            return CGPoint(x: width, y: height / 2)
        }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 100
        let range = maxValue - minValue
        let normalizedY = range > 0 ? (lastValue - minValue) / range : 0.5

        let padding: CGFloat = 4
        let x = width - padding
        let y = height - (CGFloat(normalizedY) * (height - padding * 2)) - padding

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Sparkline Shape

private struct SparklineShape: Shape {
    let data: [Double]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 100
        let range = maxValue - minValue

        let padding: CGFloat = 4
        let drawWidth = rect.width - padding * 2
        let drawHeight = rect.height - padding * 2
        let stepX = drawWidth / CGFloat(data.count - 1)

        let visibleCount = Int(CGFloat(data.count) * progress)
        guard visibleCount > 0 else { return path }

        let points = data.prefix(visibleCount).enumerated().map { index, value -> CGPoint in
            let normalizedY = range > 0 ? (value - minValue) / range : 0.5
            let x = padding + CGFloat(index) * stepX
            let y = rect.height - padding - CGFloat(normalizedY) * drawHeight
            return CGPoint(x: x, y: y)
        }

        guard let first = points.first else { return path }
        path.move(to: first)

        // Use quadratic bezier curves for smooth line
        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]
            let midX = (previous.x + current.x) / 2

            path.addQuadCurve(
                to: current,
                control: CGPoint(x: midX, y: previous.y)
            )
        }

        return path
    }
}

// MARK: - Sparkline Fill Shape

private struct SparklineFillShape: Shape {
    let data: [Double]
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 100
        let range = maxValue - minValue

        let padding: CGFloat = 4
        let drawWidth = rect.width - padding * 2
        let drawHeight = rect.height - padding * 2
        let stepX = drawWidth / CGFloat(data.count - 1)

        let visibleCount = Int(CGFloat(data.count) * progress)
        guard visibleCount > 0 else { return path }

        let points = data.prefix(visibleCount).enumerated().map { index, value -> CGPoint in
            let normalizedY = range > 0 ? (value - minValue) / range : 0.5
            let x = padding + CGFloat(index) * stepX
            let y = rect.height - padding - CGFloat(normalizedY) * drawHeight
            return CGPoint(x: x, y: y)
        }

        guard let first = points.first, let last = points.last else { return path }

        // Start at bottom left
        path.move(to: CGPoint(x: first.x, y: rect.height))
        path.addLine(to: first)

        // Draw curve through points
        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]
            let midX = (previous.x + current.x) / 2

            path.addQuadCurve(
                to: current,
                control: CGPoint(x: midX, y: previous.y)
            )
        }

        // Close to bottom right and back
        path.addLine(to: CGPoint(x: last.x, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AnimatedSparkline(
                data: [30, 35, 32, 45, 42, 55, 48, 62, 58, 75, 70, 85],
                isPositive: true,
                width: 100,
                height: 40
            )

            AnimatedSparkline(
                data: [80, 75, 78, 65, 70, 55, 60, 45, 50, 35, 40, 30],
                isPositive: false,
                width: 100,
                height: 40
            )
        }

        AnimatedSparkline(
            data: [50, 52, 48, 55, 45, 60, 55, 70, 65, 80, 75, 90, 85, 95],
            isPositive: true,
            width: 200,
            height: 60
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
