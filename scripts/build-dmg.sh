#!/usr/bin/env bash
set -euo pipefail

app_name="PomodoroLockScreen"
volume_name="Pomodoro Lock Screen"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_path="$repo_root/dist/$app_name.app"
info_plist="$app_path/Contents/Info.plist"
staging_dir="$repo_root/dist/dmg-root"

if [[ ! -d "$app_path" ]]; then
  echo "Missing app bundle: $app_path" >&2
  echo "Run: make bundle" >&2
  exit 1
fi

version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$info_plist" 2>/dev/null || true)"
if [[ -z "$version" ]]; then
  version="0.0.0"
fi

dmg_path="$repo_root/dist/$app_name-$version.dmg"

rm -rf "$staging_dir"
rm -f "$dmg_path"
mkdir -p "$staging_dir"

/usr/bin/ditto "$app_path" "$staging_dir/$app_name.app"
ln -s /Applications "$staging_dir/Applications"

/usr/bin/hdiutil create \
  -volname "$volume_name" \
  -srcfolder "$staging_dir" \
  -ov \
  -format UDZO \
  "$dmg_path" >/dev/null

/usr/bin/hdiutil verify "$dmg_path" >/dev/null
rm -rf "$staging_dir"

echo "$dmg_path"
