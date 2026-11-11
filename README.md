# XCTest-watchOS

[![CI Status](https://img.shields.io/github/actions/workflow/status/dfed/XCTest-watchOS/ci.yml?branch=master)](https://github.com/dfed/XCTest-watchOS/actions?query=workflow%3ACI+branch%3Amaster)

XCTest-watchOS provides an implementation of XCTest that can run on watchOS. XCTest-watchOS allows you to run your library’s existing `XCTest` suite on watchOS with minimal effort.

## Getting Started

1. Create a new watchOS app
1. Include your test files in your new watchOS app extension
1. Install XCTest-watchOS, and link the included XCTest framework from your new watchOS app extension
1. Call `XCTestCase.runAllTestsAndExit()` from `applicationDidFinishLaunching` in your `WKExtensionDelegate` implementation in your new watchOS app extension
1. Run your new watchOS app, and see if your tests succeed

### CocoaPods

Versions through 0.0.2 remain available on CocoaPods. Newer releases will not be published to CocoaPods, so use one of the installation methods below.

### Carthage

Install with [Carthage](https://github.com/Carthage/Carthage) by adding the following to your `Cartfile`:

```ogdl
github "dfed/XCTest-watchOS"
```

Run `carthage` to build the framework and drag the built `XCTest.framework` into your Xcode project.

### Swift Package Manager

Install with [Swift Package Manager](https://github.com/apple/swift-package-manager) by adding the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dfed/XCTest-watchOS", from: "0.0.1"),
],
```

### Submodules

Or manually checkout the submodule with `git submodule add git@github.com:dfed/XCTest-watchOS.git`, drag `XCTest.xcodeproj` to your project, and add the `XCTest` framework as a build dependency of your test watch app.

## Requirements

* Xcode 9.0 or later.
* watchOS 2 or later.
