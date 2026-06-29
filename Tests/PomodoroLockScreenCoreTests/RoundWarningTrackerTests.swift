import Foundation
import Testing
@testable import PomodoroLockScreenCore

@Suite
struct RoundWarningTrackerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        return calendar
    }()

    @Test
    func warnsAfterThresholdOnSameDay() {
        let morning = date(year: 2026, month: 6, day: 23, hour: 9)
        var tracker = RoundWarningTracker(calendar: calendar)

        #expect(tracker.registerCompletedRound(threshold: 3, now: morning) == false)
        #expect(tracker.currentRoundNumber == 2)
        #expect(tracker.registerCompletedRound(threshold: 3, now: morning.addingTimeInterval(30 * 60)) == false)
        #expect(tracker.currentRoundNumber == 3)
        #expect(tracker.registerCompletedRound(threshold: 3, now: morning.addingTimeInterval(60 * 60)) == true)
        #expect(tracker.currentRoundNumber == 1)
    }

    @Test
    func startsFreshOnNewLocalDay() {
        let lateNight = date(year: 2026, month: 6, day: 22, hour: 23)
        let morning = date(year: 2026, month: 6, day: 23, hour: 8)
        var tracker = RoundWarningTracker(completedRoundsSinceWarning: 2, lastCompletedRoundAt: lateNight, calendar: calendar)

        #expect(tracker.registerCompletedRound(threshold: 3, now: morning) == false)
        #expect(tracker.currentRoundNumber == 2)
    }

    @Test
    func explicitNewDayResetClearsProgress() {
        let yesterday = date(year: 2026, month: 6, day: 22, hour: 17)
        let today = date(year: 2026, month: 6, day: 23, hour: 7)
        var tracker = RoundWarningTracker(completedRoundsSinceWarning: 2, lastCompletedRoundAt: yesterday, calendar: calendar)

        tracker.resetIfNewDay(now: today)

        #expect(tracker.currentRoundNumber == 1)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date!
    }
}
