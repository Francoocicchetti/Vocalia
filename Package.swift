// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "FrancoTranscribe", platforms: [.macOS("26.0")], dependencies: [.package(path: "Vendor/Argmax")], targets: [.executableTarget(name: "Transcribe", dependencies: [.product(name: "WhisperKit", package: "Argmax"), .product(name: "SpeakerKit", package: "Argmax")], path: ".", exclude: ["Vendor"], sources: ["Transcribe.swift", "Advanced.swift", "LocalEngines.swift", "Localization.swift"])])
