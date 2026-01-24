//
//  UrgencyBadge.swift
//  lapses
//
//  Time-based urgency indicator badge
//

import SwiftUI
import Combine

// MARK: - Urgency Badge

struct UrgencyBadge: View {
    let urgency: UrgencyLevel
    let timeRemaining: String?

    @State private var isPulsing = false

    var body: some View {
        if urgency != .none && urgency != .normal {
            HStack(spacing: 4) {
                if urgency.shouldPulse {
                    Circle()
                        .fill(urgency.color)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0.7 : 1.0)
                }

                if let time = timeRemaining {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .medium))

                    Text(time)
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(urgency.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(urgency.color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(urgency.color.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                if urgency.shouldPulse {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
        }
    }
}

// MARK: - Countdown Badge

struct CountdownBadge: View {
    let expiresAt: Date?
    @State private var timeRemaining: String = ""
    @State private var urgency: UrgencyLevel = .normal

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        UrgencyBadge(urgency: urgency, timeRemaining: timeRemaining)
            .onAppear {
                updateTime()
            }
            .onReceive(timer) { _ in
                updateTime()
            }
    }

    private func updateTime() {
        guard let expiresAt else {
            timeRemaining = ""
            urgency = .none
            return
        }

        let remaining = expiresAt.timeIntervalSinceNow

        guard remaining > 0 else {
            timeRemaining = "Expired"
            urgency = .critical
            return
        }

        // Update urgency
        if remaining < 300 {         // < 5 min
            urgency = .critical
        } else if remaining < 900 {  // < 15 min
            urgency = .high
        } else if remaining < 3600 { // < 1 hour
            urgency = .moderate
        } else {
            urgency = .normal
        }

        // Format time
        if remaining < 60 {
            timeRemaining = "\(Int(remaining))s"
        } else if remaining < 3600 {
            let minutes = Int(remaining / 60)
            let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))
            timeRemaining = String(format: "%d:%02d", minutes, seconds)
        } else {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            timeRemaining = String(format: "%dh %dm", hours, minutes)
        }
    }
}

// MARK: - Hot Badge

struct HotBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .bold))

            Text("Hot")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Different urgency levels
        UrgencyBadge(urgency: .normal, timeRemaining: "2h 45m")
        UrgencyBadge(urgency: .moderate, timeRemaining: "45:23")
        UrgencyBadge(urgency: .high, timeRemaining: "12:34")
        UrgencyBadge(urgency: .critical, timeRemaining: "2:15")

        Divider()

        // Countdown badge with live updates
        CountdownBadge(expiresAt: Date().addingTimeInterval(180))
        CountdownBadge(expiresAt: Date().addingTimeInterval(3600))

        Divider()

        // Hot badge
        HotBadge()
    }
    .padding()
    .background(Theme.Colors.background)
}
