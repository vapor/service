// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Service",
    products: [
        .library(name: "Service", targets: ["Service"]),
        .library(name: "Configs", targets: ["Configs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/mapper.git", .branch("beta")),
        .package(url: "https://github.com/vapor/core.git", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/vapor/debugging.git", .upToNextMajor(from: "1.1.0")),
    ],
    targets: [
        .target(name: "Service", dependencies: ["Configs", "Debugging", "Core"]),
        .testTarget(name: "ServiceTests", dependencies: ["Service"]),
        .target(name: "Configs", dependencies: ["Mapper"]),
        .testTarget(name: "ConfigsTests", dependencies: ["Configs"]),
    ]
)
