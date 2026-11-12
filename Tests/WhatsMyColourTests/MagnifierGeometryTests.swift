import AppKit
import XCTest
@testable import WhatsMyColour

final class MagnifierGeometryTests: XCTestCase {
    func testCaptureCentersTargetAndClampsAtDisplayEdges() {
        let size = CGSize(width: 1920, height: 1080)
        XCTAssertEqual(MagnifierGeometry.captureRegion(pixel: CGRect(x: 100, y: 200, width: 1, height: 1), screenSize: size), CGRect(x: 93, y: 193, width: 15, height: 15))
        XCTAssertEqual(MagnifierGeometry.captureRegion(pixel: CGRect(x: 1919, y: 1079, width: 1, height: 1), screenSize: size), CGRect(x: 1905, y: 1065, width: 15, height: 15))
        XCTAssertEqual(MagnifierGeometry.captureRegion(pixel: .zero, screenSize: size).origin, .zero)
    }

    func testLensStaysOnNegativeOriginDisplay() {
        let screen = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        for point in [CGPoint(x: -1, y: 0), CGPoint(x: -1919, y: 1079)] {
            let frame = MagnifierGeometry.frame(mouse: point, screen: screen)
            XCTAssertTrue(screen.contains(frame))
            XCTAssertFalse(frame.contains(point))
        }
    }
}

final class MagnifierOverlayTests: XCTestCase {
    @MainActor
    func testOverlayWindowsAreVisibleClickThroughAndHideTogether() {
        _ = NSApplication.shared
        let overlay = MagnifierOverlay()
        overlay.show()
        defer { overlay.hide() }
        let windows = NSApp.windows.filter { overlay.windowIDs.contains(CGWindowID($0.windowNumber)) }
        XCTAssertEqual(windows.count, 2)
        XCTAssertTrue(windows.allSatisfy { $0.isVisible && $0.ignoresMouseEvents })
        overlay.hide()
        XCTAssertTrue(windows.allSatisfy { !$0.isVisible })
    }
}
