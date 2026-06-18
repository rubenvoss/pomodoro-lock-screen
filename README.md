# Pomodoro Lock Screen

A small native macOS menu bar Pomodoro timer. It shows the remaining time in the menu bar, opens a compact popover when clicked, and starts a 5-minute break automatically after a 25-minute focus session.

The timer also starts automatically whenever Google Chrome becomes the frontmost app. Chrome can already be open; the trigger is focusing/clicking into Chrome.

When a focus or break session ends, the app plays a short completion effect using the built-in macOS `Funk` sound and system speech. When a focus session ends, the app also attempts to lock the Mac. On modern macOS this may ask for Accessibility or Automation permission because the primary lock methods trigger the built-in `Control` + `Command` + `Q` Lock Screen shortcut. If macOS blocks that, the app falls back to putting the display to sleep.

## Controls

- `Start` / `Pause`: run or pause the current timer.
- `Reset`: reset the current focus or break timer.
- `Skip`: move to the next mode without locking.
- `Focus` / `Break` minute fields + `Apply`: edit the timer lengths.
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

The bundled app is intentionally unsigned. If Gatekeeper blocks it after moving it elsewhere, run it from this build directory or sign/notarize it with your Apple developer identity.
