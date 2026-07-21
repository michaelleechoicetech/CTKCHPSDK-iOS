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
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/v1.0.19/CTKCHPSDK.xcframework.zip",
            checksum: "3c28404f9bf7d02dcc5962f7c41ce73b9fcba4c6948c4cf99243dd4310b8588c"
        )
    ]
)
