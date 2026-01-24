//
//  PredictionCard.swift
//  lapses
//
//  Card component for prediction markets
//

import SwiftUI

// MARK: - Prediction Card

struct PredictionCard: View {
    let market: PredictionMarket
    let hasVoted: Bool
    let userVote: PredictionSide?
    let onVote: (PredictionSide) -> Void
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with epoch info and urgency
            header

            // Question
            Text(market.question)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(2)

            // Vote buttons
            VoteButtons(
                yesPercentage: market.yesPercentage,
                noPercentage: market.noPercentage,
                yesPool: formatPool(market.yesPool),
                noPool: formatPool(market.noPool),
                hasVoted: hasVoted,
                userVote: userVote,
                onVote: onVote
            )

            // Footer with pool info
            footer
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .strokeBorder(
                    urgencyBorderColor,
                    lineWidth: market.urgencyLevel == .critical ? 2 : 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Prediction type icon
                HStack(spacing: 6) {
                    Image(systemName: market.predictionType.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    Text(market.epochTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Urgency badge
            if market.isActive {
                CountdownBadge(expiresAt: market.endTime)
            } else if market.isResolved {
                resolvedBadge
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            // Total pool
            HStack(spacing: 4) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 12))
                Text("Pool: \(market.formattedPool)")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Theme.Colors.textTertiary)

            Spacer()

            // Total voters
            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12))
                Text("\(market.totalVoters) traders")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    // MARK: - Resolved Badge

    private var resolvedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: market.outcome == .yes ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 12, weight: .bold))

            Text(market.outcome == .yes ? "YES" : "NO")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(market.outcome == .yes ? Color.green : Color.red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((market.outcome == .yes ? Color.green : Color.red).opacity(0.15))
        )
    }

    // MARK: - Helpers

    private var urgencyBorderColor: Color {
        switch market.urgencyLevel {
        case .none, .normal:
            return Theme.Colors.textTertiary.opacity(0.2)
        case .moderate:
            return Color.orange.opacity(0.5)
        case .high:
            return Color.red.opacity(0.5)
        case .critical:
            return Color.red
        }
    }

    private func formatPool(_ amount: Double) -> String {
        if amount >= 1.0 {
            return String(format: "%.2f ETH", amount)
        } else {
            return String(format: "%.3f ETH", amount)
        }
    }
}

// MARK: - Compact Prediction Card

struct CompactPredictionCard: View {
    let market: PredictionMarket
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: market.predictionType.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Theme.Colors.primaryFallback)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Theme.Colors.primaryFallback.opacity(0.1))
                    )

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(market.question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("Yes: \(Int(market.yesPercentage))%")
                            .foregroundStyle(.green)

                        Text("No: \(Int(market.noPercentage))%")
                            .foregroundStyle(.red)

                        Text(market.formattedPool)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .font(.system(size: 12, weight: .medium))
                }

                Spacer()

                // Vote indicator or chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(Theme.Colors.surfaceElevated)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(PredictionMarket.mockMarkets()) { market in
                PredictionCard(
                    market: market,
                    hasVoted: market.id == "market-5",
                    userVote: market.id == "market-5" ? .yes : nil,
                    onVote: { side in
                        print("Voted \(side) on \(market.id)")
                    },
                    onTap: {
                        print("Tapped \(market.id)")
                    }
                )
            }

            Divider()

            Text("Compact Cards")
                .font(.headline)

            ForEach(PredictionMarket.mockMarkets().prefix(3)) { market in
                CompactPredictionCard(market: market) {
                    print("Tapped compact \(market.id)")
                }
            }
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
