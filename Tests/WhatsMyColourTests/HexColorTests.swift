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
