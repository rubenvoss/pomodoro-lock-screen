import Foundation

public struct RoundWarningTracker {
    public private(set) var completedRoundsSinceWarning: Int
    public private(set) var lastCompletedRoundAt: Date?

    private var calendar: Calendar

    public init(
        completedRoundsSinceWarning: Int = 0,
        lastCompletedRoundAt: Date? = nil,
        calendar: Calendar = .current
    ) {
        self.completedRoundsSinceWarning = completedRoundsSinceWarning
        self.lastCompletedRoundAt = lastCompletedRoundAt
        self.calendar = calendar
    }

    public var currentRoundNumber: Int {
        completedRoundsSinceWarning + 1
    }

    public mutating func clamp(threshold: Int) {
        completedRoundsSinceWarning = min(completedRoundsSinceWarning, max(1, threshold) - 1)
    }

    public mutating func resetIfNewDay(now: Date = Date()) {
        guard let lastCompletedRoundAt else {
            return
        }

        if !calendar.isDate(lastCompletedRoundAt, inSameDayAs: now) {
            completedRoundsSinceWarning = 0
            self.lastCompletedRoundAt = nil
        }
    }

    public mutating func registerCompletedRound(threshold: Int, now: Date = Date()) -> Bool {
        resetIfNewDay(now: now)

        completedRoundsSinceWarning += 1
        lastCompletedRoundAt = now

        guard completedRoundsSinceWarning >= max(1, threshold) else {
            return false
        }

        completedRoundsSinceWarning = 0
        return true
    }
}
