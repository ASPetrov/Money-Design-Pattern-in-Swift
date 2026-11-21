import Foundation
import MoneyFramework
import Testing

struct CustomCurrencyTests {

    @Test func testCryptoRoundTripsExactlyAcrossLocales() throws {
        for (code, scale) in [("BTC", 8), ("ETH", 18)] {
            let currency = try #require(
                CustomCurrency(
                    identifier: .asset(
                        network: code,
                        reference: "native"
                    ),
                    code: code,
                    name: code,
                    minorUnits: scale
                )
            )
            for (localeID, separator) in [("en_US", "."), ("de_DE", ",")] {
                let locale = Locale(identifier: localeID)
                let quantity =
                    "0" + separator + String(repeating: "0", count: scale - 1) + "1"
                let text = quantity + " " + code
                let money = try #require(
                    Money(amount: text, currency: currency, locale: locale)
                )

                #expect(try money.checkedMinorUnits() == 1)
                #expect(money.formatted(locale: locale) == text)
                #expect(Money(amount: quantity + " USD", currency: currency, locale: locale) == nil)
                #expect(Money(amount: text + " extra", currency: currency, locale: locale) == nil)
            }
        }
    }

    @Test func testArithmeticChecksIdentityAndScale() throws {
        let original = try token(network: "test:1", reference: "a")
        let alias = try token(network: "test:1", reference: "a", code: "ALIAS")
        let lhs = try #require(Money(amount: Decimal(2), currency: original))
        let rhs = try #require(Money(amount: Decimal(2), currency: alias))

        #expect(lhs == rhs)
        #expect((lhs + rhs).amount == Decimal(4))
        #expect((lhs - rhs).amount == .zero)
        #expect(try lhs.compare(to: rhs) == .orderedSame)
        #expect(!((lhs as Any) is any DecimalRepresentable))
    }

    @Test func testRejectsCurrencyConflicts() throws {
        let original = try token(network: "test:1", reference: "a")
        let lhs = try #require(Money(amount: Decimal(2), currency: original))
        let otherNetwork = try token(network: "test:2", reference: "a")
        let otherContract = try token(network: "test:1", reference: "b")
        let otherScale = try token(network: "test:1", reference: "a", scale: 18)
        let conflicts: [(CustomCurrency, Money<CustomCurrency>.ArithmeticError)] = [
            (otherNetwork, .incompatibleCurrencies),
            (otherContract, .incompatibleCurrencies),
            (otherScale, .incompatibleCurrencyScale),
        ]
        for (currency, expected) in conflicts {
            let incompatible = try #require(Money(amount: Decimal(2), currency: currency))
            expectCurrencyConflict(lhs, incompatible, error: expected)
        }
    }

    private func expectCurrencyConflict(
        _ lhs: Money<CustomCurrency>,
        _ incompatible: Money<CustomCurrency>,
        error expected: Money<CustomCurrency>.ArithmeticError
    ) {
        #expect(lhs != incompatible)
        #expect(throws: expected) {
            _ = try lhs.adding(incompatible)
        }
        #expect(throws: expected) {
            _ = try lhs.subtracting(incompatible)
        }
        #expect(throws: expected) {
            _ = try lhs.compare(to: incompatible)
        }
    }

    @Test func testValidatesCrossTypeConversion() throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "usd"))
        let credits = try #require(CustomCurrency(
            identifier: .custom(namespace: "example", code: "credits"),
            code: "CR", name: "Credits", minorUnits: 0
        ))
        let source = try #require(Money(amount: Decimal(1), currency: usd, roundingMode: .plain))
        let rate = try #require(Decimal(string: "2.5"))
        let converted = try source.convertTo(credits, usingExchangeRate: rate, roundingMode: .plain)

        #expect(converted.amount == Decimal(3))
        #expect(converted.currency == credits)
        #expect(converted.formatted(locale: Locale(identifier: "en_US")) == "3 CR")
        #expect(try converted.convertTo(usd, usingExchangeRate: Decimal(2)).amount == Decimal(6))
    }

    @Test func testRejectsInvalidConversionRates() throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "usd"))
        let credits = try #require(CustomCurrency(
            identifier: .custom(namespace: "example", code: "credits"),
            code: "CR", name: "Credits", minorUnits: 0
        ))
        let source = try #require(Money(amount: Decimal(1), currency: usd, roundingMode: .plain))
        #expect(throws: ConvertCurrenciesStrategyError.sameCurrency) {
            _ = try source.convertTo(usd, usingExchangeRate: 1)
        }
        for rate in [Decimal.zero, Decimal(-1), .nan] {
            #expect(throws: ConvertCurrenciesStrategyError.invalidExchangeRate) {
                _ = try source.convertTo(credits, usingExchangeRate: rate)
            }
        }
    }

    @Test func testRejectsConversionOverflow() throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "usd"))
        let credits = try #require(CustomCurrency(
            identifier: .custom(namespace: "example", code: "credits"),
            code: "CR", name: "Credits", minorUnits: 0
        ))
        let largeAmount = try #require(Decimal(string: "1e120"))
        let largeRate = try #require(Decimal(string: "1e60"))
        let large = try #require(Money(amount: largeAmount, currency: usd))
        #expect(throws: ConvertCurrenciesStrategyError.unrepresentableResult) {
            _ = try large.convertTo(credits, usingExchangeRate: largeRate)
        }
    }

    @Test func testConversionUsesTheSuppliedStrategy() throws {
        let sourceCurrency = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let targetCurrency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let source = try #require(Money(amount: Decimal(10), currency: sourceCurrency))
        let strategy = RecordingConversionStrategy()

        let result = try source.convertTo(targetCurrency, usingExchangeRate: 2, strategy: strategy)

        #expect(strategy.sourceAmount == 10)
        #expect(strategy.sourceCurrencyCode == "USD")
        #expect(strategy.targetCurrencyCode == "EUR")
        #expect(strategy.rate == 2)
        #expect(result.amount == 7)
        #expect(result.currency == targetCurrency)
    }

    @Test func testConversionRejectsConflictingScales() throws {
        let currency = try token(network: "test:1", reference: "native")
        let conflictingCurrency = try token(network: "test:1", reference: "native", scale: 18)
        let money = try #require(Money(amount: Decimal(1), currency: currency))

        #expect(throws: ConvertCurrenciesStrategyError.incompatibleCurrencyScale) {
            _ = try money.convertTo(conflictingCurrency, usingExchangeRate: 1)
        }
    }

    @Test func testFormatsETHBeyondMinorUnitRange() throws {
        let eth = try token(network: "test:1", reference: "native", code: "ETH", scale: 18)
        let money = try #require(Money(amount: Decimal(10), currency: eth))

        #expect(money.formatted(locale: Locale(identifier: "en_US")) == "10 ETH")
        #expect(throws: (any Error).self) {
            _ = try money.checkedMinorUnits()
        }
        #expect(throws: (any Error).self) {
            _ = try money.allocate(recipientCount: 2)
        }
        #expect(CustomCurrency(identifier: eth.identifier, code: "ETH", name: "Ether", minorUnits: 128) == nil)
    }

    @Test func testIsoParsingUsesLocaleAndConsumesInput() throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "usd"))
        let locale = Locale(identifier: "de_DE")
        let money = try #require(Money(amount: "1,25", currency: usd, locale: locale))
        let formatted = try #require(money.formatted(locale: locale))

        #expect(formatted.contains("1,25"))
        #expect(Money(amount: formatted, currency: usd, locale: locale) == money)
        #expect(Money(amount: formatted + " extra", currency: usd, locale: locale) == nil)
        #expect(Money(amount: "$1", currency: usd)?.amount == Decimal(1))
        #expect(try Money(parsing: formatted, currency: usd, locale: locale) == money)
        #expect(throws: Amount.ValidationError.invalidFormat) {
            _ = try Money(parsing: formatted + " extra", currency: usd, locale: locale)
        }
        #expect(throws: Amount.ValidationError.unrepresentableValue) {
            _ = try Money(parsing: "1.123456789012345678901234567890123456789", currency: usd)
        }
    }

    @Test(arguments: ["en_US", "fa_IR", "hi_IN", "ja_JP", "fr_FR"], [-12, 12])
    func testTunisianDinarRoundTrips(
        localeID: String,
        units: Int
    ) throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "TND"))
        let locale = Locale(identifier: localeID)
        let money = try Money(validating: Amount(integer: units), currency: currency)
        let formatted = try #require(money.formatted(locale: locale))

        #expect(try Money(parsing: formatted, currency: currency, locale: locale) == money)
    }

    @Test(arguments: [
        "TND\u{00A0}\u{00A0}12.000",
        "TND\u{00A0}12,34.000",
        "-TND\u{00A0}-12.000",
        "TND\u{00A0}12.000 extra",
    ])
    func testRejectsMalformedCurrencySpacing(_ input: String) throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "TND"))
        #expect(throws: Amount.ValidationError.invalidFormat) {
            _ = try Money(parsing: input, currency: currency, locale: Locale(identifier: "en_US"))
        }
    }

    @Test func testRejectsInvalidExternalCurrencyScale() {
        let externalCurrency = LocaleCurrency(
            code: "USD", name: "US Dollar", minorUnits: -1, symbol: nil, separator: nil, delimiter: nil
        )

        #expect(Money(currency: externalCurrency) == nil)
        #expect(throws: Amount.ValidationError.invalidScale) {
            _ = try Money(validating: .zero, currency: externalCurrency)
        }
    }

    private func token(
        network: String,
        reference: String,
        code: String = "TOK",
        scale: Int = 8
    ) throws -> CustomCurrency {
        try #require(CustomCurrency(
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
        return try #require(Money(amount: Decimal(7), currency: currency))
    }
}
