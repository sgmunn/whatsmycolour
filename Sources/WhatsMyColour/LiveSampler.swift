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
    private let overlay = MagnifierOverlay()
    private var task: Task<Void, Never>?

    func stop() {
        task?.cancel()
        task = nil
        overlay.hide()
    }

    func start(update: @escaping @MainActor (NSColor) -> Void,
               failure: @escaping @MainActor (String) -> Void) {
        stop()
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            failure("Screen Recording permission is required. Enable What's My Colour in System Settings → Privacy & Security → Screen & System Audio Recording, then quit and reopen the app.")
            return
        }
        overlay.show()
        task = Task { [overlay] in
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let excluded = content.windows.filter { overlay.windowIDs.contains($0.windowID) }
                while !Task.isCancelled {
                    let mouse = NSEvent.mouseLocation
                    overlay.move(mouse: mouse)
                    if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }),
                       let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                       let display = content.displays.first(where: { $0.displayID == id.uint32Value }) {
                        let filter = SCContentFilter(display: display, excludingWindows: excluded)
                        let config = SCStreamConfiguration()
                        let pixel = SamplingPoint.region(mouse: mouse, screen: screen.frame)
                        let region = MagnifierGeometry.captureRegion(pixel: pixel, screenSize: screen.frame.size)
                        config.sourceRect = region
                        config.width = Int(region.width * screen.backingScaleFactor)
                        config.height = Int(region.height * screen.backingScaleFactor)
                        config.showsCursor = false
                        config.captureResolution = .best
                        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                        guard !Task.isCancelled else { return }
                        let x = min(image.width - 1, Int((pixel.minX - region.minX) * CGFloat(image.width) / region.width))
                        let y = min(image.height - 1, Int((pixel.minY - region.minY) * CGFloat(image.height) / region.height))
                        if let color = NSBitmapImageRep(cgImage: image).colorAt(x: x, y: y) {
                            update(color)
                            overlay.update(image: image, pixel: CGPoint(x: x, y: y), hex: HexColor(color: color)?.string ?? "")
                        }
                    }
                    try await Task.sleep(for: .milliseconds(80))
                }
            } catch {
                guard !Task.isCancelled else { return }
                overlay.hide()
                failure("Live sampling needs Screen Recording access. Enable What's My Colour in System Settings → Privacy & Security → Screen Recording, then try again.\n\(error.localizedDescription)")
            }
        }
    }
}
