// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Voip",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Voip",
            targets: ["Voip"])
    ],
    dependencies: [
        .package(url: "https://github.com/chebur/pjsip.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Voip",
            dependencies: [.product(name: "PJSIP", package: "pjsip")])
    ]
)