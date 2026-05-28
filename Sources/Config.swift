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
        // Always read from the explicit suite so `--test` runs (direct binary
        // invocation) and launchd runs (via the bundle) hit the same prefs.
        let d = UserDefaults(suiteName: "com.user.meetingairplane") ?? UserDefaults.standard
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
