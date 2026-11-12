import AppKit

struct MagnifierGeometry {
    static func captureRegion(pixel: CGRect, screenSize: CGSize) -> CGRect {
        let side = min(15, screenSize.width, screenSize.height)
        return CGRect(x: min(max(0, pixel.minX - 7), screenSize.width - side),
                      y: min(max(0, pixel.minY - 7), screenSize.height - side),
                      width: side, height: side)
    }

    static func frame(mouse: CGPoint, screen: CGRect) -> CGRect {
        let size = CGSize(width: 180, height: 212)
        var x = mouse.x + 24
        if x + size.width > screen.maxX { x = mouse.x - size.width - 24 }
        return CGRect(x: max(screen.minX, x),
                      y: min(max(screen.minY, mouse.y - size.height - 24), screen.maxY - size.height),
                      width: size.width, height: size.height)
    }
}

@MainActor
final class MagnifierOverlay {
    private let lens = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    private let target = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    private let lensView = LensView()

    init() {
        for panel in [lens, target] {
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.ignoresMouseEvents = true
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
        }
        lens.title = "Color magnifier"
        target.title = "Sampling target"
        lens.contentView = lensView
        target.contentView = TargetView()
    }

    var windowIDs: Set<CGWindowID> { Set([CGWindowID(lens.windowNumber), CGWindowID(target.windowNumber)]) }

    func show() {
        move(mouse: NSEvent.mouseLocation)
        lens.orderFrontRegardless()
        target.orderFrontRegardless()
    }

    func hide() {
        lens.orderOut(nil)
        target.orderOut(nil)
    }

    func move(mouse: CGPoint) {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) else { return }
        lens.setFrame(MagnifierGeometry.frame(mouse: mouse, screen: screen.visibleFrame), display: true)
        target.setFrame(CGRect(x: mouse.x - 12, y: mouse.y - 12, width: 24, height: 24), display: true)
    }

    func update(image: CGImage, pixel: CGPoint, hex: String) {
        lensView.image = image
        lensView.pixel = pixel
        lensView.hex = hex
        lensView.needsDisplay = true
    }
}

@MainActor
private final class LensView: NSView {
    var image: CGImage?
    var pixel = CGPoint.zero
    var hex = ""

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.9).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12).fill()
        guard let image else { return }
        let area = CGRect(x: 8, y: 40, width: 164, height: 164)
        NSGraphicsContext.current?.imageInterpolation = .none
        NSImage(cgImage: image, size: .zero).draw(in: area)
        let cell = CGSize(width: area.width / CGFloat(image.width), height: area.height / CGFloat(image.height))
        let selection = CGRect(x: area.minX + pixel.x * cell.width,
                               y: area.maxY - (pixel.y + 1) * cell.height,
                               width: cell.width, height: cell.height)
        NSColor.black.setStroke()
        let outer = NSBezierPath(rect: selection.insetBy(dx: -1, dy: -1))
        outer.lineWidth = 3
        outer.stroke()
        NSColor.white.setStroke()
        let inner = NSBezierPath(rect: selection)
        inner.lineWidth = 1
        inner.stroke()
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: 16, weight: .medium), .foregroundColor: NSColor.white]
        let text = hex as NSString
        text.draw(at: CGPoint(x: (bounds.width - text.size(withAttributes: attributes).width) / 2, y: 12), withAttributes: attributes)
    }
}

@MainActor
private final class TargetView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        for (a, b) in [(CGPoint(x: 0, y: 12), CGPoint(x: 8, y: 12)),
                       (CGPoint(x: 16, y: 12), CGPoint(x: 24, y: 12)),
                       (CGPoint(x: 12, y: 0), CGPoint(x: 12, y: 8)),
                       (CGPoint(x: 12, y: 16), CGPoint(x: 12, y: 24))] {
            path.move(to: a); path.line(to: b)
        }
        NSColor.black.setStroke(); path.lineWidth = 3; path.stroke()
        NSColor.white.setStroke(); path.lineWidth = 1; path.stroke()
    }
}
