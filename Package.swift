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
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/v1.0.33/CTKCHPSDK.xcframework.zip",
            checksum: "f2c6773fda82c1e46c3aaeb39f2e7617cff71cab9afd496d4c9623e69e7b9e28"
        )
    ]
)
