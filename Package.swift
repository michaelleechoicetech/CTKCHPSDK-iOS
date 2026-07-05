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
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/1.0.0/CTKCHPSDK.xcframework.zip",
            checksum: "1f77c3e647caa77a5001503a381c8213b02a5415a693d9a02ec0a8c40bc07a5e"
        )
    ]
)
