// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Service",
    products: [
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "Service", dependencies: ["Async", "Core", "Debugging"]),
        .testTarget(name: "ServiceTests", dependencies: ["Service"]),
    ]
)
