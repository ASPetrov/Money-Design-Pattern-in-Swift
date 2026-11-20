import Foundation
import MoneyFramework
import XCTest

final class CustomCurrencyTests: XCTestCase {
    func testCryptoAmountsRoundTripExactlyAcrossLocales() throws {
        for (code, scale) in [("BTC", 8), ("ETH", 18)] {
            let currency = try XCTUnwrap(CustomCurrency(
                identifier: .asset(network: code, reference: "native"), code: code, name: code, minorUnits: scale
            ))
            for (localeID, separator) in [("en_US", "."), ("de_DE", ",")] {
                let locale = Locale(identifier: localeID)
                let quantity = "0" + separator + String(repeating: "0", count: scale - 1) + "1"
                let text = quantity + " " + code
                let money = try XCTUnwrap(Money(amount: text, currency: currency, locale: locale))

                XCTAssertEqual(try money.checkedMinorUnits(), 1)
                XCTAssertEqual(money.formatted(locale: locale), text)
                XCTAssertNil(Money(amount: quantity + " USD", currency: currency, locale: locale))
                XCTAssertNil(Money(amount: text + " extra", currency: currency, locale: locale))
            }
        }
    }

    func testIdentityAndScaleAreCheckedBeforeArithmetic() throws {
        let original = try token(network: "test:1", reference: "a")
        let alias = try token(network: "test:1", reference: "a", code: "ALIAS")
        let otherNetwork = try token(network: "test:2", reference: "a")
        let otherContract = try token(network: "test:1", reference: "b")
        let otherScale = try token(network: "test:1", reference: "a", scale: 18)
        let lhs = try XCTUnwrap(Money(amount: Decimal(2), currency: original))
        let rhs = try XCTUnwrap(Money(amount: Decimal(2), currency: alias))

        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual((lhs + rhs).amount, Decimal(4))
        XCTAssertEqual((lhs - rhs).amount, .zero)
        XCTAssertEqual(try lhs.compare(to: rhs), .orderedSame)
        let incompatibleCurrencies: [(CustomCurrency, Money<CustomCurrency>.ArithmeticError)] = [
            (otherNetwork, .incompatibleCurrencies),
            (otherContract, .incompatibleCurrencies),
            (otherScale, .incompatibleCurrencyScale),
        ]
        for (currency, expected) in incompatibleCurrencies {
            let incompatible = try XCTUnwrap(Money(amount: Decimal(2), currency: currency))
            XCTAssertNotEqual(lhs, incompatible)
            XCTAssertThrowsError(try lhs.adding(incompatible)) {
                XCTAssertEqual($0 as? Money<CustomCurrency>.ArithmeticError, expected)
            }
            XCTAssertThrowsError(try lhs.subtracting(incompatible)) {
                XCTAssertEqual($0 as? Money<CustomCurrency>.ArithmeticError, expected)
            }
            XCTAssertThrowsError(try lhs.compare(to: incompatible)) {
                XCTAssertEqual($0 as? Money<CustomCurrency>.ArithmeticError, expected)
            }
        }
        XCTAssertFalse((lhs as Any) is any DecimalRepresentable)
    }

    func testExplicitConversionAcrossCurrencyTypesAndValidation() throws {
        let usd = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "usd"))
        let credits = try XCTUnwrap(CustomCurrency(
            identifier: .custom(namespace: "example", code: "credits"),
            code: "CR", name: "Credits", minorUnits: 0
        ))
        let source = try XCTUnwrap(Money(amount: Decimal(1), currency: usd, roundingMode: .plain))
        let rate = try XCTUnwrap(Decimal(string: "2.5"))
        let converted = try source.convertTo(credits, usingExchangeRate: rate, roundingMode: .plain)

        XCTAssertEqual(converted.amount, Decimal(3))
        XCTAssertEqual(converted.currency, credits)
        XCTAssertEqual(converted.formatted(locale: Locale(identifier: "en_US")), "3 CR")
        XCTAssertEqual(try converted.convertTo(usd, usingExchangeRate: Decimal(2)).amount, Decimal(6))
        XCTAssertThrowsError(try source.convertTo(usd, usingExchangeRate: 1)) {
            XCTAssertEqual($0 as? ConvertCurrenciesStrategyError, .sameCurrency)
        }
        for rate in [Decimal.zero, Decimal(-1), .nan] {
            XCTAssertThrowsError(try source.convertTo(credits, usingExchangeRate: rate)) {
                XCTAssertEqual($0 as? ConvertCurrenciesStrategyError, .invalidExchangeRate)
            }
        }
        let largeAmount = try XCTUnwrap(Decimal(string: "1e120"))
        let largeRate = try XCTUnwrap(Decimal(string: "1e60"))
        let large = try XCTUnwrap(Money(amount: largeAmount, currency: usd))
        XCTAssertThrowsError(try large.convertTo(credits, usingExchangeRate: largeRate)) {
            XCTAssertEqual($0 as? ConvertCurrenciesStrategyError, .unrepresentableResult)
        }
    }

    func testConversionUsesTheSuppliedStrategy() throws {
        let sourceCurrency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "USD"))
        let targetCurrency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let source = try XCTUnwrap(Money(amount: Decimal(10), currency: sourceCurrency))
        let strategy = RecordingConversionStrategy()

        let result = try source.convertTo(targetCurrency, usingExchangeRate: 2, strategy: strategy)

        XCTAssertEqual(strategy.sourceAmount, 10)
        XCTAssertEqual(strategy.sourceCurrencyCode, "USD")
        XCTAssertEqual(strategy.targetCurrencyCode, "EUR")
        XCTAssertEqual(strategy.rate, 2)
        XCTAssertEqual(result.amount, 7)
        XCTAssertEqual(result.currency, targetCurrency)
    }

    func testConversionRejectsConflictingScalesForTheSameIdentity() throws {
        let currency = try token(network: "test:1", reference: "native")
        let conflictingCurrency = try token(network: "test:1", reference: "native", scale: 18)
        let money = try XCTUnwrap(Money(amount: Decimal(1), currency: currency))

        XCTAssertThrowsError(try money.convertTo(conflictingCurrency, usingExchangeRate: 1)) {
            XCTAssertEqual($0 as? ConvertCurrenciesStrategyError, .incompatibleCurrencyScale)
        }
    }

    func testLargeETHRemainsDisplayableOutsideMinorUnitRange() throws {
        let eth = try token(network: "test:1", reference: "native", code: "ETH", scale: 18)
        let money = try XCTUnwrap(Money(amount: Decimal(10), currency: eth))

        XCTAssertEqual(money.formatted(locale: Locale(identifier: "en_US")), "10 ETH")
        XCTAssertThrowsError(try money.checkedMinorUnits())
        XCTAssertThrowsError(try money.allocate(recipientCount: 2))
        XCTAssertNil(CustomCurrency(identifier: eth.identifier, code: "ETH", name: "Ether", minorUnits: 128))
    }

    func testISOParsingUsesTheRequestedLocaleAndRejectsTrailingText() throws {
        let usd = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "usd"))
        let locale = Locale(identifier: "de_DE")
        let money = try XCTUnwrap(Money(amount: "1,25", currency: usd, locale: locale))
        let formatted = try XCTUnwrap(money.formatted(locale: locale))

        XCTAssertTrue(formatted.contains("1,25"))
        XCTAssertEqual(Money(amount: formatted, currency: usd, locale: locale), money)
        XCTAssertNil(Money(amount: formatted + " extra", currency: usd, locale: locale))
        XCTAssertEqual(Money(amount: "$1", currency: usd)?.amount, Decimal(1))
        XCTAssertEqual(try Money(parsing: formatted, currency: usd, locale: locale), money)
        XCTAssertThrowsError(try Money(parsing: formatted + " extra", currency: usd, locale: locale)) {
            XCTAssertEqual($0 as? Amount.ValidationError, .invalidFormat)
        }
        XCTAssertThrowsError(try Money(parsing: "1.123456789012345678901234567890123456789", currency: usd)) {
            XCTAssertEqual($0 as? Amount.ValidationError, .unrepresentableValue)
        }
    }

    func testMoneyRejectsInvalidExternalCurrencyScale() {
        let externalCurrency = LocaleCurrency(
            code: "USD", name: "US Dollar", minorUnits: -1, symbol: nil, separator: nil, delimiter: nil
        )

        XCTAssertNil(Money(currency: externalCurrency))
        XCTAssertThrowsError(try Money(validating: .zero, currency: externalCurrency)) {
            XCTAssertEqual($0 as? Amount.ValidationError, .invalidScale)
        }
    }

    private func token(
        network: String,
        reference: String,
        code: String = "TOK",
        scale: Int = 8
    ) throws -> CustomCurrency {
        try XCTUnwrap(CustomCurrency(
            identifier: .asset(network: network, reference: reference), code: code, name: code, minorUnits: scale
        ))
    }
}

private final class RecordingConversionStrategy: ConvertCurrenciesStrategy {
    private(set) var sourceAmount: Decimal?
    private(set) var sourceCurrencyCode: String?
    private(set) var targetCurrencyCode: String?
    private(set) var rate: Decimal?

    func convertTo<T: Currency>(
        _ money: Money<T>,
        toCurrency currency: T,
        usingExchangeRate multiplier: Decimal
    ) throws -> Money<T> {
        sourceAmount = money.amount
        sourceCurrencyCode = money.currency.code
        targetCurrencyCode = currency.code
        rate = multiplier
        return try XCTUnwrap(Money(amount: Decimal(7), currency: currency))
    }
}
