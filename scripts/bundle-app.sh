#!/usr/bin/env bash
set -euo pipefail

app_name="PomodoroLockScreen"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
binary_path="$repo_root/.build/release/$app_name"
app_dir="$repo_root/dist/$app_name.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"

if [[ ! -x "$binary_path" ]]; then
  echo "Missing release binary: $binary_path" >&2
  echo "Run: swift build -c release" >&2
  exit 1
fi

rm -rf "$app_dir"
mkdir -p "$macos_dir"
cp "$binary_path" "$macos_dir/$app_name"

cat > "$contents_dir/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>PomodoroLockScreen</string>
  <key>CFBundleIdentifier</key>
  <string>local.pomodoro-lock-screen</string>
  <key>CFBundleName</key>
  <string>Pomodoro Lock Screen</string>
  <key>CFBundleDisplayName</key>
  <string>Pomodoro Lock Screen</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>Used to trigger the macOS Lock Screen shortcut when a focus session ends.</string>
</dict>
</plist>
PLIST

echo "$app_dir"
