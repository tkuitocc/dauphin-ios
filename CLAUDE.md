# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dauphin is an iOS app for Tamkang University students, built using SwiftUI and following the MVVM architecture pattern. The app provides course schedules, library services, event management, and student ID barcode generation through both the main app and widget extensions.

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (iOS 16.6+, with iOS 18 TabView support)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS**: iOS 16.6 (main app), iOS 17.0+ (widgets)
- **Dependencies** (Swift Package Manager):
  - KeychainSwift (v24.0.0+) - Secure credential storage
  - Lottie (v4.5.1+) - Animation support
  - Reachability.swift (master) - Network status monitoring
  - SwiftUI-Code39 (v1.1.0+) - Barcode generation for student IDs

## Build Configuration

- **App Version**: 1.1.3
- **Bundle IDs**:
  - Production: `cantpr09ram.dauphin`
  - Development: `cantpr09ram.dauphin.dev`
- **Build Schemes**: `dauphin` (production), `dauphin Beta` (development)
- **Asset Catalogs**: Separate for production (`Assets.xcassets`) and development (`AssetsDev.xcassets`)

## Build Commands

```bash
# Build the project
xcodebuild -scheme dauphin -configuration Debug build

# Build for release
xcodebuild -scheme dauphin -configuration Release build

# Build Beta version
xcodebuild -scheme "dauphin Beta" -configuration Debug build

# Clean build folder
xcodebuild -scheme dauphin clean

# Run on simulator
xcodebuild -scheme dauphin -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build widgets
xcodebuild -scheme CoursesWidgetExtension -configuration Debug build
```

## Project Structure

```
dauphin/
├── dauphin/                    # Main app target
│   ├── Models/                 # Data models and API structures
│   │   ├── API.swift          # API response models
│   │   ├── Course.swift       # Course data models
│   │   ├── Event.swift        # Event models
│   │   └── CourseColors.swift # Color management for courses
│   ├── View/                  # SwiftUI Views
│   │   ├── CourseSchedule/    # Course schedule views
│   │   ├── Other/            # Other features (Library, Events)
│   │   ├── Setting/          # Settings screens
│   │   └── Loading/          # Launch and loading screens
│   ├── ViewModels/           # MVVM ViewModels
│   │   ├── AuthViewModel.swift
│   │   ├── CourseViewModel.swift
│   │   └── EventViewModel.swift
│   ├── Utilities/            # Helper classes and utilities
│   │   ├── KeychainManager.swift  # Keychain operations
│   │   ├── Encrypto.swift        # AES encryption utilities
│   │   ├── EventManager.swift    # Event handling
│   │   └── Constants.swift       # App constants
│   ├── ContentView.swift     # Main TabView container
│   ├── dauphinApp.swift      # App entry point
│   └── IntroScreenView.swift  # First-time user introduction
├── CoursesWidget/            # Widget extension for course schedule
└── StdID/                    # Widget extension for student ID barcode
```

## Key Architecture Patterns

1. **MVVM Pattern**: ViewModels (`@StateObject`, `@ObservedObject`) manage state and business logic separate from views.

2. **App Entry Flow**:
   - `dauphinApp.swift` (struct `MyApp`) loads API keys asynchronously on launch
   - Shows `LaunchScreenView` during initialization
   - Transitions to `ContentView` once keys are loaded
   - Conditional support for iOS 18's new TabView API

3. **Tab-based Navigation**: Main app uses TabView with three sections:
   - Course Schedule
   - Other (Library, Events)
   - Settings

4. **Widget Extensions**: Two widget extensions provide quick access:
   - `CoursesWidgetExtension`: Shows upcoming courses (iOS 17.0+)
   - `StdIDExtension`: Displays student ID barcode (iOS 17.6+)

5. **Data Sharing**: Uses App Groups (`group.cantpr09ram.dauphin`) for sharing data between main app and widgets.

6. **Secure Storage**: KeychainSwift stores credentials and API keys. AuthViewModel manages authentication state across app and widgets.

7. **Network Layer**: API models handle encrypted responses using AES encryption (`Encrypto.swift`).

8. **Logging**: Uses OSLog for structured logging throughout the codebase.

## API Configuration

- **API Keys**: Store in `api.plist` (gitignored). Use `api.example.plist` as template.
- **Key Loading**: `KeyConstants.swift` handles secure API key loading from plist.
- **Encryption**: AES encryption for API responses via `Encrypto.swift`.

## Development Notes

- **Localization**: Supports English and Traditional Chinese (zh-Hant) via `Localizable.xcstrings`
- **VS Code Integration**: Configured with Swift file associations and LLDB debugger
- **Permissions**: Calendar access for event management
- **Animation**: Lottie animations for loading screens
- **Network Monitoring**: Reachability.swift for offline support
- **Development Branch**: Active development on `dev` branch