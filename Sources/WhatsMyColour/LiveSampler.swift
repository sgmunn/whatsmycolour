import AppKit
import ScreenCaptureKit

/// AppKit uses bottom-left screen coordinates; capture regions use top-left display coordinates.
struct SamplingPoint {
    static func region(mouse: CGPoint, screen: CGRect) -> CGRect {
        CGRect(x: floor(mouse.x - screen.minX),
               y: min(screen.height - 1, max(0, floor(screen.maxY - mouse.y))), width: 1, height: 1)
    }
}

@MainActor
final class LiveSampler {
    private var task: Task<Void, Never>?

    func stop() {
        task?.cancel()
        task = nil
    }

    func start(update: @escaping @MainActor (NSColor) -> Void,
               failure: @escaping @MainActor (String) -> Void) {
        stop()
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            failure("Screen Recording permission is required. Enable What's My Colour in System Settings → Privacy & Security → Screen & System Audio Recording, then quit and reopen the app.")
            return
        }
        task = Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                while !Task.isCancelled {
                    let mouse = NSEvent.mouseLocation
                    if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }),
                       let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                       let display = content.displays.first(where: { $0.displayID == id.uint32Value }) {
                        let filter = SCContentFilter(display: display, excludingWindows: [])
                        let config = SCStreamConfiguration()
                        config.sourceRect = SamplingPoint.region(mouse: mouse, screen: screen.frame)
                        config.width = 1
                        config.height = 1
                        config.showsCursor = false
                        config.captureResolution = .best
                        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                        guard !Task.isCancelled else { return }
                        if let color = NSBitmapImageRep(cgImage: image).colorAt(x: 0, y: 0) {
                            update(color)
                        }
                    }
                    try await Task.sleep(for: .milliseconds(80))
                }
            } catch {
                guard !Task.isCancelled else { return }
                failure("Live sampling needs Screen Recording access. Enable What's My Colour in System Settings → Privacy & Security → Screen Recording, then try again.\n\(error.localizedDescription)")
            }
        }
    }
}
