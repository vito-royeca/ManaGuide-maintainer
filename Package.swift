// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManaGuide-maintainer",
    platforms: [
        .macOS(.v11),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.2.2"),
        .package(url: "https://github.com/codewinsdotcom/PostgresClientKit", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "7.0.0-rc1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.2.7"),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.2.7"),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ManaGuide-maintainer",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),
                           "Kanna",
                           "PostgresClientKit",
                           .product(name: "PromiseKit", package: "PromiseKit"),
                           .product(name: "PMKFoundation", package: "PromiseKit"),
                           .product(name: "SwiftToolsSupport", package: "swift-tools-support-core")],
            resources: [ .process("keyrune-updates.plist"),
                         .process("mtgpics.json")]
        ),
        .testTarget(
            name: "ManaGuide-maintainerTests",
            dependencies: ["ManaGuide-maintainer",
                           .product(name: "ArgumentParser", package: "swift-argument-parser"),
                           "Kanna",
                           "PostgresClientKit",
                           .product(name: "PromiseKit", package: "PromiseKit"),
                           .product(name: "PMKFoundation", package: "PromiseKit"),
                           .product(name: "SwiftToolsSupport", package: "swift-tools-support-core")]
        ),
    ]
)
