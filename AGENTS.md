# Repository Guidelines

## Structure
- `dauphin/` contains the iOS app sources, grouped by feature (views, view models, utilities).
- `CoursesWidget/` is the Widget extension with its own views and timeline provider.
- `Tests/` mirrors production modules for unit and snapshot coverage; place new tests beside the feature they validate.
- Shared assets and config artifacts (e.g., `api.plist`, `StdID`) live at the repo root. Never bake secrets into code.

## Build, Test, and Dev Commands
- Build app:
  `xcodebuild -project dauphin.xcodeproj -scheme "dauphin" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' clean build`
- Run tests:
  `xcodebuild test -scheme dauphin -destination 'platform=iOS Simulator,name=iPhone 15'`
- Lint:
  `swift-format lint --configuration .swift-format --recursive .`
- Install to simulator:
  `xcrun simctl install booted build/Debug-iphonesimulator/dauphin.app`

## Coding Style
- Four-space indentation and camelCase identifiers (`courseViewModel`, not `course_vm`).
- Decode external snake_case payloads via `CodingKeys` while exposing camelCase APIs on models.
- Keep SwiftLint warnings at zero; justify any rule suppression with a short rationale comment.
- Organize larger files with `// MARK:` blocks to aid navigation in Xcode.

## Testing
- XCTest is the primary harness; name new files with a `Tests` suffix.
- Prefer deterministic tests. Wrap async paths with expectations and sub-five-second timeouts.
- Run `xcodebuild test` before every PR and refresh baseline snapshots when UI output changes.

## Commit and PRs
- Use imperative, scoped commit messages (e.g., `fix: resolve SwiftLint warnings in CourseViewModel`).
- PRs must summarize behavior changes, document test coverage, and link Jira/GitHub issues.
- Attach screenshots or screen recordings for UI changes.
- Ensure CI passes (build, lint, tests) and rebase onto latest main before review.

## Security
- Secrets live in `api.plist` and load through `KeyConstants`. Commit only sample values.
