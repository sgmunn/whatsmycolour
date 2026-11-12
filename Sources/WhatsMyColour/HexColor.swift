import AppKit

struct HexColor {
    let red: Int
    let green: Int
    let blue: Int

    init?(color: NSColor) {
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        red = Self.byte(rgb.redComponent)
        green = Self.byte(rgb.greenComponent)
        blue = Self.byte(rgb.blueComponent)
    }

    private static func byte(_ component: CGFloat) -> Int {
        Int((min(1, max(0, component)) * 255).rounded())
    }

    var string: String { String(format: "#%02X%02X%02X", red, green, blue) }
}
