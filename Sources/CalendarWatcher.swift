import Foundation
import EventKit

/// Polls EventKit every `pollSeconds` and fires `onMeetingSoon` once per event
/// when that event is about to start (within `leadMinutes`).
///
/// Deduplication: we track event identifiers we've already fired for, so a
/// meeting near the lead window only triggers a single airplane.
final class CalendarWatcher {
    private let store = EKEventStore()
    private var timer: Timer?
    private var firedEventKeys = Set<String>()

    var onMeetingSoon: ((EKEvent) -> Void)?

    /// How many minutes before the meeting we trigger the animation.
    var leadMinutes: Int = 5

    /// How often we re-check the calendar.
    var pollSeconds: TimeInterval = 30

    func start() {
        requestAccess { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                NSLog("[MeetingAirplane] Calendar access denied. Grant it in System Settings → Privacy & Security → Calendars.")
                return
            }
            DispatchQueue.main.async {
                self.check()
                self.timer = Timer.scheduledTimer(withTimeInterval: self.pollSeconds, repeats: true) { [weak self] _ in
                    self?.check()
                }
            }
        }
    }

    private func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, error in
                if let error = error {
                    NSLog("[MeetingAirplane] Calendar access error: \(error)")
                }
                completion(granted)
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                if let error = error {
                    NSLog("[MeetingAirplane] Calendar access error: \(error)")
                }
                completion(granted)
            }
        }
    }

    private func check() {
        let now = Date()
        // Look two hours ahead so the predicate is cheap but always includes
        // the meeting we care about.
        let windowEnd = now.addingTimeInterval(60 * 60 * 2)
        let predicate = store.predicateForEvents(withStart: now, end: windowEnd, calendars: nil)
        let events = store.events(matching: predicate)

        for event in events {
            // Skip all-day events — they don't have a meaningful "starts in N min".
            if event.isAllDay { continue }

            let key = makeKey(for: event)
            if firedEventKeys.contains(key) { continue }

            let minutesUntil = event.startDate.timeIntervalSince(now) / 60.0
            // Fire if the meeting is upcoming and within the lead window.
            // (If the app started up with only 3 min until a meeting, we still
            // fire — better late than missed.)
            if minutesUntil > 0 && minutesUntil <= Double(leadMinutes) {
                firedEventKeys.insert(key)
                onMeetingSoon?(event)
            }
        }

        // Don't let the dedup set grow forever.
        if firedEventKeys.count > 500 {
            firedEventKeys.removeAll()
        }
    }

    private func makeKey(for event: EKEvent) -> String {
        // Identifier + start time handles recurring events correctly: each
        // occurrence has the same identifier but a distinct start date.
        let id = event.eventIdentifier ?? "unknown"
        return "\(id)|\(event.startDate.timeIntervalSince1970)"
    }

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
}
