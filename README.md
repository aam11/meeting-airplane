# Meeting Airplane

A tiny macOS background app that flies a cartoon airplane across your screen
five minutes before every Outlook meeting, with a banner showing the meeting
title and "starts in N min."

It reads from the macOS Calendar app (which is where your Outlook account
already lives), so there's no API key, no OAuth, no server. It runs as a
launchd background agent — no Dock icon, no menu bar item.

## Install

```bash
git clone https://github.com/aam11/meeting-airplane.git
cd meeting-airplane
./install.sh
```

This will:

1. Compile the Swift sources into `MeetingAirplane.app`.
2. Copy it to `~/Applications/`.
3. Register a launchd agent at `~/Library/LaunchAgents/com.user.meetingairplane.plist`.
4. Start the agent immediately.

Requires Xcode Command Line Tools (`xcode-select --install` if you don't
have them).

## First-launch permission

The first time the app reads your calendar, macOS will pop up a permission
request. Grant it.

If you miss the popup, go to **System Settings → Privacy & Security →
Calendars** and enable *MeetingAirplane*.

## Make sure Outlook is in Calendar.app

This app reads from the built-in Calendar app, not from Outlook directly.
If you haven't already added your Outlook account to Calendar:

- **System Settings → Internet Accounts → Microsoft Exchange** (or Outlook),
  then sign in.
- Open Calendar.app once and confirm your Outlook events appear there.

That's the only setup. After that the app sees every new and updated meeting
automatically — no resync.

## Preview the animation right now

You don't have to wait for a real meeting. Run:

```bash
~/Applications/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

This plays the animation once with a dummy meeting title, then quits.

## How it works

- A 30-second timer asks EventKit for events in the next two hours.
- For each event whose start time is between *now* and *now + 5 min*, the
  app fires the airplane once. Dedup is keyed on `(event-id, start-time)`,
  so recurring meetings each fire on their own occurrence and never twice.
- The overlay is a borderless, transparent, click-through `NSWindow` at
  screensaver level — it draws on top of everything (including full-screen
  apps) and lets your clicks pass through to whatever's underneath.
- The plane and banner slide across via a manual 60Hz `Timer` updating
  `setFrameOrigin` (NSWindow's animator ignores duration overrides on recent
  macOS). The window fades out in the final 0.6s and closes after the slide
  finishes (~6s by default; configurable via `slideDuration`).

## Configuration

Runtime settings live in macOS `UserDefaults` under domain
`com.user.meetingairplane`. No GUI — use the `defaults` CLI:

```bash
# Slow the plane down to 12 seconds across the screen (default: 6)
defaults write com.user.meetingairplane slideDuration -float 12

# Fire 10 minutes early instead of 5 (default: 5)
defaults write com.user.meetingairplane leadMinutes -int 10

# Poll every 60 seconds instead of 30 (default: 30)
defaults write com.user.meetingairplane pollSeconds -float 60

# Tolerance band around the lead time, in seconds (default: 60)
# Set to 0 for the strict "fire if event starts within leadMinutes" v0.2 behavior.
defaults write com.user.meetingairplane triggerBandSeconds -float 60

# Restart the agent to pick up changes
launchctl kickstart -k "gui/$(id -u)/com.user.meetingairplane"
```

Out-of-range values clamp to safe limits; missing values use defaults.
To reset everything:

```bash
defaults delete com.user.meetingairplane
launchctl kickstart -k "gui/$(id -u)/com.user.meetingairplane"
```

## Tweaks

Open `Sources/CalendarWatcher.swift`:

- `leadMinutes` — how many minutes before the meeting to fire (default 5).
- `pollSeconds` — how often to recheck the calendar (default 30).

Open `Sources/OverlayController.swift` to adjust the animation, colors, or
layout. After any edit run `./install.sh` again. For runtime-tunable values
(durations, polling, lead time), use `defaults write` — see the
**Configuration** section above.

## Logs

```
/tmp/meetingairplane.out.log
/tmp/meetingairplane.err.log
```

## Uninstall

```bash
./uninstall.sh
```

Removes the launch agent and the installed `.app`. Calendar permission is
left in place (revoke it in System Settings if you also want that gone).

## Credits

Plane and banner artwork by [@conniexu444](https://github.com/conniexu444),
borrowed from [meeting-reminder](https://github.com/conniexu444/meeting-reminder)
under the MIT License. Full license text in [`art/LICENSE-art.txt`](art/LICENSE-art.txt).
