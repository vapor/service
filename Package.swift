// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "service-kit",
    products: [
        .library(name: "ServiceKit", targets: ["ServiceKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0-convergence"),
    ],
    targets: [
        .target(name: "ServiceKit", dependencies: ["NIO"]),
        .testTarget(name: "ServiceKitTests", dependencies: ["ServiceKit"]),
    ]
)
