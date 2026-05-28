import AppKit

/// Non-activating NSPanel — never becomes key/main, so it cannot steal focus.
private final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Plane glyph + rounded pastel banner, sliding across the screen.
///
/// Window is transparent — only the plane emoji and the rounded banner show.
/// All visible elements are NSTextField / layer-backed NSView (no custom
/// draw), since custom draw inside layer-backed parents has been flaky on
/// recent macOS.
final class OverlayController {
    private let config: Config
    private var window: NSPanel?
    private var slideTimer: Timer?

    init(config: Config) {
        self.config = config
    }

    // Soothing pastel palette.
    private let bannerFill = NSColor(calibratedRed: 0.78, green: 0.88, blue: 0.96, alpha: 0.95) // pastel sky blue
    private let bannerTextColor = NSColor(calibratedRed: 0.12, green: 0.20, blue: 0.36, alpha: 1.0) // soft navy

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
        let windowWidth: CGFloat = 760
        let windowHeight: CGFloat = 130
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
        // Above-everything level. Higher than .screenSaver so it survives
        // Mission Control/screensaver transitions. Fall back to .screenSaver
        // if a future macOS suppresses this.
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        // Click-through: mouse events fall to whatever's underneath.
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false

        // Content: transparent NSView containing plane glyph + rounded banner.
        let content = NSView(frame: NSRect(origin: .zero, size: startFrame.size))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.clear.cgColor

        // --- Plane glyph (left column) ---
        let planeColumnWidth: CGFloat = 130
        let planeLabel = NSTextField(labelWithString: "\u{2708}\u{FE0F}")
        planeLabel.font = NSFont.systemFont(ofSize: 90)
        planeLabel.alignment = .center
        planeLabel.backgroundColor = .clear
        planeLabel.drawsBackground = false
        planeLabel.isBezeled = false
        planeLabel.isEditable = false
        planeLabel.translatesAutoresizingMaskIntoConstraints = false

        // --- Rounded pastel banner (right side) ---
        let banner = NSView()
        banner.wantsLayer = true
        banner.layer?.backgroundColor = bannerFill.cgColor
        banner.layer?.cornerRadius = 18
        banner.layer?.shadowColor = NSColor.black.cgColor
        banner.layer?.shadowOpacity = 0.18
        banner.layer?.shadowOffset = CGSize(width: 0, height: -2)
        banner.layer?.shadowRadius = 6
        banner.layer?.masksToBounds = false
        banner.translatesAutoresizingMaskIntoConstraints = false

        let textLabel = NSTextField(labelWithString: bannerText(title: title, startDate: startDate, minutesUntil: minutesUntil))
        textLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        textLabel.textColor = bannerTextColor
        textLabel.alignment = .center
        textLabel.backgroundColor = .clear
        textLabel.drawsBackground = false
        textLabel.isBezeled = false
        textLabel.isEditable = false
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        banner.addSubview(textLabel)
        content.addSubview(planeLabel)
        content.addSubview(banner)

        NSLayoutConstraint.activate([
            // Plane on the right (leading the flight), vertically centered.
            planeLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            planeLabel.widthAnchor.constraint(equalToConstant: planeColumnWidth),
            planeLabel.centerYAnchor.constraint(equalTo: content.centerYAnchor),

            // Banner trails behind on the left, with vertical padding.
            banner.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: planeLabel.leadingAnchor, constant: -8),
            banner.topAnchor.constraint(equalTo: content.topAnchor, constant: 28),
            banner.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -28),

            // Text centered inside banner, with horizontal padding.
            textLabel.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            textLabel.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 24),
            textLabel.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -24),
        ])

        w.contentView = content
        w.orderFrontRegardless()
        NSLog("[MeetingAirplane] window ordered front at \(startFrame)")

        window = w

        // Manual 60Hz slide + fade (NSWindow animator ignores duration on macOS 26).
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
    }

    private func bannerText(title: String, startDate: Date?, minutesUntil: Int) -> String {
        let mins = minutesUntil == 1 ? "in 1 min" : "in \(minutesUntil) min"
        if let startDate = startDate {
            let f = DateFormatter()
            f.timeStyle = .short
            f.dateStyle = .none
            return "\(title)  \u{2022}  \(f.string(from: startDate))  \u{2022}  \(mins)"
        }
        return "\(title)  \u{2022}  \(mins)"
    }
}
