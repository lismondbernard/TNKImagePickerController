// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "TNKImagePickerController",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "TNKImagePickerController",
            targets: ["TNKImagePickerController"]),
    ],
    dependencies: [
        // no dependencies
    ],
    targets: [
        .target(
            name: "TNKImagePickerController",
            dependencies: []),
    ]
)
