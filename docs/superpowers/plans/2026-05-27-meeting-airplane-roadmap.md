# Meeting Airplane Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish `meeting-airplane` as a public OSS repo and ship 3 incremental improvements (P1 bug fixes, UserDefaults config, custom plane art from `conniexu444/meeting-reminder`).

**Architecture:** Existing 4-file Swift app (`main.swift`, `CalendarWatcher.swift`, `OverlayController.swift`) stays. v0.3 adds `Config.swift`. v0.4 adds `art/` bundled into `Resources/`. No Xcode project, no menu bar UI — preserves pure-background launchd ethos.

**Tech Stack:** Swift (AppKit, EventKit, QuartzCore), `swiftc` direct compile, launchd agent, `gh` CLI (account `aam11`), MIT license.

**Spec reference:** `docs/superpowers/specs/2026-05-27-meeting-airplane-roadmap-design.md`

**Working directory:** `/Users/anishaniketmahanta/Documents/Claude/Projects/meeting-airplane`

---

## File Structure

Files this plan creates or modifies, grouped by milestone:

### v0.1 (repo bootstrap)
- **Create:** `.gitignore`
- **Create:** `LICENSE`
- **Modify:** `README.md` (sanitize hard-coded user path)

### v0.2 (P1 fixes)
- **Modify:** `Sources/OverlayController.swift` (NSPanel + max level + fade-out)
- **Modify:** `Sources/CalendarWatcher.swift` (attendee-aware `displayTitle` helper)
- **Modify:** `Sources/main.swift` (call `displayTitle` helper)

### v0.3 (UserDefaults config)
- **Create:** `Sources/Config.swift` (UserDefaults loader + clamp)
- **Modify:** `Sources/main.swift` (load Config, pass to components)
- **Modify:** `Sources/CalendarWatcher.swift` (consume `config.leadMinutes/pollSeconds/triggerBandSeconds`, switch to band trigger)
- **Modify:** `Sources/OverlayController.swift` (consume `config.slideDuration/fadeDuration`)
- **Modify:** `README.md` (document `defaults write` workflow)

### v0.4 (custom art)
- **Create:** `art/plane.png` + `art/plane@2x.png` (from Connie's repo)
- **Create:** `art/banner.png` + `art/banner@2x.png` (from Connie's repo)
- **Create:** `art/LICENSE-art.txt` (MIT text + Connie's copyright)
- **Modify:** `build.sh` (copy `art/*.png` into Resources)
- **Modify:** `Sources/OverlayController.swift` (replace emoji label + rounded NSView with NSImageView plane + banner-PNG-backed text view; Comic Sans white text)
- **Modify:** `README.md` (Credits section)

---

## Pre-flight Checks (run once before starting)

- [ ] **Step 1: Confirm working dir + gh auth**

Run:

```bash
cd /Users/anishaniketmahanta/Documents/Claude/Projects/meeting-airplane && pwd && gh auth status 2>&1 | grep -E "(Logged in|Active account)"
```

Expected: working dir prints; `Logged in to github.com account aam11`, `Active account: true`.

- [ ] **Step 2: Confirm build still works pre-changes**

Run:

```bash
./build.sh
```

Expected: `✓ Built build/MeetingAirplane.app`.

- [ ] **Step 3: Note the current installed app exists**

Run:

```bash
launchctl list | grep meetingairplane && ls -la ~/Applications/MeetingAirplane.app
```

Expected: launchd entry exists with a PID + `Contents/` listed. (If absent, the install script will be re-run at the end.)

---

# Phase v0.1 — Repo Bootstrap

## Task 1: Write `.gitignore`

**Files:**

- Create: `.gitignore`

- [ ] **Step 1: Write the file**

Path: `.gitignore`

```gitignore
# Build artifacts
build/

# macOS junk
.DS_Store

# Editor swap files
*.swp
*.swo

# Logs
*.log

# Claude/superpowers memory (keep specs + plans, exclude any local-only state)
.claude/
```

- [ ] **Step 2: Verify it exists and is readable**

Run:

```bash
cat .gitignore
```

Expected: contents of the file print.

---

## Task 2: Write `LICENSE`

**Files:**

- Create: `LICENSE`

- [ ] **Step 1: Write the file**

Path: `LICENSE`

```text
MIT License

Copyright (c) 2026 Anish Aniket Mahanta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Verify it exists**

Run:

```bash
head -1 LICENSE
```

Expected: `MIT License`.

---

## Task 3: Sanitize README

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Replace the hard-coded user path in the Install section**

In `README.md`, find this block:

```markdown
## Install

​```bash
cd /Users/anishaniketmahanta/Documents/Claude/Projects/meeting-airplane
./install.sh
​```
```

Replace it with:

```markdown
## Install

​```bash
git clone https://github.com/aam11/meeting-airplane.git
cd meeting-airplane
./install.sh
​```
```

(Drop the literal "​" — that zero-width char is in this plan to keep code fences from breaking. The actual block should be standard triple-backtick + `bash`.)

- [ ] **Step 2: Verify the absolute path is gone**

Run:

```bash
grep -c "/Users/anishaniketmahanta" README.md
```

Expected: `0`.

---

## Task 4: Initial git commit

**Files:**

- Create: `.git/` (via init)

- [ ] **Step 1: Initialize the repo**

Run:

```bash
git init -b main
```

Expected: `Initialized empty Git repository in .../meeting-airplane/.git/`.

- [ ] **Step 2: Stage all tracked files**

Run:

```bash
git add .gitignore LICENSE README.md Info.plist build.sh install.sh uninstall.sh Sources/ docs/
```

Note: do NOT use `git add .` here — confirms what we're committing.

- [ ] **Step 3: Verify staged set**

Run:

```bash
git status --short
```

Expected output should list only the files above as new (`A`). No `build/`, no `.DS_Store`.

- [ ] **Step 4: Commit**

Run:

```bash
git commit -m "Initial commit: macOS background app, flies plane banner before Outlook meetings"
```

Expected: a commit hash + summary line.

---

## Task 5: Push to GitHub

**Files:** none (remote operation)

- [ ] **Step 1: Create the GitHub repo and push**

Run:

```bash
gh repo create aam11/meeting-airplane --public --source=. --push --description "macOS background app that flies a plane banner across your screen 5 min before each Outlook calendar meeting"
```

Expected: `https://github.com/aam11/meeting-airplane` printed; `main` branch pushed.

- [ ] **Step 2: Verify push**

Run:

```bash
gh repo view aam11/meeting-airplane --json url,visibility,defaultBranchRef
```

Expected: URL `https://github.com/aam11/meeting-airplane`, visibility `PUBLIC`, default branch `main`.

---

## Task 6: Tag v0.1.0 and add topics

**Files:** none

- [ ] **Step 1: Create local tag**

Run:

```bash
git tag -a v0.1.0 -m "v0.1.0 — initial public release"
```

- [ ] **Step 2: Push tag**

Run:

```bash
git push origin v0.1.0
```

Expected: `* [new tag] v0.1.0 -> v0.1.0`.

- [ ] **Step 3: Set repo topics**

Run:

```bash
gh repo edit aam11/meeting-airplane --add-topic macos --add-topic swift --add-topic outlook --add-topic calendar --add-topic eventkit
```

Expected: successful edit (no error printed).

- [ ] **Step 4: Verify**

Run:

```bash
gh repo view aam11/meeting-airplane --json repositoryTopics
```

Expected: 5 topics listed.

---

# Phase v0.2 — P1 Bug Fixes

## Task 7: Fix 1 — Swap `NSWindow` for `NSPanel(.nonactivatingPanel)`

**Files:**

- Modify: `Sources/OverlayController.swift`

- [ ] **Step 1: Add a private NSPanel subclass at the top of the file**

In `Sources/OverlayController.swift`, immediately after the `import AppKit` line, insert:

```swift
/// Non-activating NSPanel — never becomes key/main, so it cannot steal focus.
private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
```

- [ ] **Step 2: Replace the NSWindow construction**

Find this block in `show(...)`:

```swift
        let w = NSWindow(
            contentRect: startFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
```

Replace with:

```swift
        let w = OverlayPanel(
            contentRect: startFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
```

- [ ] **Step 3: Update the `window` property type to allow the panel**

Find:

```swift
    private var window: NSWindow?
```

Replace with:

```swift
    private var window: NSPanel?
```

(`NSPanel` is a subclass of `NSWindow`, all existing calls — `orderOut`, `setFrameOrigin`, `orderFrontRegardless`, `alphaValue` — still work.)

- [ ] **Step 4: Build**

Run:

```bash
./build.sh
```

Expected: `✓ Built build/MeetingAirplane.app`.

- [ ] **Step 5: Manual test — focus must NOT steal**

Run:

```bash
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

While the banner slides, verify the Terminal (or whatever app you started from) keeps focus — no flicker, no other app activating.

Expected: banner draws + slides + closes; focused app does not change.

---

## Task 8: Fix 2 — Bump window level to `maximumWindow + 1`

**Files:**

- Modify: `Sources/OverlayController.swift`

- [ ] **Step 1: Replace the level assignment**

Find this line:

```swift
        // .screenSaver draws over full-screen apps and the menu bar. If macOS
        // suppresses it on your build, fall back to .popUpMenu.
        w.level = .screenSaver
```

Replace with:

```swift
        // Above-everything level. Higher than .screenSaver so it survives
        // Mission Control/screensaver transitions. Fall back to .screenSaver
        // if a future macOS suppresses this.
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
```

- [ ] **Step 2: Build**

Run:

```bash
./build.sh
```

Expected: success.

- [ ] **Step 3: Manual test — over full-screen apps**

Open any app and enter full-screen mode (e.g., Safari + green button or `Ctrl+Cmd+F`). From a Terminal on a different Space, run:

```bash
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

Move the cursor to the full-screen app's display before running so the banner picks that screen.

Expected: banner draws above the full-screen content.

---

## Task 9: Fix 3 — Attendee-aware title helper in `CalendarWatcher`

**Files:**

- Modify: `Sources/CalendarWatcher.swift`
- Modify: `Sources/main.swift`

- [ ] **Step 1: Add the `displayTitle` helper to `CalendarWatcher`**

In `Sources/CalendarWatcher.swift`, add this method inside the `CalendarWatcher` class (just before the closing `}`):

```swift
    /// Prefer "Meeting with <names>" when the event has named invitees besides
    /// the current user; fall back to the event title.
    func displayTitle(for event: EKEvent) -> String {
        let fallback = event.title ?? "Untitled meeting"

        let names = (event.attendees ?? [])
            .filter { !$0.isCurrentUser }
            .compactMap { participant -> String? in
                guard let name = participant.name, !name.isEmpty else { return nil }
                return name
            }

        guard !names.isEmpty else { return fallback }

        switch names.count {
        case 1:  return "Meeting with \(names[0])"
        case 2:  return "Meeting with \(names[0]) and \(names[1])"
        default: return "Meeting with \(names[0]), \(names[1]) +\(names.count - 2) more"
        }
    }
```

- [ ] **Step 2: Change `onMeetingSoon` callback signature to pass the event through**

Already does — the callback is `((EKEvent) -> Void)`. No change needed in `CalendarWatcher.swift` API.

- [ ] **Step 3: Update `main.swift` to call the helper**

In `Sources/main.swift`, find:

```swift
        watcher.onMeetingSoon = { [weak self] event in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let title = event.title ?? "Untitled meeting"
                let minutesUntil = max(1, Int(round(event.startDate.timeIntervalSinceNow / 60)))
                self.overlay?.show(
                    title: title,
                    startDate: event.startDate,
                    minutesUntil: minutesUntil,
                    completion: nil
                )
            }
        }
```

Replace `let title = event.title ?? "Untitled meeting"` with:

```swift
                let title = self.watcher.displayTitle(for: event)
```

Note: `self.watcher` is the existing `private let watcher = CalendarWatcher()` property.

- [ ] **Step 4: Build**

Run:

```bash
./build.sh
```

Expected: success.

- [ ] **Step 5: Manual test — fake invitees**

There's no `--test` mode that exercises real attendees. Verify compilation succeeded and the helper is exercised in production by waiting for a real meeting. For now, the build passing is the gate; an end-to-end check happens after `install.sh` runs.

---

## Task 10: Fix 4 — Fade out last 0.6s of the slide

**Files:**

- Modify: `Sources/OverlayController.swift`

- [ ] **Step 1: Add fade ramp inside the slide timer**

Find this block in `Sources/OverlayController.swift`:

```swift
        let startX = startFrame.origin.x
        let endX = screenFrame.maxX
        let duration: TimeInterval = 6.0
        let t0 = Date()
        slideTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self, weak w] timer in
            guard let w = w else {
                timer.invalidate()
                return
            }
            let progress = min(1.0, Date().timeIntervalSince(t0) / duration)
            let x = startX + (endX - startX) * CGFloat(progress)
            w.setFrameOrigin(NSPoint(x: x, y: yTop))
            if progress >= 1.0 {
                timer.invalidate()
                NSLog("[MeetingAirplane] slide done")
                self?.slideTimer = nil
                self?.window?.orderOut(nil)
                self?.window = nil
                completion?()
            }
        }
```

Replace with:

```swift
        let startX = startFrame.origin.x
        let endX = screenFrame.maxX
        let duration: TimeInterval = 6.0
        let fadeDuration: TimeInterval = 0.6
        let fadeStart = max(0.0, (duration - fadeDuration) / duration)
        let t0 = Date()
        slideTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self, weak w] timer in
            guard let w = w else {
                timer.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(t0)
            let progress = min(1.0, elapsed / duration)
            let x = startX + (endX - startX) * CGFloat(progress)
            w.setFrameOrigin(NSPoint(x: x, y: yTop))

            // Fade alpha 1.0 → 0.0 across the final `fadeDuration` seconds.
            if progress >= fadeStart {
                let fadeProgress = (progress - fadeStart) / max(0.0001, 1.0 - fadeStart)
                w.alphaValue = CGFloat(max(0.0, 1.0 - fadeProgress))
            }

            if progress >= 1.0 {
                timer.invalidate()
                NSLog("[MeetingAirplane] slide done")
                self?.slideTimer = nil
                self?.window?.orderOut(nil)
                self?.window = nil
                completion?()
            }
        }
```

- [ ] **Step 2: Build**

Run:

```bash
./build.sh
```

Expected: success.

- [ ] **Step 3: Manual test — visual fade**

Run:

```bash
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

Expected: in the final ~0.6s, the banner visibly fades to transparent instead of snapping off-screen.

---

## Task 11: Commit + tag v0.2.0

**Files:** none

- [ ] **Step 1: Stage and commit**

Run:

```bash
git add Sources/OverlayController.swift Sources/CalendarWatcher.swift Sources/main.swift
git commit -m "v0.2: NSPanel + max window level + attendee-aware title + fade-out"
```

- [ ] **Step 2: Tag and push**

Run:

```bash
git tag -a v0.2.0 -m "v0.2.0 — P1 bug fixes"
git push origin main v0.2.0
```

Expected: tag pushed, branch updated.

---

# Phase v0.3 — UserDefaults Config

## Task 12: Create `Sources/Config.swift`

**Files:**

- Create: `Sources/Config.swift`

- [ ] **Step 1: Write the file**

Path: `Sources/Config.swift`

```swift
import Foundation

/// User-tunable settings, read from UserDefaults (domain
/// `com.user.meetingairplane`) at app launch. Out-of-range or missing values
/// fall back to safe defaults so a corrupt prefs file can never disable the
/// app.
struct Config {
    let leadMinutes: Int
    let pollSeconds: TimeInterval
    let slideDuration: TimeInterval
    let fadeDuration: TimeInterval
    let triggerBandSeconds: TimeInterval

    static func load() -> Config {
        let d = UserDefaults.standard
        return Config(
            leadMinutes:        clampInt(d.integer(forKey: "leadMinutes"),        default: 5,  min: 1,  max: 60),
            pollSeconds:        clamp(d.double(forKey: "pollSeconds"),            default: 30, min: 10, max: 300),
            slideDuration:      clamp(d.double(forKey: "slideDuration"),          default: 6,  min: 2,  max: 30),
            fadeDuration:       clamp(d.double(forKey: "fadeDuration"),           default: 0.6, min: 0,  max: 3),
            triggerBandSeconds: clamp(d.double(forKey: "triggerBandSeconds"),     default: 60, min: 0,  max: 300)
        )
    }
}

// 0 is treated as "not set" so users running v0.2 (no UserDefaults written)
// still get the documented defaults instead of the floor.
private func clamp(_ value: Double, default def: Double, min lo: Double, max hi: Double) -> Double {
    guard value != 0 else { return def }
    return Swift.min(hi, Swift.max(lo, value))
}

private func clampInt(_ value: Int, default def: Int, min lo: Int, max hi: Int) -> Int {
    guard value != 0 else { return def }
    return Swift.min(hi, Swift.max(lo, value))
}
```

- [ ] **Step 2: Build**

Run:

```bash
./build.sh
```

Expected: success (`Config.swift` compiles; nothing consumes it yet).

---

## Task 13: Consume `Config` in `CalendarWatcher`

**Files:**

- Modify: `Sources/CalendarWatcher.swift`

- [ ] **Step 1: Replace the hard-coded `leadMinutes`/`pollSeconds` properties**

In `Sources/CalendarWatcher.swift`, find:

```swift
    /// How many minutes before the meeting we trigger the animation.
    var leadMinutes: Int = 5

    /// How often we re-check the calendar.
    var pollSeconds: TimeInterval = 30
```

Replace with:

```swift
    private let config: Config

    init(config: Config) {
        self.config = config
    }
```

- [ ] **Step 2: Update the `start()` method to use `config.pollSeconds`**

Find:

```swift
                self.timer = Timer.scheduledTimer(withTimeInterval: self.pollSeconds, repeats: true) { [weak self] _ in
```

Replace with:

```swift
                self.timer = Timer.scheduledTimer(withTimeInterval: self.config.pollSeconds, repeats: true) { [weak self] _ in
```

- [ ] **Step 3: Replace the trigger logic with a band**

Find this block in `check()`:

```swift
            let minutesUntil = event.startDate.timeIntervalSince(now) / 60.0
            // Fire if the meeting is upcoming and within the lead window.
            // (If the app started up with only 3 min until a meeting, we still
            // fire — better late than missed.)
            if minutesUntil > 0 && minutesUntil <= Double(leadMinutes) {
                firedEventKeys.insert(key)
                onMeetingSoon?(event)
            }
```

Replace with:

```swift
            // Fire when the event start falls inside a band centered on
            // (now + leadMinutes). triggerBandSeconds=0 reverts to the strict
            // "fire if 0 < minutesUntil <= leadMinutes" v0.2 behavior.
            let secondsUntil = event.startDate.timeIntervalSince(now)
            let leadSeconds = Double(config.leadMinutes) * 60.0
            let band = config.triggerBandSeconds

            let inBand: Bool
            if band > 0 {
                inBand = secondsUntil >= (leadSeconds - band) && secondsUntil <= (leadSeconds + band)
            } else {
                inBand = secondsUntil > 0 && secondsUntil <= leadSeconds
            }

            if inBand {
                firedEventKeys.insert(key)
                onMeetingSoon?(event)
            }
```

- [ ] **Step 4: Build**

Run:

```bash
./build.sh
```

Expected: ERROR — `main.swift` still calls `CalendarWatcher()` with no args. We fix that in the next task. Note the error and continue.

---

## Task 14: Consume `Config` in `OverlayController`

**Files:**

- Modify: `Sources/OverlayController.swift`

- [ ] **Step 1: Add a stored config and init**

In `Sources/OverlayController.swift`, find:

```swift
final class OverlayController {
    private var window: NSPanel?
    private var slideTimer: Timer?
```

Replace with:

```swift
final class OverlayController {
    private let config: Config
    private var window: NSPanel?
    private var slideTimer: Timer?

    init(config: Config) {
        self.config = config
    }
```

- [ ] **Step 2: Replace the hard-coded slide + fade durations**

Find:

```swift
        let duration: TimeInterval = 6.0
        let fadeDuration: TimeInterval = 0.6
```

Replace with:

```swift
        let duration = config.slideDuration
        let fadeDuration = config.fadeDuration
```

- [ ] **Step 3: Build**

Run:

```bash
./build.sh
```

Expected: still ERROR (main.swift not yet updated). Continue.

---

## Task 15: Wire `Config` into `main.swift`

**Files:**

- Modify: `Sources/main.swift`

- [ ] **Step 1: Update the AppDelegate construction sites**

In `Sources/main.swift`, find:

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let watcher = CalendarWatcher()
    private var overlay: OverlayController?
    private let testMode: Bool

    init(testMode: Bool) {
        self.testMode = testMode
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay = OverlayController()
```

Replace with:

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let config: Config
    private let watcher: CalendarWatcher
    private var overlay: OverlayController?
    private let testMode: Bool

    init(testMode: Bool) {
        self.testMode = testMode
        self.config = Config.load()
        self.watcher = CalendarWatcher(config: config)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlay = OverlayController(config: config)
```

- [ ] **Step 2: Build**

Run:

```bash
./build.sh
```

Expected: `✓ Built build/MeetingAirplane.app`.

- [ ] **Step 3: Manual test — defaults still apply**

Run:

```bash
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

Expected: identical behavior to v0.2 (6s slide, 0.6s fade at end). No UserDefaults set yet, so all values come from `Config.load`'s baked-in defaults.

- [ ] **Step 4: Manual test — override works**

Run:

```bash
defaults write com.user.meetingairplane slideDuration -float 2
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
defaults delete com.user.meetingairplane slideDuration
```

Expected: middle run completes in ~2 seconds; final `delete` restores defaults.

- [ ] **Step 5: Manual test — clamp**

Run:

```bash
defaults write com.user.meetingairplane slideDuration -float 500
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
defaults delete com.user.meetingairplane slideDuration
```

Expected: slide takes 30s (clamped to max), not 500s.

---

## Task 16: Document config in README

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Add a `## Configuration` section**

In `README.md`, insert this section between the existing `## Tweaks` and `## Logs` sections (or just before `## Uninstall` if `## Tweaks` was removed during README sanitization — search for the closest one):

````markdown
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
````

- [ ] **Step 2: Verify**

Run:

```bash
grep -c "defaults write com.user.meetingairplane" README.md
```

Expected: `4` (one per documented key).

---

## Task 17: Commit + tag v0.3.0

**Files:** none

- [ ] **Step 1: Stage and commit**

Run:

```bash
git add Sources/Config.swift Sources/CalendarWatcher.swift Sources/OverlayController.swift Sources/main.swift README.md
git commit -m "v0.3: UserDefaults config (leadMinutes, pollSeconds, slideDuration, fadeDuration, triggerBandSeconds)"
```

- [ ] **Step 2: Tag and push**

Run:

```bash
git tag -a v0.3.0 -m "v0.3.0 — UserDefaults configuration"
git push origin main v0.3.0
```

---

# Phase v0.4 — Custom Plane Art

## Task 18: Fetch Connie's art assets

**Files:**

- Create: `art/plane.png`
- Create: `art/plane@2x.png` (if present in source)
- Create: `art/banner.png`
- Create: `art/banner@2x.png` (if present in source)

- [ ] **Step 1: Discover which scale variants exist**

Run:

```bash
gh api repos/conniexu444/meeting-reminder/contents/MeetingReminder/Assets.xcassets/airplane.imageset
gh api repos/conniexu444/meeting-reminder/contents/MeetingReminder/Assets.xcassets/banner.imageset
```

Expected: JSON listing files in each imageset. Note which of `airplane.png`, `airplane@2x.png`, `airplane@3x.png`, `banner.png`, `banner@2x.png`, `banner@3x.png` actually exist. The `download_url` field on each file is what we'll curl.

- [ ] **Step 2: Make the `art/` directory**

Run:

```bash
mkdir -p art
```

- [ ] **Step 3: Download each existing PNG**

For each file found in Step 1, run (substitute the actual `download_url` and rename to drop the `airplane` prefix in favor of `plane`):

```bash
curl -fsSL <download_url> -o art/<target-name>.png
```

Mapping:

- `airplane.png` → `art/plane.png`
- `airplane@2x.png` → `art/plane@2x.png`
- `airplane@3x.png` → `art/plane@3x.png` (if present)
- `banner.png` → `art/banner.png`
- `banner@2x.png` → `art/banner@2x.png`
- `banner@3x.png` → `art/banner@3x.png` (if present)

- [ ] **Step 4: Verify**

Run:

```bash
ls -la art/
file art/*.png | head
```

Expected: at least `plane.png` and `banner.png` listed; `file` reports each as `PNG image data` with width/height.

- [ ] **Step 5: Inspect to confirm whether plane.png includes the rope/banner**

Run:

```bash
file art/plane.png art/banner.png
open art/plane.png art/banner.png  # opens both in Preview.app
```

Visually confirm:

- If `plane.png` includes a rope/banner stub, the layout will need to align Connie's banner.png to where the rope ends. Note position.
- If `plane.png` is plane-only, banner.png sits to the left independently.

Either way, layout in Task 20 is adjusted accordingly.

---

## Task 19: Add art license + update build.sh

**Files:**

- Create: `art/LICENSE-art.txt`
- Modify: `build.sh`

- [ ] **Step 1: Write `art/LICENSE-art.txt`**

Path: `art/LICENSE-art.txt`

```text
The PNG files in this directory (plane.png, plane@2x.png, banner.png,
banner@2x.png, and any @3x variants) are derived from the Assets.xcassets
folder of https://github.com/conniexu444/meeting-reminder by Connie Xu
(@conniexu444) and are used here under the terms of that project's MIT
license, reproduced in full below.

---

MIT License

Copyright (c) 2025 Connie Xu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Note: if Connie's actual repo LICENSE has a different year or copyright holder spelling, copy that verbatim instead. To check:

```bash
curl -fsSL https://raw.githubusercontent.com/conniexu444/meeting-reminder/main/LICENSE 2>/dev/null || gh api repos/conniexu444/meeting-reminder | grep license
```

If no LICENSE file exists upstream, her README says "MIT — do what you want." — use the boilerplate above with year `2025`.

- [ ] **Step 2: Update `build.sh` to copy PNGs into Resources**

Find this block in `build.sh`:

```bash
# Install the Info.plist that tells macOS this is a real app bundle with
# calendar usage permission.
cp Info.plist "${APP_DIR}/Contents/Info.plist"
```

Insert immediately BEFORE that block:

```bash
# Copy art assets into the bundle's Resources directory.
cp art/*.png "${RES_DIR}/"
```

- [ ] **Step 3: Build and verify Resources are populated**

Run:

```bash
./build.sh
ls build/MeetingAirplane.app/Contents/Resources/
```

Expected: PNGs listed alongside any other resources.

---

## Task 20: Swap plane emoji + pastel banner for PNG art in OverlayController

**Files:**

- Modify: `Sources/OverlayController.swift`

- [ ] **Step 1: Read the current file to anchor the rewrite**

Run:

```bash
wc -l Sources/OverlayController.swift
```

Expected: ~150 lines (current state after v0.3).

- [ ] **Step 2: Replace the `show(...)` method body**

In `Sources/OverlayController.swift`, locate the entire `show(...)` method (starts with `func show(title:...` and ends at the closing `}` before `private func bannerText`). Replace it with this implementation:

```swift
    func show(title: String, startDate: Date? = nil, minutesUntil: Int, completion: (() -> Void)? = nil) {
        NSLog("[MeetingAirplane] show: title=\(title) minutesUntil=\(minutesUntil)")

        let mouse = NSEvent.mouseLocation
        let pick = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen = pick else {
            NSLog("[MeetingAirplane] no screens — bailing")
            completion?()
            return
        }
        NSLog("[MeetingAirplane] using screen frame=\(screen.frame) (of \(NSScreen.screens.count) screens)")

        slideTimer?.invalidate()
        slideTimer = nil
        window?.orderOut(nil)
        window = nil

        let screenFrame = screen.frame

        // Build the content view, measure it, then size the window to fit.
        let content = makeContentView(title: title, startDate: startDate, minutesUntil: minutesUntil)
        let contentSize = content.fittingSize
        let windowHeight = contentSize.height
        let windowWidth = contentSize.width
        let yTop = screenFrame.maxY - windowHeight - 40

        let startFrame = NSRect(
            x: screenFrame.minX - windowWidth,
            y: yTop,
            width: windowWidth,
            height: windowHeight
        )

        let w = OverlayPanel(
            contentRect: startFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false
        w.contentView = content

        w.orderFrontRegardless()
        NSLog("[MeetingAirplane] window ordered front at \(startFrame)")

        window = w

        // Manual 60Hz slide + fade.
        let startX = startFrame.origin.x
        let endX = screenFrame.maxX
        let duration = config.slideDuration
        let fadeDuration = config.fadeDuration
        let fadeStart = max(0.0, (duration - fadeDuration) / duration)
        let t0 = Date()
        slideTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self, weak w] timer in
            guard let w = w else {
                timer.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(t0)
            let progress = min(1.0, elapsed / duration)
            let x = startX + (endX - startX) * CGFloat(progress)
            w.setFrameOrigin(NSPoint(x: x, y: yTop))

            if progress >= fadeStart {
                let fadeProgress = (progress - fadeStart) / max(0.0001, 1.0 - fadeStart)
                w.alphaValue = CGFloat(max(0.0, 1.0 - fadeProgress))
            }

            if progress >= 1.0 {
                timer.invalidate()
                NSLog("[MeetingAirplane] slide done")
                self?.slideTimer = nil
                self?.window?.orderOut(nil)
                self?.window = nil
                completion?()
            }
        }
    }
```

- [ ] **Step 3: Add the `makeContentView` helper**

Add this new private method to `OverlayController` (place it directly above the existing `private func bannerText` method):

```swift
    /// Builds a content view: banner.png-backed label on the left, plane.png
    /// NSImageView on the right. Sized via Auto Layout; caller asks for
    /// `fittingSize` to size the window.
    private func makeContentView(title: String, startDate: Date?, minutesUntil: Int) -> NSView {
        let planeSize: CGFloat = 220
        let bannerVerticalInset: CGFloat = 35      // top + bottom padding inside the banner PNG (visual rope/ribbon shape)
        let bannerHorizontalInset: CGFloat = 50    // left + right padding inside the banner PNG
        let textHorizontalPadding: CGFloat = 50
        let textVerticalPadding: CGFloat = 22
        let stackOverlap: CGFloat = -10            // negative spacing — plane overlaps banner so rope tucks behind

        let bannerImage = NSImage(named: "banner")
        let planeImage = NSImage(named: "plane")

        // Comic Sans MS, fallback to bold system font if absent.
        let font = NSFont(name: "Comic Sans MS", size: 28)
            ?? NSFont.systemFont(ofSize: 28, weight: .bold)

        let label = NSTextField(labelWithString: bannerText(title: title, startDate: startDate, minutesUntil: minutesUntil))
        label.font = font
        label.textColor = .white
        label.alignment = .center
        label.backgroundColor = .clear
        label.drawsBackground = false
        label.isBezeled = false
        label.isEditable = false
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false

        // Banner container — uses the banner PNG as its layer contents so it
        // stretches behind the label.
        let banner = NSView()
        banner.wantsLayer = true
        banner.layer?.contentsGravity = .resize
        if let img = bannerImage {
            banner.layer?.contents = img
        } else {
            // Asset missing: visible regression so we don't ship invisibly.
            banner.layer?.backgroundColor = NSColor(calibratedRed: 0.95, green: 0.55, blue: 0.65, alpha: 1.0).cgColor
        }
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)

        let plane = NSImageView()
        plane.image = planeImage
        plane.imageScaling = .scaleProportionallyUpOrDown
        plane.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        container.addSubview(plane)

        NSLayoutConstraint.activate([
            // Plane on the right, fixed size, vertically centered.
            plane.widthAnchor.constraint(equalToConstant: planeSize),
            plane.heightAnchor.constraint(equalToConstant: planeSize),
            plane.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            plane.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            // Banner on the left, hugging the plane with negative overlap so
            // the rope tucks behind it.
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: plane.leadingAnchor, constant: stackOverlap),
            banner.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            // Label inside banner, padded.
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: textHorizontalPadding + bannerHorizontalInset),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -(textHorizontalPadding + bannerHorizontalInset)),
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: textVerticalPadding + bannerVerticalInset),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -(textVerticalPadding + bannerVerticalInset)),

            // Container has a fixed height = plane height; width is driven by
            // banner+plane content.
            container.heightAnchor.constraint(equalToConstant: planeSize),
        ])

        return container
    }
```

- [ ] **Step 4: Build**

Run:

```bash
./build.sh
```

Expected: success.

- [ ] **Step 5: Manual test — visual**

Run:

```bash
./build/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

Expected: pink banner with white "Test Meeting — Standup with Engineering · 10:00 AM · in 5 min" text in Comic Sans, hand-drawn plane on the right, slides left-to-right across cursor's screen, fades at end.

- [ ] **Step 6: Remove now-unused v0.1 pastel constants**

The PNG-based design no longer uses the pastel sky-blue palette. Find these two properties at the top of `OverlayController` (they were the pre-v0.4 banner colors):

```swift
    // Soothing pastel palette.
    private let bannerFill = NSColor(calibratedRed: 0.78, green: 0.88, blue: 0.96, alpha: 0.95) // pastel sky blue
    private let bannerTextColor = NSColor(calibratedRed: 0.12, green: 0.20, blue: 0.36, alpha: 1.0) // soft navy
```

Delete both lines. Rebuild to confirm nothing else references them.

Run:

```bash
./build.sh
```

Expected: success, no warnings about unused properties.

- [ ] **Step 7: If plane has rope/banner pre-drawn and visual is misaligned**

The `bannerVerticalInset` / `bannerHorizontalInset` constants in `makeContentView` are tunable. The banner PNG visual edge often sits well inside the PNG's transparent margin. Adjust both insets (try 25–60 range) until the text sits centered in the visible pink portion. Rebuild + retest after each tweak.

---

## Task 21: Add Credits section to README

**Files:**

- Modify: `README.md`

- [ ] **Step 1: Append the Credits section at the bottom of `README.md`**

Add this block at the end of `README.md`:

```markdown
## Credits

Plane and banner artwork by [@conniexu444](https://github.com/conniexu444),
borrowed from [meeting-reminder](https://github.com/conniexu444/meeting-reminder)
under the MIT License. Full license text in [`art/LICENSE-art.txt`](art/LICENSE-art.txt).
```

- [ ] **Step 2: Verify the link to the art license**

Run:

```bash
grep -c "art/LICENSE-art.txt" README.md
```

Expected: at least `1`.

---

## Task 22: Reinstall onto launchd + final integration check

**Files:** none

- [ ] **Step 1: Reinstall**

Run:

```bash
./install.sh
```

Expected: build succeeds, app copied to `~/Applications/`, launchd reloads, agent is running.

- [ ] **Step 2: Verify launchd agent is alive**

Run:

```bash
launchctl list | grep meetingairplane
```

Expected: a non-zero PID + label `com.user.meetingairplane`.

- [ ] **Step 3: Trigger the installed binary**

Run:

```bash
~/Applications/MeetingAirplane.app/Contents/MacOS/MeetingAirplane --test
```

Expected: banner with PNG plane + PNG banner + Comic Sans text slides + fades on cursor's screen.

---

## Task 23: Commit + tag v0.4.0

**Files:** none

- [ ] **Step 1: Stage all v0.4 changes**

Run:

```bash
git add art/ build.sh Sources/OverlayController.swift README.md
```

- [ ] **Step 2: Verify staged set includes PNGs**

Run:

```bash
git status --short
```

Expected: `art/plane.png`, `art/banner.png`, `art/LICENSE-art.txt`, `build.sh`, `Sources/OverlayController.swift`, `README.md` listed as `A` or `M`.

- [ ] **Step 3: Commit**

Run:

```bash
git commit -m "v0.4: custom plane + banner PNG art (from conniexu444/meeting-reminder, MIT)"
```

- [ ] **Step 4: Tag and push**

Run:

```bash
git tag -a v0.4.0 -m "v0.4.0 — custom plane art"
git push origin main v0.4.0
```

Expected: tag + branch pushed.

---

# Done

After Task 23 the repo is live at `https://github.com/aam11/meeting-airplane` with tags `v0.1.0`, `v0.2.0`, `v0.3.0`, `v0.4.0`, and the installed launchd agent is running the latest binary with PNG art.
