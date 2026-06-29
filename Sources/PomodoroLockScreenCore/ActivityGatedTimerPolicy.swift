import Foundation

public enum FocusActivityState: Equatable {
    case active
    case paused
}

public enum ActivityGatedTimerAction: Equatable {
    case none
    case focusExpired
}

public struct ActivityGatedTimerPolicy {
    public private(set) var focusRemainingSeconds: Int
    public private(set) var activityState: FocusActivityState

    public init(
        focusDurationSeconds: Int,
        activityState: FocusActivityState = .active
    ) {
        focusRemainingSeconds = max(1, focusDurationSeconds)
        self.activityState = activityState
    }

    public init(
        focusRemainingSeconds: Int,
        activityState: FocusActivityState = .active
    ) {
        self.focusRemainingSeconds = max(0, focusRemainingSeconds)
        self.activityState = activityState
    }

    public var displayedRemainingSeconds: Int {
        focusRemainingSeconds
    }

    public mutating func tick(inputIsActive: Bool, elapsedSeconds: Int = 1) -> ActivityGatedTimerAction {
        guard inputIsActive else {
            activityState = .paused
            return .none
        }

        activityState = .active
        focusRemainingSeconds = max(0, focusRemainingSeconds - max(1, elapsedSeconds))

        return focusRemainingSeconds == 0 ? .focusExpired : .none
    }

    public mutating func resetFocus(durationSeconds: Int) {
        focusRemainingSeconds = max(1, durationSeconds)
        activityState = .active
    }

    public mutating func applyDuration(focusDurationSeconds: Int, resetFocus: Bool) {
        let focusDurationSeconds = max(1, focusDurationSeconds)

        if resetFocus {
            focusRemainingSeconds = focusDurationSeconds
            activityState = .active
        } else {
            focusRemainingSeconds = min(focusRemainingSeconds, focusDurationSeconds)
        }
    }
}
