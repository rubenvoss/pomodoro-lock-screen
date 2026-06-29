import AppKit
import ApplicationServices
import CoreGraphics
import PomodoroLockScreenCore

private enum PomodoroMode {
    case focus
    case breakTime

    var label: String {
        switch self {
        case .focus:
            return "Focus"
        case .breakTime:
            return "Break"
        }
    }
}

@MainActor
private protocol TimerPopoverViewControllerDelegate: AnyObject {
    func timerPopoverDidToggleRunning(_ controller: TimerPopoverViewController)
    func timerPopoverDidReset(_ controller: TimerPopoverViewController)
    func timerPopoverDidSkip(_ controller: TimerPopoverViewController)
    func timerPopover(
        _ controller: TimerPopoverViewController,
        didApplyFocusMinutes focusMinutes: Int,
        breakMinutes: Int,
        warningFocusRounds: Int
    )
    func timerPopoverDidRequestLock(_ controller: TimerPopoverViewController)
    func timerPopoverDidRequestQuit(_ controller: TimerPopoverViewController)
}

@MainActor
private final class TimerPopoverViewController: NSViewController {
    weak var delegate: TimerPopoverViewControllerDelegate?

    private let modeLabel = NSTextField(labelWithString: "Focus")
    private let timeLabel = NSTextField(labelWithString: "25:00")
    private let toggleButton = NSButton(title: "Start", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset", target: nil, action: nil)
    private let skipButton = NSButton(title: "Skip", target: nil, action: nil)
    private let focusMinutesField = NSTextField(string: "25")
    private let breakMinutesField = NSTextField(string: "5")
    private let warningFocusRoundsField = NSTextField(string: "3")
    private let applyButton = NSButton(title: "Apply", target: nil, action: nil)
    private let lockButton = NSButton(title: "Lock Now", target: nil, action: nil)
    private let quitButton = NSButton(title: "Quit", target: nil, action: nil)

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        modeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        modeLabel.textColor = .secondaryLabelColor
        modeLabel.alignment = .center

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 42, weight: .semibold)
        timeLabel.alignment = .center
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        configure(toggleButton, action: #selector(toggleRunning))
        configure(resetButton, action: #selector(resetTimer))
        configure(skipButton, action: #selector(skipMode))
        configure(applyButton, action: #selector(applyDurations))
        configure(lockButton, action: #selector(lockNow))
        configure(quitButton, action: #selector(quit))
        configureMinuteField(focusMinutesField)
        configureMinuteField(breakMinutesField)
        configureCountField(warningFocusRoundsField)

        let controls = NSStackView(views: [toggleButton, resetButton, skipButton])
        controls.orientation = .horizontal
        controls.distribution = .fillEqually
        controls.spacing = 8

        let durationControls = NSStackView(views: [
            durationField(title: "Focus", field: focusMinutesField),
            durationField(title: "Break", field: breakMinutesField),
            applyButton
        ])
        durationControls.orientation = .horizontal
        durationControls.alignment = .centerY
        durationControls.distribution = .fill
        durationControls.spacing = 8

        let warningControls = NSStackView(views: [
            warningField(title: "Warn after", field: warningFocusRoundsField),
            NSTextField(labelWithString: "focus rounds")
        ])
        warningControls.orientation = .horizontal
        warningControls.alignment = .centerY
        warningControls.distribution = .fill
        warningControls.spacing = 6

        let secondaryControls = NSStackView(views: [lockButton, quitButton])
        secondaryControls.orientation = .horizontal
        secondaryControls.distribution = .fillEqually
        secondaryControls.spacing = 8

        let stack = NSStackView(views: [modeLabel, timeLabel, durationControls, warningControls, controls, secondaryControls])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 280),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            durationControls.widthAnchor.constraint(equalTo: stack.widthAnchor),
            warningControls.widthAnchor.constraint(equalTo: stack.widthAnchor),
            toggleButton.heightAnchor.constraint(equalToConstant: 32),
            resetButton.heightAnchor.constraint(equalTo: toggleButton.heightAnchor),
            skipButton.heightAnchor.constraint(equalTo: toggleButton.heightAnchor),
            applyButton.heightAnchor.constraint(equalToConstant: 28),
            lockButton.heightAnchor.constraint(equalToConstant: 30),
            quitButton.heightAnchor.constraint(equalTo: lockButton.heightAnchor)
        ])
    }

    func update(
        mode: PomodoroMode,
        activityState: FocusActivityState,
        remainingSeconds: Int,
        isRunning: Bool,
        focusMinutes: Int,
        breakMinutes: Int,
        warningFocusRounds: Int,
        currentFocusRound: Int
    ) {
        let stateText: String
        switch mode {
        case .focus:
            stateText = activityState == .active ? "Focus - Active" : "Focus - Paused"
        case .breakTime:
            stateText = activityState == .active ? "Break - Active" : "Break - Paused"
        }

        modeLabel.stringValue = "\(stateText) - Round \(currentFocusRound)/\(warningFocusRounds)"
        timeLabel.stringValue = Self.format(seconds: remainingSeconds)
        toggleButton.title = isRunning ? "Pause" : "Start"

        if focusMinutesField.currentEditor() == nil {
            focusMinutesField.stringValue = "\(focusMinutes)"
        }

        if breakMinutesField.currentEditor() == nil {
            breakMinutesField.stringValue = "\(breakMinutes)"
        }

        if warningFocusRoundsField.currentEditor() == nil {
            warningFocusRoundsField.stringValue = "\(warningFocusRounds)"
        }
    }

    private func configure(_ button: NSButton, action: Selector) {
        button.target = self
        button.action = action
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = .systemFont(ofSize: 13)
    }

    private func configureMinuteField(_ field: NSTextField) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.maximum = 240
        formatter.allowsFloats = false

        field.formatter = formatter
        field.alignment = .center
        field.controlSize = .small
        field.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        field.target = self
        field.action = #selector(applyDurations)
        field.widthAnchor.constraint(equalToConstant: 42).isActive = true
    }

    private func configureCountField(_ field: NSTextField) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 1
        formatter.maximum = 24
        formatter.allowsFloats = false

        field.formatter = formatter
        field.alignment = .center
        field.controlSize = .small
        field.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        field.target = self
        field.action = #selector(applyDurations)
        field.widthAnchor.constraint(equalToConstant: 36).isActive = true
    }

    private func durationField(title: String, field: NSTextField) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [label, field])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 5
        return stack
    }

    private func warningField(title: String, field: NSTextField) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [label, field])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 5
        return stack
    }

    @objc private func toggleRunning() {
        delegate?.timerPopoverDidToggleRunning(self)
    }

    @objc private func resetTimer() {
        delegate?.timerPopoverDidReset(self)
    }

    @objc private func skipMode() {
        delegate?.timerPopoverDidSkip(self)
    }

    @objc private func applyDurations() {
        view.window?.makeFirstResponder(nil)
        delegate?.timerPopover(
            self,
            didApplyFocusMinutes: Self.clampedMinutes(from: focusMinutesField),
            breakMinutes: Self.clampedMinutes(from: breakMinutesField),
            warningFocusRounds: Self.clampedCount(from: warningFocusRoundsField)
        )
    }

    @objc private func lockNow() {
        delegate?.timerPopoverDidRequestLock(self)
    }

    @objc private func quit() {
        delegate?.timerPopoverDidRequestQuit(self)
    }

    private static func format(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    private static func clampedMinutes(from field: NSTextField) -> Int {
        let value = field.integerValue
        return min(max(value, 1), 240)
    }

    private static func clampedCount(from field: NSTextField) -> Int {
        let value = field.integerValue
        return min(max(value, 1), 24)
    }
}

private final class LockScreenRunner {
    private struct Command {
        let path: String
        let arguments: [String]
        let waitForExit: Bool
    }

    static func lockScreen() {
        DispatchQueue.global(qos: .utility).async {
            if sendLockShortcutWhenAllowed() {
                return
            }

            for command in commands {
                if run(command) {
                    return
                }
            }
        }
    }

    private static let commands: [Command] = [
        Command(
            path: "/usr/bin/osascript",
            arguments: [
                "-e",
                "tell application \"System Events\" to key code 12 using {control down, command down}"
            ],
            waitForExit: true
        ),
        Command(path: "/usr/bin/pmset", arguments: ["displaysleepnow"], waitForExit: true),
        Command(
            path: "/System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine",
            arguments: [],
            waitForExit: false
        )
    ]

    private static func sendLockShortcutWhenAllowed() -> Bool {
        guard AXIsProcessTrusted() else {
            return false
        }

        guard
            let source = CGEventSource(stateID: .hidSystemState),
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x0C, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x0C, keyDown: false)
        else {
            return false
        }

        keyDown.flags = [.maskControl, .maskCommand]
        keyUp.flags = [.maskControl, .maskCommand]
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private static func run(_ command: Command) -> Bool {
        guard FileManager.default.isExecutableFile(atPath: command.path) else {
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.path)
        process.arguments = command.arguments

        do {
            try process.run()
            guard command.waitForExit else {
                return true
            }

            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

private final class CompletionSoundRunner {
    private struct Command {
        let path: String
        let arguments: [String]
    }

    static func play() {
        DispatchQueue.global(qos: .userInitiated).async {
            var playedEffect = false

            if run(Command(path: "/usr/bin/afplay", arguments: ["/System/Library/Sounds/Funk.aiff"])) {
                playedEffect = true
            }

            if !playedEffect {
                NSSound.beep()
            }
        }
    }

    private static func run(_ command: Command) -> Bool {
        guard FileManager.default.isExecutableFile(atPath: command.path) else {
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: command.path)
        process.arguments = command.arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

@MainActor
private final class InputActivityMonitor {
    private let activeThreshold: TimeInterval
    private let movementThreshold: CGFloat = 1
    private var lastInputAt: Date
    private var lastMouseLocation: NSPoint
    private var monitorTokens: [Any] = []

    init(activeThreshold: TimeInterval = 10) {
        self.activeThreshold = activeThreshold
        self.lastInputAt = Date()
        self.lastMouseLocation = NSEvent.mouseLocation
    }

    func start() {
        guard monitorTokens.isEmpty else {
            return
        }

        let mask: NSEvent.EventTypeMask = [
            .mouseMoved,
            .leftMouseDown,
            .leftMouseUp,
            .leftMouseDragged,
            .rightMouseDown,
            .rightMouseUp,
            .rightMouseDragged,
            .otherMouseDown,
            .otherMouseUp,
            .otherMouseDragged,
            .scrollWheel,
            .keyDown,
            .flagsChanged
        ]

        if let localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            Task { @MainActor in
                self?.registerInput(event: event)
            }
            return event
        }) {
            monitorTokens.append(localMonitor)
        }

        if let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            Task { @MainActor in
                self?.registerInput(event: event)
            }
        }) {
            monitorTokens.append(globalMonitor)
        }
    }

    func isActive(now: Date = Date()) -> Bool {
        refreshMousePosition()
        return now.timeIntervalSince(lastInputAt) <= activeThreshold
    }

    func idleSeconds(now: Date = Date()) -> Int {
        refreshMousePosition()
        return max(0, Int(now.timeIntervalSince(lastInputAt).rounded(.down)))
    }

    func refreshMousePosition() {
        let location = NSEvent.mouseLocation

        guard location.distance(to: lastMouseLocation) >= movementThreshold else {
            return
        }

        lastMouseLocation = location
        lastInputAt = Date()
    }

    private func registerInput(event: NSEvent) {
        switch event.type {
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            refreshMousePosition()
        default:
            lastMouseLocation = NSEvent.mouseLocation
            lastInputAt = Date()
        }
    }
}

private extension NSPoint {
    func distance(to other: NSPoint) -> CGFloat {
        let horizontal = x - other.x
        let vertical = y - other.y
        return sqrt(horizontal * horizontal + vertical * vertical)
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate, TimerPopoverViewControllerDelegate {
    private var focusDuration = 25 * 60
    private var breakDuration = 5 * 60
    private var longWorkWarningFocusRounds = 3
    private var roundWarningTracker = RoundWarningTracker()
    private let activityMonitor = InputActivityMonitor()
    private var focusTimer = ActivityGatedTimerPolicy(focusDurationSeconds: 25 * 60)

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let popoverController = TimerPopoverViewController()
    private var timer: Timer?
    private var mode: PomodoroMode = .focus
    private var breakRemainingSeconds = 5 * 60
    private var breakActivityState: FocusActivityState = .active
    private var isRunning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        popover.behavior = .transient
        popover.contentViewController = popoverController
        popoverController.delegate = self

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover)
        statusItem = item

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sessionDidBecomeActive),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )

        activityMonitor.start()
        updateDisplay()
        start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func timerPopoverDidToggleRunning(_ controller: TimerPopoverViewController) {
        isRunning ? pause() : start()
    }

    func timerPopoverDidReset(_ controller: TimerPopoverViewController) {
        resetCurrentMode()
    }

    func timerPopoverDidSkip(_ controller: TimerPopoverViewController) {
        advanceMode(lockOnFocusCompletion: false, continueRunning: false)
    }

    func timerPopover(
        _ controller: TimerPopoverViewController,
        didApplyFocusMinutes focusMinutes: Int,
        breakMinutes: Int,
        warningFocusRounds: Int
    ) {
        let previousFocusDuration = focusDuration
        let previousBreakDuration = breakDuration
        focusDuration = focusMinutes * 60
        breakDuration = breakMinutes * 60
        longWorkWarningFocusRounds = warningFocusRounds
        roundWarningTracker.resetIfNewDay()
        roundWarningTracker.clamp(threshold: longWorkWarningFocusRounds)

        if mode == .focus {
            focusTimer.applyDuration(
                focusDurationSeconds: focusDuration,
                resetFocus: !isRunning || previousFocusDuration != focusDuration
            )
        }

        if mode == .breakTime && (!isRunning || previousBreakDuration != breakDuration) {
            breakRemainingSeconds = breakDuration
        }

        updateDisplay()
    }

    func timerPopoverDidRequestLock(_ controller: TimerPopoverViewController) {
        LockScreenRunner.lockScreen()
    }

    func timerPopoverDidRequestQuit(_ controller: TimerPopoverViewController) {
        NSApp.terminate(nil)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            updateDisplay()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func sessionDidBecomeActive(_ notification: Notification) {
        updateDisplay()
    }

    private func start() {
        guard !isRunning else {
            return
        }

        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
        updateDisplay()
    }

    @objc private func timerFired(_ timer: Timer) {
        switch mode {
        case .focus:
            tickFocus()
        case .breakTime:
            tickBreak()
        }
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateDisplay()
    }

    private func tickFocus() {
        let action = focusTimer.tick(inputIsActive: activityMonitor.isActive())

        switch action {
        case .none:
            updateDisplay()
        case .focusExpired:
            advanceMode(lockOnFocusCompletion: true, continueRunning: true)
        }
    }

    private func tickBreak() {
        guard activityMonitor.isActive() else {
            breakActivityState = .paused
            updateDisplay()
            return
        }

        breakActivityState = .active
        breakRemainingSeconds -= 1

        if breakRemainingSeconds <= 0 {
            advanceMode(lockOnFocusCompletion: false, continueRunning: true)
        } else {
            updateDisplay()
        }
    }

    private func resetCurrentMode() {
        pause()

        switch mode {
        case .focus:
            focusTimer.resetFocus(durationSeconds: focusDuration)
        case .breakTime:
            breakRemainingSeconds = breakDuration
            breakActivityState = .active
        }

        updateDisplay()
    }

    private func advanceMode(lockOnFocusCompletion: Bool, continueRunning: Bool) {
        let completedMode = mode
        let shouldShowLongWorkWarning = completedMode == .focus
            && lockOnFocusCompletion
            && registerCompletedFocusRoundIfNeeded()

        timer?.invalidate()
        timer = nil

        switch mode {
        case .focus:
            mode = .breakTime
            breakRemainingSeconds = breakDuration
            breakActivityState = .active
        case .breakTime:
            mode = .focus
            focusTimer.resetFocus(durationSeconds: focusDuration)
        }

        isRunning = false
        CompletionSoundRunner.play()

        if shouldShowLongWorkWarning {
            showLongWorkWarning()
        }

        if completedMode == .focus && lockOnFocusCompletion {
            LockScreenRunner.lockScreen()
        }

        if continueRunning {
            start()
        } else {
            updateDisplay()
        }
    }

    private func registerCompletedFocusRoundIfNeeded() -> Bool {
        roundWarningTracker.registerCompletedRound(threshold: longWorkWarningFocusRounds)
    }

    private func showLongWorkWarning() {
        if popover.isShown {
            popover.performClose(nil)
        }

        let focusedMinutes = (focusDuration / 60) * longWorkWarningFocusRounds
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Long work session"
        alert.informativeText = "You have completed \(longWorkWarningFocusRounds) focus rounds, about \(focusedMinutes) minutes of focused work. Take a longer break before continuing."
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    private func updateDisplay() {
        roundWarningTracker.resetIfNewDay()

        let remainingSeconds = displayedRemainingSeconds
        let timeText = format(seconds: remainingSeconds)
        let roundText = "\(roundWarningTracker.currentRoundNumber)/\(longWorkWarningFocusRounds)"
        let stateText = displayStateText
        let idleText = "idle \(activityMonitor.idleSeconds())s"
        statusItem?.button?.title = "\(timeText) \(roundText)"
        statusItem?.button?.toolTip = "Pomodoro - \(stateText) - \(timeText) - Round \(roundText) - \(idleText)"
        popoverController.update(
            mode: mode,
            activityState: displayedActivityState,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            focusMinutes: focusDuration / 60,
            breakMinutes: breakDuration / 60,
            warningFocusRounds: longWorkWarningFocusRounds,
            currentFocusRound: roundWarningTracker.currentRoundNumber
        )
    }

    private var displayedRemainingSeconds: Int {
        switch mode {
        case .focus:
            return focusTimer.displayedRemainingSeconds
        case .breakTime:
            return breakRemainingSeconds
        }
    }

    private var displayStateText: String {
        switch mode {
        case .focus:
            return focusTimer.activityState == .active ? "Focus - Active" : "Focus - Paused"
        case .breakTime:
            return breakActivityState == .active ? "Break - Active" : "Break - Paused"
        }
    }

    private var displayedActivityState: FocusActivityState {
        switch mode {
        case .focus:
            return focusTimer.activityState
        case .breakTime:
            return breakActivityState
        }
    }

    private func format(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }
}

@MainActor
private func runApp() {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

runApp()
