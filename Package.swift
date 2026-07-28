// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CTKCHPSDK-iOS",
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
        .binaryTarget(
            name: "CTKCHPSDK",
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/v1.0.28/CTKCHPSDK.xcframework.zip",
            checksum: "de3a92e5522bf2ade2bf1bb1769d9a6c460c96d9cf2c83f1cbebbfdd16d5d7e8"
        )
    ]
)
