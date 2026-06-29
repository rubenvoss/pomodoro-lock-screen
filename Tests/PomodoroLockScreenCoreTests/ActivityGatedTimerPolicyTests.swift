import Testing
@testable import PomodoroLockScreenCore

@Suite
struct ActivityGatedTimerPolicyTests {
    @Test
    func activeInputDecrementsFocusTimer() {
        var policy = ActivityGatedTimerPolicy(focusRemainingSeconds: 10)

        let action = policy.tick(inputIsActive: true)

        #expect(action == .none)
        #expect(policy.activityState == .active)
        #expect(policy.focusRemainingSeconds == 9)
        #expect(policy.displayedRemainingSeconds == 9)
    }

    @Test
    func idleInputPausesFocusTimer() {
        var policy = ActivityGatedTimerPolicy(focusRemainingSeconds: 10)

        let action = policy.tick(inputIsActive: false, elapsedSeconds: 30)

        #expect(action == .none)
        #expect(policy.activityState == .paused)
        #expect(policy.focusRemainingSeconds == 10)
        #expect(policy.displayedRemainingSeconds == 10)
    }

    @Test
    func activeInputAfterPauseContinuesFromSameRemainingTime() {
        var policy = ActivityGatedTimerPolicy(focusRemainingSeconds: 10)

        _ = policy.tick(inputIsActive: false, elapsedSeconds: 30)
        let action = policy.tick(inputIsActive: true)

        #expect(action == .none)
        #expect(policy.activityState == .active)
        #expect(policy.focusRemainingSeconds == 9)
    }

    @Test
    func focusTimerExpiryRequestsFocusExpirationAction() {
        var policy = ActivityGatedTimerPolicy(focusRemainingSeconds: 1)

        let action = policy.tick(inputIsActive: true)

        #expect(action == .focusExpired)
        #expect(policy.focusRemainingSeconds == 0)
    }
}
