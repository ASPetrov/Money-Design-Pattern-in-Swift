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
        .target(name: "MoneyFramework", path: "Packages/MoneyFramework/Sources/MoneyFramework"),
        .testTarget(
            name: "MoneyFrameworkTests",
            dependencies: ["MoneyFramework"],
            path: "Packages/MoneyFramework/Tests/MoneyFrameworkTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
