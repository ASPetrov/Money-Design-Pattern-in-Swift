# Migrating MoneyFramework from CocoaPods

1. Remove the `MoneyFramework` entry from your `Podfile`. Keep any other pods your project uses and run `pod install` to update the workspace.
2. Follow the [Swift package installation instructions](../../README.md#installation). Link the `MoneyFramework` product to each target that imports it.
3. Build and test your targets. Check the new deployment minimums and use the [Money walkthrough](Money-Pattern.md) to update currency conversions that relied on the old API.

The [CocoaPods registry](https://trunk.cocoapods.org/api/v1/pods/MoneyFramework) lists versions `1.0.0` and `1.0.3`. The Git repository also has a historical [`v1.1.0` tag](https://github.com/ASPetrov/Money-Design-Pattern-in-Swift/tree/v1.1.0). Its podspec asks CocoaPods to fetch `1.1.0`, a tag absent from the repository. Use the registry versions when keeping an existing CocoaPods integration.
