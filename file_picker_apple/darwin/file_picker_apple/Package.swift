// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "file_picker_apple",
    platforms: [
        .iOS("14.0"),
        .macOS("10.13")
    ],
    products: [
        .library(name: "file-picker-apple", targets: ["file_picker_apple"]),
    ],
    targets: [
        .target(name: "file_picker_apple", path: "Sources/file_picker_apple")
    ]
)