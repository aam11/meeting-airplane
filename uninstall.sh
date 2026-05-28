#!/usr/bin/env bash
# Removes the launchd agent and the installed .app.
set -euo pipefail

LABEL="com.user.meetingairplane"
PLIST_PATH="$HOME/Library/LaunchAgents/${LABEL}.plist"

if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "✓ Removed launch agent"
fi

if [ -d "$HOME/Applications/MeetingAirplane.app" ]; then
    rm -rf "$HOME/Applications/MeetingAirplane.app"
    echo "✓ Removed ~/Applications/MeetingAirplane.app"
fi

echo ""
echo "Note: this does NOT revoke calendar permission."
echo "To revoke: System Settings → Privacy & Security → Calendars → remove MeetingAirplane."
