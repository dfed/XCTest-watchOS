// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCTest",
    products: [
        .library(name: "XCTest", targets: ["XCTest"]),
    ],
    targets: [
        .target(name: "XCTest", path: "Sources"),
    ]
)
