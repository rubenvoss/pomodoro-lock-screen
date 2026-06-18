import AppKit
import ApplicationServices
import CoreGraphics

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
    func timerPopover(_ controller: TimerPopoverViewController, didApplyFocusMinutes focusMinutes: Int, breakMinutes: Int)
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

        let secondaryControls = NSStackView(views: [lockButton, quitButton])
        secondaryControls.orientation = .horizontal
        secondaryControls.distribution = .fillEqually
        secondaryControls.spacing = 8

        let stack = NSStackView(views: [modeLabel, timeLabel, durationControls, controls, secondaryControls])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 240),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            durationControls.widthAnchor.constraint(equalTo: stack.widthAnchor),
            toggleButton.heightAnchor.constraint(equalToConstant: 32),
            resetButton.heightAnchor.constraint(equalTo: toggleButton.heightAnchor),
            skipButton.heightAnchor.constraint(equalTo: toggleButton.heightAnchor),
            applyButton.heightAnchor.constraint(equalToConstant: 28),
            lockButton.heightAnchor.constraint(equalToConstant: 30),
            quitButton.heightAnchor.constraint(equalTo: lockButton.heightAnchor)
        ])
    }

    func update(mode: PomodoroMode, remainingSeconds: Int, isRunning: Bool, focusMinutes: Int, breakMinutes: Int) {
        modeLabel.stringValue = mode.label
        timeLabel.stringValue = Self.format(seconds: remainingSeconds)
        toggleButton.title = isRunning ? "Pause" : "Start"

        if focusMinutesField.currentEditor() == nil {
            focusMinutesField.stringValue = "\(focusMinutes)"
        }

        if breakMinutesField.currentEditor() == nil {
            breakMinutesField.stringValue = "\(breakMinutes)"
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
            breakMinutes: Self.clampedMinutes(from: breakMinutesField)
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

            if run(Command(path: "/usr/bin/say", arguments: ["bruh"])) {
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
private final class AppDelegate: NSObject, NSApplicationDelegate, TimerPopoverViewControllerDelegate {
    private let chromeBundleIdentifier = "com.google.Chrome"
    private var focusDuration = 25 * 60
    private var breakDuration = 5 * 60

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private let popoverController = TimerPopoverViewController()
    private var timer: Timer?
    private var mode: PomodoroMode = .focus
    private var remainingSeconds: Int
    private var isRunning = false

    override init() {
        remainingSeconds = focusDuration
        super.init()
    }

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
            selector: #selector(activeApplicationDidChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        updateDisplay()
        startIfChromeIsFrontmost()
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
        advanceMode(lockOnFocusCompletion: false)
    }

    func timerPopover(_ controller: TimerPopoverViewController, didApplyFocusMinutes focusMinutes: Int, breakMinutes: Int) {
        let previousCurrentDuration = duration(for: mode)
        focusDuration = focusMinutes * 60
        breakDuration = breakMinutes * 60

        if !isRunning || previousCurrentDuration != duration(for: mode) {
            remainingSeconds = duration(for: mode)
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

    @objc private func activeApplicationDidChange(_ notification: Notification) {
        guard
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        else {
            return
        }

        startIfChrome(application)
    }

    private func startIfChromeIsFrontmost() {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return
        }

        startIfChrome(application)
    }

    private func startIfChrome(_ application: NSRunningApplication) {
        guard application.bundleIdentifier == chromeBundleIdentifier, !isRunning else {
            return
        }

        start()
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
        tick()
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        updateDisplay()
    }

    private func tick() {
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            advanceMode(lockOnFocusCompletion: true)
        } else {
            updateDisplay()
        }
    }

    private func resetCurrentMode() {
        pause()
        remainingSeconds = duration(for: mode)
        updateDisplay()
    }

    private func advanceMode(lockOnFocusCompletion: Bool) {
        let completedMode = mode

        timer?.invalidate()
        timer = nil

        switch mode {
        case .focus:
            mode = .breakTime
        case .breakTime:
            mode = .focus
        }

        remainingSeconds = duration(for: mode)
        isRunning = false
        CompletionSoundRunner.play()

        if completedMode == .focus && lockOnFocusCompletion {
            LockScreenRunner.lockScreen()
            start()
        } else {
            updateDisplay()
        }
    }

    private func duration(for mode: PomodoroMode) -> Int {
        switch mode {
        case .focus:
            return focusDuration
        case .breakTime:
            return breakDuration
        }
    }

    private func updateDisplay() {
        let timeText = format(seconds: remainingSeconds)
        statusItem?.button?.title = timeText
        statusItem?.button?.toolTip = "Pomodoro - \(mode.label) - \(timeText)"
        popoverController.update(
            mode: mode,
            remainingSeconds: remainingSeconds,
            isRunning: isRunning,
            focusMinutes: focusDuration / 60,
            breakMinutes: breakDuration / 60
        )
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
