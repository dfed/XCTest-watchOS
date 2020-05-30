// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCTest-watchOS",
    platforms: [
        .watchOS(.v2),
    ],
    products: [
        .library(
            name: "XCTest",
            targets: ["XCTest"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "XCTest",
            dependencies: []),
    ],
    swiftLanguageVersions: [.v4, .v4_2, .v5]
)
