// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AllurePlugin.emceeplugin",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [.executable(name: "Plugin", targets: ["AllurePlugin.emceeplugin"]),
               .library(name: "library", targets: ["AllurePlugin.emceeplugin"])],
    dependencies: [.package(name: "EmceeTestRunner",
                            url: "https://github.com/avito-tech/Emcee", .branch("12.0.0"))],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AllurePlugin.emceeplugin",
            dependencies: [.product(name: "EmceePlugin", package: "EmceeTestRunner")]),
        .testTarget(
            name: "AllurePlugin.emceepluginTests",
            dependencies: ["AllurePlugin.emceeplugin"]),
    ]
)
