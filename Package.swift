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
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/v1.0.20/CTKCHPSDK.xcframework.zip",
            checksum: "a9d73431a44c601aa9687c46c657232ff9cc9a9a8e53b4bb07d2eb5ffa6d7b0e"
        )
    ]
)
