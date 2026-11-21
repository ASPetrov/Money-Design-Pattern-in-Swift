# Money Pattern in Swift

A monetary amount needs more than a number: it needs a currency and explicit rules for arithmetic, rounding, and allocation. The Money pattern brings these responsibilities together in a dedicated type.

This guide demonstrates the pattern with MoneyFramework. We will combine a receipt for 12.03 EUR with another for 10 USD, convert them to a common currency, and split the total without losing a cent.

## Why use a Money type?

A bare number cannot tell you whether `10` means euros, dollars, or cents. Keeping the currency separately also makes it easy to add incompatible amounts accidentally.

A Money type associates the amount with its currency and gives arithmetic a clear meaning:

- Addition and comparison require compatible currencies.
- Conversion requires an explicit exchange rate.
- Rounding follows the precision of the destination currency and a chosen rounding rule.
- Allocation distributes whole minor units while preserving the original total.

These are the concerns behind [Martin Fowler’s Money pattern](https://martinfowler.com/eaaCatalog/money.html). The [Envato Tuts+ tutorial](https://code.tutsplus.com/money-pattern-the-right-way-to-represent-value-unit-pairs--net-35509t) provides additional inspiration through a PHP implementation developed with tests. This guide uses a separate Swift API and a smaller receipt-splitting example; it does not reproduce that tutorial’s account model.

## Decimal amounts and minor units

Binary floating-point types such as `Float` and `Double` cannot represent many decimal fractions exactly. For example, `0.1` has no exact finite binary representation. For monetary input, parsing decimal text avoids first introducing an approximation through a binary floating-point value.

When used as a scalar, a `Float` is widened to `Double` before its stored binary value is converted to `Decimal`. Checked arithmetic rejects NaN and infinities.

MoneyFramework’s `Amount(decimalString:)` accepts a decimal quantity. In this guide, `"12.03"` means **12.03 units of the currency**, not 12.03 cents. Keep values within the supported precision and range; decimal arithmetic still has limits and rounding rules.

A *minor unit* is the smallest unit used at the currency’s configured scale. For EUR, one minor unit is one cent, so 12.03 EUR corresponds to 1,203 minor units. Do not assume that every currency has two decimal places.

The Tuts+ example passes integer minor units to its `Money` constructor: `100` represents 1 EUR. The Swift examples below start with decimal amounts and use `checkedMinorUnits()` when integer minor units are needed.

## Create amounts with explicit currencies

`Amount` represents the decimal quantity. `LocaleCurrency` supplies the currency definition and scale. `Money` combines them and applies currency rounding.

The following Swift blocks form one program. After installing the package, paste them in order into the same Swift file.

```swift
import Foundation
import MoneyFramework

enum ExampleError: Error {
    case invalidInput
}

let euros = try Amount(decimalString: "12.03")
let dollars = try Amount(decimalString: "10")

guard
    let eur = LocaleCurrency(isoCurrencyCode: "EUR"),
    let usd = LocaleCurrency(isoCurrencyCode: "USD"),
    let euroReceipt = Money(value: euros, currency: eur),
    let dollarReceipt = Money(value: dollars, currency: usd)
else {
    throw ExampleError.invalidInput
}
```

## Reject incompatible arithmetic

When the currency comes from user input, handle the `Result` returned by `addingChecked`. Adding the EUR receipt to itself succeeds. Adding the USD receipt requires conversion first.

```swift
for receipt in [euroReceipt, dollarReceipt] {
    switch euroReceipt.addingChecked(receipt) {
    case let .success(total):
        let cents = try total.checkedMinorUnits()
        precondition(cents == 2406)
    case .failure(.incompatibleCurrencies):
        print("Convert to EUR before adding.")
    case let .failure(error):
        throw error
    }
}
```

This keeps currency validation inside the monetary abstraction rather than relying on every caller to remember it.

## Convert before adding or comparing

For this example, use a fixed illustrative rate of **0.8 EUR per 1 USD**. The direction matters: multiply the USD amount by this rate to obtain EUR. It is not a live market quote.

```swift
let rate = try Amount(decimalString: "0.8").decimalValue
let convertedReceipt = try dollarReceipt.convertTo(eur, usingExchangeRate: rate)

let comparison = try euroReceipt.compare(to: convertedReceipt)
precondition(comparison == .orderedDescending)

let total = try euroReceipt.adding(convertedReceipt)
let totalCents = try total.checkedMinorUnits()
precondition(totalCents == 2003)
```

The converted receipt is 8 EUR. Both amounts now share a currency, so their total is 20.03 EUR.

## Make rounding a deliberate choice

The preceding conversion is exact at EUR precision, so it does not demonstrate rounding. Consider a separate illustrative conversion of 10 USD at **1.0065 EUR per USD**. Before currency rounding, the result is 10.065 EUR.

| Rounding rule | Result at two decimal places | Reason |
| --- | --- | --- |
| Half to even (`.bankers`) | 10.06 EUR | At an exact halfway point, choose the result whose last retained digit is even. |
| Half away from zero | 10.07 EUR | At an exact halfway point, round away from zero. |

MoneyFramework’s default conversion rounding mode is `.bankers`. This additional example demonstrates the halfway case independently of the receipt total:

```swift
let halfwayRate = try Amount(decimalString: "1.0065").decimalValue
let roundedReceipt = try dollarReceipt.convertTo(
    eur,
    usingExchangeRate: halfwayRate
)
let roundedCents = try roundedReceipt.checkedMinorUnits()
precondition(roundedCents == 1006)
```

Pass `roundingMode:` to the conversion when your application requires a different rule. The choice is a domain policy: the Money pattern does not prescribe one universal rounding mode. Also decide where rounding occurs in a calculation; rounding individual values can produce a different total from rounding their sum.

## Allocate without losing the remainder

Splitting 20.03 EUR equally gives a mathematical share of 10.015 EUR. Rounding both shares independently could change the total. Allocation instead distributes whole minor units and assigns the remainder deterministically.

```swift
let shares = try total.allocate(recipientCount: 2)
let cents = try shares.map { try $0.checkedMinorUnits() }
precondition(cents == [1002, 1001])
precondition(cents.reduce(0, +) == 2003)
```

The recipients receive 10.02 EUR and 10.01 EUR. The extra cent goes to the first share, and the shares sum to the original 20.03 EUR.

This example demonstrates equal allocation and returns the resulting Money values. The Tuts+ tutorial demonstrates percentage allocation into account objects. Both address the indivisible remainder, but their APIs and responsibilities differ. The equal-allocation example above does not establish support for arbitrary allocation ratios.

## Run the offline SwiftUI demo

The demo illustrates currency conversion with fixed example rates. For the USD-to-EUR example, enter 10, choose USD and EUR, and tap **Convert**. The screen shows 8 EUR in your locale’s format. The demo also supports BGN and runs without internet or an API key.

Open [the Xcode project](../../TestFrameworkApp/TestFrameworkApp.xcodeproj), select the shared `TestFrameworkApp` scheme and an installed iOS simulator, then choose **Run**. The app targets iOS 15 or later and uses the local package at `Packages/MoneyFramework`.

## Run the tests

Run `swift test` from the repository root to test the library. Choose **Product → Test** with the shared `TestFrameworkApp` scheme to run the demo’s unit and UI tests. You can also run the following command from the repository root with an installed simulator.

```sh
xcodebuild -project TestFrameworkApp/TestFrameworkApp.xcodeproj \
  -scheme TestFrameworkApp \
  -destination 'platform=iOS Simulator,name=<installed simulator>,OS=latest' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

The assertions in this guide describe the expected results of the examples. They supplement the project’s tests; they are not a complete verification of arithmetic, range limits, or error handling.

## References

- [Martin Fowler — Money](https://martinfowler.com/eaaCatalog/money.html): the pattern’s motivation, including currency safety and rounding.
- [Patkos Csaba — Money Pattern: The Right Way to Represent Value-Unit Pairs](https://code.tutsplus.com/money-pattern-the-right-way-to-represent-value-unit-pairs--net-35509t): a test-driven PHP example covering money, currencies, accounts, and allocation.
