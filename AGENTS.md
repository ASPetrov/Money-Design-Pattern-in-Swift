# Repository guide

MoneyFramework is a Swift implementation of the Money pattern for iOS. The framework target uses Swift 4 language mode and declares iOS 10 as its deployment target.

- `Classes/Swift/` contains the library sources, including `Money`, currency definitions, decimal helpers, and conversion strategies. The CocoaPods spec also packages sources from this directory.
- `Tests/Swift/` contains the XCTest suites for money and currencies.
- `MoneyFramework/MoneyFramework.xcodeproj` contains the framework and test targets. `TestFrameworkApp/` contains the separate UIKit sample app.

## Build and test

Use the shared `MoneyFramework` scheme. Set `SIMULATOR_NAME` to an available iOS simulator listed by `xcrun simctl list devices booted` or `xcrun simctl list devices available`.

```sh
xcodebuild -project MoneyFramework/MoneyFramework.xcodeproj \
  -scheme MoneyFramework \
  -destination "platform=iOS Simulator,name=${SIMULATOR_NAME}" \
  test
```

For a build without a simulator device, use the same project and scheme with `-destination 'generic/platform=iOS Simulator' build`.

## Library changes

Keep monetary calculations in `Decimal`. When changing arithmetic, allocation, or currency conversion, check how currency minor units and rounding affect the result. Exchange-rate inputs and conversion strategies belong in the existing conversion API. When adding Swift files, confirm that the applicable Xcode target includes them.

## Implementation plan

Follow the order and completion criteria in [the master specification](Documentation/Master-Specification.md). For behavior changes, start with a regression test that fails for the expected reason, make the minimal change, then run the affected suite before refactoring.
