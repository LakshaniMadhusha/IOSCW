// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LibraryApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "LibraryApp",
            targets: ["LibraryApp"]
        )
    ],
    dependencies: [
        // Temporarily remove Firebase to test basic compilation
        // .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "11.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "LibraryApp",
            dependencies: [
                // Temporarily remove Firebase dependencies
                // .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                // .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "LibraryApp",
            exclude: ["Assets.xcassets", "GoogleService-Info.plist"], // Exclude resources for now
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"]) // Allow @main in library
            ]
        )
    ]
)