#!/usr/bin/env bash
# Builds, copies the .app to ~/Applications, and registers a launchd agent
# so it starts automatically every time you log in.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MeetingAirplane"
LABEL="com.user.meetingairplane"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

# Build first.
./build.sh

# Install to ~/Applications.
mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/${APP_NAME}.app"
cp -R "build/${APP_NAME}.app" "$HOME/Applications/"

APP_EXEC="$HOME/Applications/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# Write the launchd agent plist.
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_EXEC}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/meetingairplane.out.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/meetingairplane.err.log</string>
</dict>
</plist>
EOF

# (Re)load.
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

cat <<'EOF'

✓ MeetingAirplane installed and running.

FIRST-LAUNCH NOTE
  macOS will pop up a Calendar permission request the first time the app
  tries to read events. Grant it — otherwise the app can't see your
  meetings. If you miss the popup, go to:
    System Settings → Privacy & Security → Calendars → enable MeetingAirplane

OUTLOOK
  This reads from the macOS Calendar app. If your Outlook account is not
  already added there, open Calendar.app once and add it via:
    System Settings → Internet Accounts → Microsoft Exchange / Outlook

TEST THE ANIMATION RIGHT NOW
  ~/Applications/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test

LOGS
  /tmp/meetingairplane.out.log
  /tmp/meetingairplane.err.log

EOF
