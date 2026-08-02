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
            url: "https://github.com/michaelleechoicetech/CTKCHPSDK-iOS/releases/download/v1.0.45/CTKCHPSDK.xcframework.zip",
            checksum: "f0af5d912ae28733cb883b9fe2ccf04aad32ae96b36c07a1f1a2d29f1dc743ca"
        )
    ]
)
