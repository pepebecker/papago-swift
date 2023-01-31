// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Papago",
    products: [
        .library(name: "Papago", targets: ["Papago"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Papago",
            dependencies: []
        ),
    ]
)
