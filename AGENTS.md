# Repository guide

MoneyFramework is a Swift implementation of the Money pattern for iOS and macOS. The library and its tests use Swift 6 language mode. The Swift package declares iOS 15 and macOS 12 as minimum deployment targets.

- `Packages/MoneyFramework/Sources/` contains the library sources, including `Money`, currency definitions, decimal helpers, and conversion strategies.
- `Packages/MoneyFramework/Tests/` contains Swift Testing unit suites and XCTest performance measurements.
- `TestFrameworkApp/` contains the SwiftUI sample app, its Xcode project, and its tests.

## Build and test

Keep the root and nested `Packages/MoneyFramework/Package.swift` manifests aligned. The root manifest supports Git URL installation. The sample app uses the nested package. Run `swift test --package-path Packages/MoneyFramework` to check that entry point.

From the repository root, use `swift build`, `swift test list`, and `swift test` for the package. For iOS Simulator, use the package scheme and specify an available device and runtime.

```sh
xcodebuild -scheme MoneyFramework \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
  test
```

For the sample app, open `TestFrameworkApp/TestFrameworkApp.xcodeproj` and use its shared `TestFrameworkApp` scheme to run and test on an iOS simulator.

The app's Xcode test targets use iOS 17 to match the current XCTest runtime. The library and sample app deploy to iOS 15.

## Library changes

Keep monetary calculations in `Decimal`. When changing arithmetic, allocation, or currency conversion, check how currency minor units and rounding affect the result. Exchange-rate inputs and conversion strategies belong in the existing conversion API. Put library and package test files in their respective SPM target directories and check target membership when adding files to the sample app.

## Implementation plan

Check the [master specification](Documentation/Master-Specification.md) for outstanding work and completed stages. For behavior changes, start with a regression test that fails for the expected reason, make the minimal change, then run the affected suite before refactoring.

## Swift style and formatting

Follow the repository's adaptation of the Google Swift Style Guide. Use four spaces, aim for 120 columns, and omit `return` where a single expression can return implicitly. Put guard bodies on separate lines and start multiple conditions on the line after `guard`. Prefer clear names and retain comments that explain a non-obvious reason or a public contract. Follow the Swift API Design Guidelines for names, argument labels, units, and errors. [Swift style policy](Documentation/Swift-Style.md) · [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)

Use SwiftFormat with the repository's `.swiftformat`. Install it with `brew install swiftformat`. Run `swiftformat path/to/ChangedFile.swift` before staging Swift changes and review the formatting diff. [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)

Install SwiftLint with `brew install swiftlint` to check the 400-line limit. Enable the repository's optional pre-commit hook with `git config --local core.hooksPath .githooks`. If a hooks path is already configured, integrate these checks with the existing hooks. The hook runs SwiftFormat and SwiftLint on staged Swift content, including partially staged files.

## Agent skills

- Use `$swift-concurrency` for actor isolation, `Sendable`, and task cancellation work.
- Use `$swift-testing-expert` for test design. Use Swift Testing for functional unit tests and XCTest for UI automation and performance measurements.

## Commit messages

Follow the [commit message policy](Documentation/Commit-Policy.md). Use Conventional Commits for new commits and validate with Commitizen. The tracked `commit-msg` hook shares `.cz.toml` with `cz commit` and uses the same hooks directory as the SwiftFormat check.
