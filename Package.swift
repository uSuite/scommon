// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "scommon",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "SCommon",
            targets: ["SCommon"]
        ),
    ],
    targets: [
        .target(
            name: "SCommon"
        ),
        .testTarget(
            name: "SCommonTests",
            dependencies: ["SCommon"]
        ),
    ]
)
