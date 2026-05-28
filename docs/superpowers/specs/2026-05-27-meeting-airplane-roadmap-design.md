# Meeting Airplane — Public Repo + Roadmap Design

**Date:** 2026-05-27
**Author:** Anish Aniket Mahanta
**Status:** Approved

## Context

`meeting-airplane` is a working macOS background app that flies a banner across the screen 5 min before Outlook calendar meetings. Built with pure `swiftc` + shell scripts (no Xcode project). Runs as a launchd accessory agent — no Dock, no menu bar.

After comparing against `conniexu444/meeting-reminder` (a similar SwiftUI menu-bar app), we identified bug-grade improvements to adopt and decided to publish our version as a public OSS repo on GitHub.

## Goals

1. Publish current code as public MIT-licensed repo at `github.com/aam11/meeting-airplane`.
2. Land bug-grade fixes in v0.2.
3. Add `UserDefaults`-based configuration in v0.3.
4. Replace ✈️ emoji with hand-drawn PNG art (borrowed from Connie's MIT-licensed repo with attribution) in v0.4.

Non-goals (decided against):

- Menu bar UI / status item. Keep pure-background launchd ethos.
- Multi-screen mirroring. Stick with cursor's screen.
- Xcode project. Stay with `swiftc` + shell.

## Architecture (unchanged from current)

```text
Sources/
  main.swift              — entry, --test flag, AppDelegate, lifecycle
  CalendarWatcher.swift   — EventKit poll, dedup, fires onMeetingSoon
  OverlayController.swift — NSPanel + label/PNG views + slide animation
  Config.swift            — (new in v0.3) UserDefaults loader

art/                      — (new in v0.4) PNG assets + license
docs/superpowers/specs/   — design docs
```

The pieces remain narrow and replaceable:

- `CalendarWatcher` owns event polling and dedup. Knows nothing about UI.
- `OverlayController` owns the visible banner. Knows nothing about calendars.
- `main.swift` wires them.
- `Config` (added v0.3) reads `UserDefaults`. Knows nothing about either component, just provides values.

## Milestones

### v0.1 — Repo bootstrap (no code changes)

Snapshot current code, ship as public MIT-licensed repo.

**Steps:**

1. `.gitignore`: `build/`, `*.swp`, `.DS_Store`.
2. `LICENSE`: MIT, copyright 2026 Anish Aniket Mahanta.
3. `README.md`: sanitize hardcoded `/Users/anishaniketmahanta/...` path → use `cd /path/to/clone` example, keep my-machine note as footnote.
4. `git init` → initial commit → `gh repo create aam11/meeting-airplane --public --source=. --push`.
5. Tag `v0.1.0`.
6. GitHub topics: `macos`, `swift`, `outlook`, `calendar`, `eventkit`.

**Risks:** README sanitization could trip up paste-to-paste install — mitigate with footnote retaining the absolute path for reference.

### v0.2 — P1 bug fixes (~37 LOC across 2 files)

Adopt 4 robustness fixes inspired by Connie's repo.

**Fix 1: `NSWindow` → `NSPanel(.nonactivatingPanel)`** — eliminates focus theft on `orderFront`. Subclass to override `canBecomeKey`/`canBecomeMain → false`. ~10 LOC.

**Fix 2: Window level → `CGWindowLevelForKey(.maximumWindow) + 1`** — more reliable above-everything than `.screenSaver`. 1 LOC. Comment notes `.screenSaver` as fallback if macOS suppresses.

**Fix 3: Attendee-aware title** in `CalendarWatcher`. Add helper `displayTitle(for: EKEvent) -> String`:

- 0 named attendees → `event.title ?? "Untitled meeting"`
- 1 → `"Meeting with <name>"`
- 2 → `"Meeting with <a> and <b>"`
- 3+ → `"Meeting with <a>, <b> +N more"`

Filter out current user; require non-empty names. Replace the `event.title ?? "Untitled meeting"` line in `main.swift`'s `onMeetingSoon` handler to call this helper instead. ~20 LOC.

**Fix 4: Fade-out last 0.6s** in `OverlayController` slide timer. When `progress ≥ ~0.9`, ramp `panel.alphaValue` from 1.0 to 0.0 across remaining slide time. ~6 LOC.

**Testing (manual via `--test`):**

- Focus check: run `--test`, confirm Terminal keeps focus.
- Fullscreen check: foreground a fullscreen app, trigger `--test`, banner draws above.
- Attendee title: needs real meeting w/ invitees; before merge, mock by hand.
- Fade: visual confirmation last second of slide.

### v0.3 — UserDefaults config (~80 LOC, new file `Sources/Config.swift`)

Move hard-coded constants to `UserDefaults` under domain `com.user.meetingairplane`. No GUI — config via `defaults` CLI.

**Keys with defaults + clamp ranges:**

| Key | Default | Range | Consumer |
|-----|---------|-------|----------|
| `leadMinutes` | 5 | 1–60 | `CalendarWatcher` |
| `pollSeconds` | 30 | 10–300 | `CalendarWatcher` |
| `slideDuration` | 6.0 | 2.0–30.0 | `OverlayController` |
| `fadeDuration` | 0.6 | 0.0–3.0 | `OverlayController` |
| `triggerBandSeconds` | 60 | 0–300 | `CalendarWatcher` (tolerance window — see below) |

`Config.load()` reads all keys at app launch, applies defaults for missing/zero, clamps to safe range. Passed to `CalendarWatcher.init(config:)` and `OverlayController.init(config:)`.

**Trigger window logic change in `CalendarWatcher`:** current logic fires when `0 < minutesUntil ≤ leadMinutes`. In v0.3, switch to a band: fire when the event starts within `[leadMinutes*60 - triggerBandSeconds, leadMinutes*60 + triggerBandSeconds]` seconds from now. Default band of 60s ≈ Connie's `[lead-1, lead+1]` minute window — forgives poll drift. With `triggerBandSeconds: 0`, behavior reverts to a stricter "fire when `≤ leadMinutes`" matching current behavior.

**Reload model:** settings applied at app launch. User runs `launchctl kickstart -k gui/$UID/com.user.meetingairplane` to pick up new values. README documents the workflow.

**Testing:**

- `defaults write com.user.meetingairplane slideDuration -float 12` + kickstart → 12s slide.
- Out-of-range values clamp.
- `defaults delete com.user.meetingairplane` → restores defaults.

### v0.4 — Custom plane art from `conniexu444/meeting-reminder` (~40 LOC + 4 PNGs)

Adopt Connie's hand-drawn plane + banner PNGs. Drop our pastel sky-blue rounded NSView banner. Switch to white text in Comic Sans MS, matching her design.

**Assets to take (MIT-licensed):**

- `plane.png` (+ `@2x` if present) — right-facing hand-drawn plane.
- `banner.png` (+ `@2x` if present) — pink banner background.

NOT taking: app icon (we're `.accessory`, no Dock icon), menubar icon (no menu bar).

**Bundle path:** `art/*.png` in repo, copied to `MeetingAirplane.app/Contents/Resources/` by `build.sh`. Loadable via `NSImage(named: "plane")`.

**View redesign (`OverlayController.swift`):**

- Plane on right (leading): `NSImageView` with `plane.png`, `scaledToFit`, ~220×220pt.
- Banner on left (trailing): banner PNG as background of a container view, sized to fit text with horizontal padding.
- Text: white, Comic Sans MS 28pt semibold, centered in banner. Fallback to `.systemFont(ofSize: 28, weight: .bold)` if Comic Sans absent.
- Window dynamically sized to `(text_width + 220 + padding) × 220`.

**Attribution (license compliance):**

- `art/LICENSE-art.txt` — full MIT text + Connie's copyright line.
- `README.md` `## Credits` section — names `@conniexu444`, links source repo, points to art license file.

**Risks:**
1. Her plane PNG may have rope/banner pre-drawn. If so, banner.png positioning must align with rope endpoint — verify by inspecting the PNG first.
2. Aspect ratios may not match 220×220 — `scaledToFit` not `Fill`.
3. Comic Sans MS missing on some installs — fallback handles.
4. Attribution is non-negotiable — must persist through any future README rewrite.

## Data flow

```text
EventKit → CalendarWatcher.check() (every pollSeconds)
        → filter to events starting in (now, now + leadMinutes ± triggerBand]
        → dedup on (eventID, startDate) — recurring-safe
        → fire onMeetingSoon(event)
        → main.swift handler → OverlayController.show(title, startDate, minutesUntil)
        → NSPanel, max window level, NSImageView(plane) + banner.png + NSTextField
        → 60Hz Timer slides setFrameOrigin from off-left to off-right over slideDuration
        → last fadeDuration seconds: ramp alphaValue → 0
        → orderOut, release
```

## Error handling

| Failure | Behavior |
|---------|----------|
| Calendar permission denied | `NSLog` + skip polling. User re-grants in System Settings. |
| `NSScreen.main` nil | Bail with `NSLog`, no banner shown. |
| Comic Sans MS missing | Fall back to system font. No user-visible failure. |
| PNG asset missing | `NSImage(named:)` returns nil; `NSImageView` shows empty box. Visible regression — build script validates PNGs exist at build time. |
| `UserDefaults` value out of range | Clamp to safe value silently. |
| `UserDefaults` value missing/zero | Use baked-in default. |

## Testing strategy

Manual via `--test` flag at each milestone:

- v0.2: focus check, fullscreen overlay check, fade visual.
- v0.3: `defaults write` → kickstart → confirm new value applied.
- v0.4: visual confirmation of plane PNG + banner PNG + Comic Sans text.

No automated tests planned — pure-UI app, low-value to mock AppKit + EventKit.

## What does NOT change across all milestones

- Pure-background `.accessory` app, no menu bar, no Dock icon.
- launchd agent at `~/Library/LaunchAgents/com.user.meetingairplane.plist`.
- `swiftc` + shell build (no Xcode project).
- Cursor-aware screen pick.
- Recurring-event-safe dedup (`id|startDate`).
- Bounded dedup set (capped at 500 then cleared).
- Click-through, transparent window.

## Roll-out

Milestones land in order on `main`. Each tagged: `v0.2.0`, `v0.3.0`, `v0.4.0`. No long-lived feature branches. Each milestone independently testable via `--test`.
