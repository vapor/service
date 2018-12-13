// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "service-kit",
    products: [
        .library(name: "ServiceKit", targets: ["ServiceKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .branch("master"))
    ],
    targets: [
        .target(name: "ServiceKit", dependencies: ["NIO"]),
        .testTarget(name: "ServiceKitTests", dependencies: ["ServiceKit"]),
    ]
)
