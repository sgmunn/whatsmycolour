import AppKit
import XCTest
@testable import WhatsMyColour

final class ColorModelTests: XCTestCase {
    @MainActor
    func testCancelStopsSamplingAndKeepsLastColor() {
        let model = ColorModel()
        model.color = .red
        model.sampling = true
        model.stopSampling()
        XCTAssertFalse(model.sampling)
        XCTAssertEqual(model.hex, "#FF0000")
        // Escape while already stopped must not restart sampling.
        model.stopSampling()
        XCTAssertFalse(model.sampling)
        XCTAssertEqual(model.hex, "#FF0000")
    }
}
