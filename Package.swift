// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "KIDCore",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "KIDCoreUI", targets: ["KIDCoreUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.11.0"),
    ],
    targets: [
        .target(name: "KIDCore", dependencies: [.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")]),
        .target(name: "KIDCoreUI", dependencies: ["KIDCore"], resources: [.copy("Resources/localization")]),
    ]
)
