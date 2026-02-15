# Repository Guidelines

## Structure
- `app/dauphin/` contains the iOS app sources, grouped by feature (views, view models, utilities).
- `app/CoursesWidget/` is the Widget extension with its own views and timeline provider.
- `app/Tests/` mirrors production modules for unit and snapshot coverage; place new tests beside the feature they validate.
- Shared assets and config artifacts (e.g., `api.plist`, `StdID`) live under `app/` or at the repo root. Never bake secrets into code.

## Build, Test, and Dev Commands
- Lint:
  `swift-format lint --configuration app/.swift-format --recursive .`
- Build app:
  `xcodebuild -project app/dauphin.xcodeproj -scheme "dauphin" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone xx,OS=xx.xx' clean build`
- Run tests:
  `xcodebuild -project app/dauphin.xcodeproj -scheme "dauphin" -destination 'platform=iOS Simulator,name=iPhone xx' test`
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
- Tests are not available yet, so skip `xcodebuild test` until the suite is added and note this in PRs.

## Commit and PRs
- Use imperative, scoped commit messages (e.g., `fix: resolve SwiftLint warnings in CourseViewModel`).
- Run pre-commit checks based on what changed:
  - Docs/config only (`README.md`, `AGENTS.md`, `.github/**`): no build/test required.
  - Swift code or assets (`app/dauphin/**`, `app/CoursesWidget/**`, `app/Tests/**`): run lint + build (tests once available).
  - Build system changes (`app/dauphin.xcodeproj/**`, `app/.swift-format`): run lint + build (tests once available).
- PRs must summarize behavior changes, document test coverage, and link Jira/GitHub issues.
- Attach screenshots or screen recordings for UI changes.
- Ensure CI passes (build, lint, tests) and rebase onto latest main before review.

## Pre-Commit Troubleshooting
- If `xcodebuild test` says no project/workspace found, ensure you run with `-project app/dauphin.xcodeproj` from repo root.

## Security
- Secrets live in `api.plist` and load through `KeyConstants`. Commit only sample values.
