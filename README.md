# Pomodoro Lock Screen

A small native macOS menu bar Pomodoro timer. It shows the remaining time in the menu bar, opens a compact popover when clicked, and starts a 5-minute break automatically after a 25-minute focus session.

The focus and break timers count down only while you are actively using the Mac with the mouse, trackpad, or keyboard. When input has been idle for 10 seconds, the current timer pauses. Moving the mouse, using the trackpad, or typing starts the timer again.

After three completed focus rounds by default, the app shows a long-work warning popup before continuing. You can change the warning threshold from the menu bar popover.

When a focus or break session ends, the app plays a short completion effect using the built-in macOS `Funk` sound. When a focus session ends, the app also attempts to lock the Mac. On modern macOS this may ask for Accessibility or Automation permission because the primary lock methods trigger the built-in `Control` + `Command` + `Q` Lock Screen shortcut. If macOS blocks that, the app falls back to putting the display to sleep.

## Controls

- `Start` / `Pause`: run or pause the current timer.
- `Reset`: reset the current focus or break timer.
- `Skip`: move to the next mode without locking.
- `Focus` / `Break` minute fields + `Apply`: edit the timer lengths.
- `Warn after` + `Apply`: edit how many completed focus rounds trigger the long-work warning.
- `Lock Now`: immediately trigger the same lock behavior.
- `Quit`: exit the menu bar app.

## Build And Run

Run from the repository:

```sh
make run
```

Build a normal `.app` bundle:

```sh
make bundle
open dist/PomodoroLockScreen.app
```

Build a downloadable `.dmg` installer image:

```sh
make dmg
open dist/PomodoroLockScreen-0.1.0.dmg
```

The DMG contains `PomodoroLockScreen.app` and an `Applications` shortcut so the app can be installed by dragging it into Applications.

The bundled app and DMG are intentionally unsigned. They are usable for local installs and direct sharing, but macOS Gatekeeper can warn or block them on other Macs. For broad public distribution without Gatekeeper friction, sign the `.app` with a Developer ID Application certificate, build the DMG, then notarize and staple it with your Apple developer account.
