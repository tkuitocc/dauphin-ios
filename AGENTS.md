# Repository Guidelines

## Project Structure & Module Organization
- `dauphin/` hosts the iOS app sources, grouped by feature (e.g., `ViewModels/`, `View/`, `Utilities/`).
- `CoursesWidget/` contains the Widget extension with its own views and timeline provider.
- `Tests/` mirrors production modules for unit and snapshot coverage; place new tests beside the feature they validate.
- Shared assets and configuration artifacts (e.g., `api.plist`, `StdID`) sit at the repository root—never bake secrets into code.

## Build, Test, and Development Commands
- `xcodebuild -project dauphin.xcodeproj -scheme "dauphin" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' clean build` compiles the main app target.
- `xcodebuild test -scheme dauphin -destination 'platform=iOS Simulator,name=iPhone 15'` executes the XCTest suite in `Tests/`.
- `swift-format lint --configuration .swift-format --recursive .` enforces the project’s Swift style rules; run before committing to avoid CI lint failures.
- `xcrun simctl install booted build/Debug-iphonesimulator/dauphin.app` deploys the latest simulator build for manual QA.

## Coding Style & Naming Conventions
- Use four-space indentation and camelCase identifiers (`courseViewModel`, not `course_vm`).
- Decode external snake_case payloads via `CodingKeys` while exposing camelCase API on models.
- Keep `SwiftLint` warnings at zero; annotate any rule suppression with a rationale comment.
- Organize larger files with `// MARK:` blocks to surface logical sections in Xcode’s navigator.

## Testing Guidelines
- XCTest is the primary harness; suffix new files with `Tests` (e.g., `CourseViewModelTests`).
- Favor deterministic tests—wrap async paths with expectations and sub-five-second timeouts.
- Run `xcodebuild test` before every pull request and refresh baseline snapshots if UI output changes.

## Commit & Pull Request Guidelines
- Write imperative, scoped commit messages (e.g., `fix: resolve SwiftLint warnings in CourseViewModel`). Squash transient WIP commits pre-review.
- Pull requests must summarize behavioral changes, document test coverage, and link Jira/GitHub issues. Attach screenshots or screen recordings for UI updates.
- Ensure CI passes (build, lint, tests) and rebase onto the latest main branch before requesting review.

## Security & Configuration Tips
- Secrets live in `api.plist` and load through `KeyConstants`; commit only sample values.
