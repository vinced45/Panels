// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Panels",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "Panels",
            targets: ["Panels"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Panels",
            dependencies: []
        ),
        .testTarget(
            name: "PanelsTests",
            dependencies: ["Panels"]
        ),
    ]
)
