# Repository guide

MoneyFramework is a Swift implementation of the Money pattern for iOS. The library and its tests use Swift 6 language mode. The Swift package declares iOS 15 and macOS 12 as minimum deployment targets. The legacy Xcode project retains its original deployment settings.

- `Packages/MoneyFramework/Sources/` contains the library sources, including `Money`, currency definitions, decimal helpers, and conversion strategies. The CocoaPods spec also packages sources from this directory.
- `Packages/MoneyFramework/Tests/` contains the XCTest suites for money and currencies.
- `MoneyFramework/MoneyFramework.xcodeproj` contains the framework and test targets. `TestFrameworkApp/` contains the separate SwiftUI sample app.

## Build and test

Keep the root and nested `Packages/MoneyFramework/Package.swift` manifests aligned. The root manifest supports Git URL installation. The sample app uses the nested package. Run `swift test --package-path Packages/MoneyFramework` to check that entry point.

From the repository root, use `swift build`, `swift test list`, and `swift test` for the package. For iOS Simulator, use the package scheme and specify an available device and runtime.

```sh
xcodebuild -scheme MoneyFramework \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
  test
```

See [the baseline](Documentation/Baseline.md) for the legacy Xcode commands and the known formatted USD parsing failure.

## Library changes

Keep monetary calculations in `Decimal`. When changing arithmetic, allocation, or currency conversion, check how currency minor units and rounding affect the result. Exchange-rate inputs and conversion strategies belong in the existing conversion API. When adding Swift files, confirm that the applicable Xcode target includes them.

## Implementation plan

Follow the order and completion criteria in [the master specification](Documentation/Master-Specification.md). For behavior changes, start with a regression test that fails for the expected reason, make the minimal change, then run the affected suite before refactoring.

## Swift formatting

Follow the [Swift style policy](Documentation/Swift-Style.md). Use [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) with the repository's `.swiftformat`. Install it with `brew install swiftformat`. Run `swiftformat path/to/ChangedFile.swift` before staging Swift changes and review the formatting diff.

Enable the repository's optional pre-commit hook with `git config --local core.hooksPath .githooks`. If a hooks path is already configured, integrate this check with the existing hooks. The hook runs SwiftFormat in lint mode on staged Swift files, including partially staged files.

## Commit messages

Follow the [commit message policy](Documentation/Commit-Policy.md). Use Conventional Commits for new commits and validate with Commitizen. The tracked `commit-msg` hook shares `.cz.toml` with `cz commit` and uses the same hooks directory as the SwiftFormat check.
