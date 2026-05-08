// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "LibraryApp",
            targets: ["LibraryApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "11.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "LibraryApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "LibraryApp",
            exclude: ["Assets.xcassets", "GoogleService-Info.plist"], // Exclude resources for now
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"]) // Allow @main in library
            ]
        ),
        .testTarget(
            name: "LibraryAppTests",
            dependencies: ["LibraryApp"],
            path: "Tests/LibraryAppTests"
        )
    ]
)