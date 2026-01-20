import Foundation

// MARK: - Time Capsule

/// A message written to your future self, unlocked at a specific epoch or date
struct TimeCapsule: Identifiable, Codable, Sendable {
    let id: String
    let authorId: String
    let content: String
    let createdAt: Date
    let unlockCondition: UnlockCondition
    var isUnlocked: Bool
    var unlockedAt: Date?
    var title: String?
    var associatedEpochId: UInt64?

    var canUnlock: Bool {
        guard !isUnlocked else { return false }
        switch unlockCondition {
        case .epoch: return false
        case .date(let date): return Date() >= date
        }
    }

    var timeUntilUnlock: TimeInterval? {
        guard !isUnlocked else { return nil }
        switch unlockCondition {
        case .epoch: return nil
        case .date(let date):
            let remaining = date.timeIntervalSince(Date())
            return remaining > 0 ? remaining : nil
        }
    }

    var unlockDescription: String {
        switch unlockCondition {
        case .epoch(let id): return "Unlocks at epoch #\(id)"
        case .date(let date):
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return "Unlocks \(f.string(from: date))"
        }
    }

    var status: CapsuleStatus {
        if isUnlocked { return .unlocked }
        else if canUnlock { return .unlockable }
        else { return .locked }
    }
}

enum UnlockCondition: Codable, Sendable, Equatable {
    case epoch(UInt64)
    case date(Date)
}

enum CapsuleStatus: String { case locked, unlockable, unlocked }

extension TimeCapsule {
    static func forEpoch(authorId: String, content: String, epochId: UInt64, title: String? = nil) -> TimeCapsule {
        TimeCapsule(id: UUID().uuidString, authorId: authorId, content: content, createdAt: Date(),
                    unlockCondition: .epoch(epochId), isUnlocked: false, title: title, associatedEpochId: epochId)
    }

    static func forDate(authorId: String, content: String, unlockDate: Date, title: String? = nil) -> TimeCapsule {
        TimeCapsule(id: UUID().uuidString, authorId: authorId, content: content, createdAt: Date(),
                    unlockCondition: .date(unlockDate), isUnlocked: false, title: title)
    }

    static func mock(isUnlocked: Bool = false) -> TimeCapsule {
        TimeCapsule(id: UUID().uuidString, authorId: "mock", content: "Remember this moment.",
                    createdAt: Date().addingTimeInterval(-86400), unlockCondition: .date(Date().addingTimeInterval(3600)),
                    isUnlocked: isUnlocked, unlockedAt: isUnlocked ? Date() : nil, title: "Past message", associatedEpochId: 1)
    }
}
