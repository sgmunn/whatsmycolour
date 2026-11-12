import AppKit
import XCTest
@testable import WhatsMyColour

final class HexColorTests: XCTestCase {
    func testHexFormattingAndRounding() {
        XCTAssertEqual(HexColor(color: NSColor(srgbRed: 1, green: 0.5, blue: 0, alpha: 1))?.string, "#FF8000")
        XCTAssertEqual(HexColor(color: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))?.string, "#000000")
        XCTAssertEqual(HexColor(color: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))?.string, "#FFFFFF")
    }

    func testConvertsGrayscaleAndIgnoresAlpha() {
        XCTAssertEqual(HexColor(color: NSColor(white: 0, alpha: 0.5))?.string, "#000000")
    }
}

final class SamplingPointTests: XCTestCase {
    func testConvertsMainDisplayCoordinates() {
        XCTAssertEqual(SamplingPoint.region(mouse: CGPoint(x: 120.7, y: 200.4), screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)), CGRect(x: 120, y: 879, width: 1, height: 1))
    }

    func testBottomEdgeStaysInsideDisplay() {
        XCTAssertEqual(SamplingPoint.region(mouse: CGPoint(x: 0, y: 0), screen: CGRect(x: 0, y: 0, width: 1920, height: 1080)).origin.y, 1079)
    }

    func testDisplayLeftAndAboveMainDisplay() {
        XCTAssertEqual(SamplingPoint.region(mouse: CGPoint(x: -1500, y: 1400), screen: CGRect(x: -1920, y: 1080, width: 1920, height: 1080)), CGRect(x: 420, y: 760, width: 1, height: 1))
    }
}
