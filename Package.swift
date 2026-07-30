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
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/v1.0.32/CTKCHPSDK.xcframework.zip",
            checksum: "dd70e97a8509e0c956d088e6265fb3f1176eb7ef270b073ca0943d3e61adf1a3"
        )
    ]
)
