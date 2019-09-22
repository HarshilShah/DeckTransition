// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "DeckTransition",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "DeckTransition", targets: ["DeckTransition"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DeckTransition", dependencies: [], path: "Source"),
    ],
    swiftLanguageVersions: [.v5]
)
