// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Service",
    products: [
        .library(name: "Service", targets: ["Service"]),
    ],
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/async.git", "1.0.0-beta.1"..<"1.0.0-beta.2"),

        // A library to aid Vapor users with better debugging around the framework
        .package(url: "https://github.com/vapor/core.git", "3.0.0-beta.1"..<"3.0.0-beta.2"),
    ],
    targets: [
        .target(name: "Service", dependencies: ["Async", "Debugging"]),
        .testTarget(name: "ServiceTests", dependencies: ["Service"]),
    ]
)
