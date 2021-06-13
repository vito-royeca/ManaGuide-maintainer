// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ManaGuide-maintainer",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.2.2"),
        //.package(url: "https://github.com/postmates/PMJSON.git", from: "3.0.1"),
        .package(url: "https://github.com/codewinsdotcom/PostgresClientKit", from: "1.0.0"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "7.0.0-rc1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ManaGuide-maintainer",
            dependencies: ["Kanna",
                           //"PMJSON",
                           "PostgresClientKit",
                           .product(name: "PromiseKit", package: "PromiseKit"),
                           .product(name: "PMKFoundation", package: "PromiseKit")]
        ),
        .testTarget(
            name: "ManaGuide-maintainerTests",
            dependencies: ["ManaGuide-maintainer",
                           "Kanna",
                           //"PMJSON",
                           "PostgresClientKit",
                           .product(name: "PromiseKit", package: "PromiseKit"),
                           .product(name: "PMKFoundation", package: "PromiseKit")]
        ),
    ]
)
