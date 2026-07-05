// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CTKCHPSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CTKCHPSDK",
            targets: ["CTKCHPSDK"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CTKCHPSDK",
            dependencies: [],
            path: "Sources/CTKCHPSDK"),
        .testTarget(
            name: "CTKCHPSDKTests",
            dependencies: ["CTKCHPSDK"],
            path: "Tests/CTKCHPSDKTests"),
    ]
)
