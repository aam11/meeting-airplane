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
- The plane and banner slide across with `NSAnimationContext`. The window
  closes itself after ~9 seconds.

## Tweaks

Open `Sources/CalendarWatcher.swift`:

- `leadMinutes` — how many minutes before the meeting to fire (default 5).
- `pollSeconds` — how often to recheck the calendar (default 30).

Open `Sources/PlaneView.swift` to adjust the animation duration, colors, or
banner text format. After any edit run `./install.sh` again.

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
