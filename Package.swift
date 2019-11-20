// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Panels",
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
