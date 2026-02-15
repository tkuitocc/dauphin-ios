# Dauphin

[![.github/workflows/ci.yml](https://github.com/tkuitocc/dauphin-ios/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/tkuitocc/dauphin-ios/actions/workflows/ci.yml)

[![pages-build-deployment](https://github.com/tkuitocc/dauphin-ios/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/tkuitocc/dauphin-ios/actions/workflows/pages/pages-build-deployment)

## Overview
Dauphin is an iOS app with a companion Widget extension. The codebase is organized by feature and backed by XCTest coverage.

## Requirements
- Xcode 15.4 or newer
- iOS Simulator (iPhone 15 or newer recommended)
- Swift 5.9+

## Getting Started
1. Clone the repo.
2. Open `dauphin.xcodeproj` in Xcode.
3. Select the `dauphin` scheme and build/run.

## Common Commands
```sh
xcodebuild -project dauphin.xcodeproj -scheme "dauphin" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' clean build
```

```sh
xcodebuild test -scheme dauphin -destination 'platform=iOS Simulator,name=iPhone 15'
```

```sh
swift-format lint --configuration .swift-format --recursive .
```

```sh
xcrun simctl install booted build/Debug-iphonesimulator/dauphin.app
```

## Project Structure
- `dauphin/`: iOS app sources (views, view models, utilities).
- `CoursesWidget/`: Widget extension.
- `Tests/`: Unit and snapshot tests.
- Root configs: `api.plist`, `StdID` (sample values only).

## Contributing
- Keep SwiftLint warnings at zero.
- Add or update tests for behavior changes.
- Run lint and tests before opening a PR.
