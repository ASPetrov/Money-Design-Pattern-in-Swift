// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MoneyFramework",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "MoneyFramework", targets: ["MoneyFramework"]),
    ],
    targets: [
        .target(name: "MoneyFramework", path: "Sources"),
        .testTarget(
            name: "MoneyFrameworkTests",
            dependencies: ["MoneyFramework"],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
