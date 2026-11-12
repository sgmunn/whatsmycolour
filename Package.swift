// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WhatsMyColour",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "WhatsMyColour", targets: ["WhatsMyColour"])],
    targets: [
        .executableTarget(name: "WhatsMyColour"),
        .testTarget(name: "WhatsMyColourTests", dependencies: ["WhatsMyColour"])
    ]
)
