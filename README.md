# Mosaic

Mosaic is based on Rectangle which is based on Spectacle.

Mosaic uses [Swift Package Manager](https://www.swift.org/documentation/package-manager/) to pull in [MASShortcut](https://github.com/shpakovski/MASShortcut) (pinned to the final upstream commit, since the repo is archived). Xcode resolves it automatically.

1. Open the project (`open Mosaic.xcodeproj`).
1. Build and run the `Mosaic` scheme. Requires macOS 12 or later.

Run the tests with ⌘U in Xcode, or `xcodebuild test -project Mosaic.xcodeproj -scheme Mosaic`. They cover the window layout rules and don't launch the app.

#### Signing
- When running in Xcode (debug), Mosaic is signed to run locally with no developer ID configured.
- You can run the app out of the box this way, but you might have to authorize the app in System Prefs every time you run it. 
- If you don't want to authorize in System Prefs every time you run it and you have a developer ID set up, you'll want to use that to sign it and additionally add the Hardened Runtime capability to the Mosaic and MosaicLauncher targets.