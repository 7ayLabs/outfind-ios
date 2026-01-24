//
//  VoteProgressBar.swift
//  lapses
//
//  Yes/No vote progress bar for predictions
//

import SwiftUI

// MARK: - Vote Progress Bar

struct VoteProgressBar: View {
    let yesPercentage: Double
    let noPercentage: Double
    let yesLabel: String
    let noLabel: String
    let animated: Bool

    @State private var animatedYesPercentage: Double = 50
    @State private var animatedNoPercentage: Double = 50

    init(
        yesPercentage: Double,
        noPercentage: Double,
        yesLabel: String = "Yes",
        noLabel: String = "No",
        animated: Bool = true
    ) {
        self.yesPercentage = yesPercentage
        self.noPercentage = noPercentage
        self.yesLabel = yesLabel
        self.noLabel = noLabel
        self.animated = animated
    }

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let yesWidth = totalWidth * (animatedYesPercentage / 100)
            let noWidth = totalWidth * (animatedNoPercentage / 100)

            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.2))

                // Yes portion
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.8))
                    .frame(width: max(0, yesWidth))

                // Labels
                HStack {
                    // Yes side
                    VStack(alignment: .leading, spacing: 2) {
                        Text(yesLabel)
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%.0f%%", animatedYesPercentage))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.leading, 8)

                    Spacer()

                    // No side
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(noLabel)
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%.0f%%", animatedNoPercentage))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.trailing, 8)
                }
            }
        }
        .frame(height: 36)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animatedYesPercentage = yesPercentage
                    animatedNoPercentage = noPercentage
                }
            } else {
                animatedYesPercentage = yesPercentage
                animatedNoPercentage = noPercentage
            }
        }
        .onChange(of: yesPercentage) { _, newValue in
            if animated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animatedYesPercentage = newValue
                }
            } else {
                animatedYesPercentage = newValue
            }
        }
        .onChange(of: noPercentage) { _, newValue in
            if animated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animatedNoPercentage = newValue
                }
            } else {
                animatedNoPercentage = newValue
            }
        }
    }
}

// MARK: - Vote Buttons

struct VoteButtons: View {
    let yesPercentage: Double
    let noPercentage: Double
    let yesPool: String
    let noPool: String
    let hasVoted: Bool
    let userVote: PredictionSide?
    let onVote: (PredictionSide) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Yes button
            voteButton(
                side: .yes,
                percentage: yesPercentage,
                pool: yesPool,
                isSelected: userVote == .yes
            )

            // No button
            voteButton(
                side: .no,
                percentage: noPercentage,
                pool: noPool,
                isSelected: userVote == .no
            )
        }
    }

    private func voteButton(
        side: PredictionSide,
        percentage: Double,
        pool: String,
        isSelected: Bool
    ) -> some View {
        let isYes = side == .yes
        let baseColor = isYes ? Color.green : Color.red

        return Button {
            if !hasVoted {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onVote(side)
            }
        } label: {
            VStack(spacing: 4) {
                Text(isYes ? "YES" : "NO")
                    .font(.system(size: 14, weight: .bold))

                Text(String(format: "%.0f%%", percentage))
                    .font(.system(size: 18, weight: .bold))

                Text(pool)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? baseColor.opacity(0.2) : Theme.Colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .strokeBorder(
                        isSelected ? baseColor : Theme.Colors.textTertiary.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .foregroundStyle(isSelected ? baseColor : Theme.Colors.textPrimary)
        }
        .buttonStyle(.plain)
        .disabled(hasVoted)
        .opacity(hasVoted && !isSelected ? 0.5 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        VoteProgressBar(
            yesPercentage: 62,
            noPercentage: 38
        )

        VoteProgressBar(
            yesPercentage: 80,
            noPercentage: 20
        )

        VoteProgressBar(
            yesPercentage: 35,
            noPercentage: 65
        )

        Divider()

        VoteButtons(
            yesPercentage: 62,
            noPercentage: 38,
            yesPool: "1.3 ETH",
            noPool: "0.8 ETH",
            hasVoted: false,
            userVote: nil
        ) { side in
            print("Voted: \(side)")
        }

        VoteButtons(
            yesPercentage: 70,
            noPercentage: 30,
            yesPool: "2.1 ETH",
            noPool: "0.9 ETH",
            hasVoted: true,
            userVote: .yes
        ) { _ in }
    }
    .padding()
    .background(Theme.Colors.background)
}
