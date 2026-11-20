# MoneyFramework

A Swift implementation of the Money pattern for representing monetary amounts with a currency, converting between currencies, and allocating amounts.

The project includes the `MoneyFramework` library, an offline SwiftUI demo, and a walkthrough available in English and Bulgarian.

## Project contents

| Component | Purpose |
| --- | --- |
| `MoneyFramework` | The reusable Swift library. Add this product to your application to use the Money implementation. |
| SwiftUI demo | An offline example application demonstrating how to use the library. |
| Walkthrough | An explanation of the Money pattern and the accompanying demo. See the documentation links below. |

## Requirements

- Swift 6.0 or later
- iOS 15 or later, or macOS 12 or later

## Installation

### Xcode

1. Select **File → Add Package Dependencies**.
2. Enter the repository URL:

   ```text
   https://github.com/ASPetrov/Money-Design-Pattern-in-Swift.git
   ```

3. Select **Branch** and enter `master`.
4. Add the **MoneyFramework** library product to your application target.

### Swift Package Manager

Add the repository to the `dependencies` array in your `Package.swift`:

```swift
.package(
    url: "https://github.com/ASPetrov/Money-Design-Pattern-in-Swift.git",
    branch: "master"
)
```

Then add the library product to the `dependencies` array of the target that will use it:

```swift
.product(
    name: "MoneyFramework",
    package: "Money-Design-Pattern-in-Swift"
)
```

Import the module in your Swift source files:

```swift
import MoneyFramework
```

**Package availability:** The selected branch or release tag must contain `Package.swift`. The `master` instructions apply once the Swift Package Manager changes have been pushed to that branch.

## Documentation

The walkthrough explains the Money pattern and its implementation, including the offline SwiftUI demo.

| Language | Document |
| --- | --- |
| English | [Money Pattern walkthrough](Documentation/EN/Money-Pattern.md) |
| Български | [Ръководство за шаблона Money](Documentation/BG/Money-Pattern.md) |

## License

This project is distributed under the [MIT License](LICENSE.md).
