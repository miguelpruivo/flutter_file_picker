// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "file_picker",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "file-picker", targets: ["file_picker"])
    ],
    dependencies: [
        .package(url: "https://github.com/zhangao0086/DKImagePickerController", branch: "4.3.9")
    ],
    targets: [
        .target(
            name: "file_picker",
            dependencies: [
                .product(name: "DKImagePickerController", package: "DKImagePickerController")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .headerSearchPath("include/file_picker"),
                .define("PICKER_MEDIA"),
                .define("PICKER_AUDIO"),
                .define("PICKER_DOCUMENT")
            ]
        )
    ]
)
