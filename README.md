# Money Design Pattern in Swift

Simple implementation of The Money Pattern, defined by Martin Fowler.

## Installation

Money Framework is available through [CocoaPods](http://cocoapods.org).

To install add the following line to your Podfile:

``` Ruby
pod 'MoneyFramework'
```

## Build Settings

Base SDK:  Latest
Deployment Target:  10.0

> **NB! You can build an application with latest Base SDK that runs under iOS 10. But then you have to take care to not use any function or method that is not available on iOS 10. If you do, your application will crash on iOS 10 as soon as this function is used.**

## Offline SwiftUI demo

Open `TestFrameworkApp/TestFrameworkApp.xcodeproj` in Xcode, select the shared `TestFrameworkApp` scheme and an iOS simulator, then choose **Run**. The demo targets iOS 15 or later and resolves `MoneyFramework` from the local Swift package.

The converter uses fixed sample rates for USD, EUR, and BGN. Enter `10`, select USD and EUR, and tap **Convert** to see `8 EUR` in your locale's format. The demo requires no internet connection or API key.

To run the model and UI tests, choose **Product → Test** in Xcode or run this command from the repository root, using an installed simulator name:

```sh
xcodebuild -project TestFrameworkApp/TestFrameworkApp.xcodeproj \
  -scheme TestFrameworkApp \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

## To be done

+ Better README
+ Better Unit Tests

## License

**Copyright (c) 2015 Aleksandar Petrov**

Licensed under the MIT License.
