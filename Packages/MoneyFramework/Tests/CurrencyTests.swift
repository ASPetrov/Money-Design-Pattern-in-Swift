//
//  Currency.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import Testing

// NOTE: Factory methods are build over constructors - no need to be tested

struct CurrencyTests {

    @Test(arguments: ["sv_SE", "ar_EG", "fa_IR"])
    func testAcceptsAsciiSignsWithIsoAffixes(_ localeID: String) throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let locale = Locale(identifier: localeID)
        let positive = try #require(usd.string(from: 21, locale: locale))
        let negative = try #require(usd.string(from: -21, locale: locale))

        #expect(usd.number(from: negative, locale: locale)?.decimalValue == -21)
        #expect(usd.number(from: "-" + positive, locale: locale)?.decimalValue == -21)
        #expect(usd.number(from: "+" + positive, locale: locale)?.decimalValue == 21)
        #expect(usd.number(from: "+" + negative, locale: locale) == nil)
        #expect(usd.number(from: "--" + positive, locale: locale) == nil)
    }

    @Test(arguments: [("en_US", "1.234", "1,234"), ("de_DE", "1,234", "1.234")])
    func testLocaleDisambiguatesSeparators(example: (localeID: String, fraction: String, grouped: String)) throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let locale = Locale(identifier: example.localeID)

        #expect(usd.number(from: example.fraction, locale: locale)?.decimalValue == Decimal(1234) / 1000)
        #expect(usd.number(from: example.grouped, locale: locale)?.decimalValue == 1234)
    }

    @Test(arguments: ["USD", "usd", "uSd"])
    func testCanonicalizesIsoCode(_ code: String) throws {
        let canonical = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let initialized = LocaleCurrency(
            code: code,
            name: canonical.name,
            minorUnits: canonical.minorUnits,
            symbol: canonical.symbol,
            separator: canonical.separator,
            delimiter: canonical.delimiter
        )
        var updated = canonical
        updated.code = code

        try expectCanonicalUSD(initialized, matching: canonical)
        try expectCanonicalUSD(updated, matching: canonical)
    }

    private func expectCanonicalUSD(_ currency: LocaleCurrency, matching canonical: LocaleCurrency) throws {
        #expect(currency.code == "USD")
        #expect(currency.identifier == canonical.identifier)
        for locale: Locale? in [nil, Locale(identifier: "en_US")] {
            let text = try #require(canonical.string(from: 12, locale: locale))
            #expect(currency.string(from: 12, locale: locale) == text)
            #expect(currency.number(from: text, locale: locale)?.decimalValue == Decimal(12))
        }
    }

    //
    // MARK: - Test Initialization
    //

    @Test func testInitializerPreservesAllFields() {
        // Given
        let currencyCode = "EUR"
        let currencyName = "Euro"
        let currencyMinorUnits = 2
        let currencySymbol = "€"
        let decimalSeparator = "."
        let groupingDelimiter = " "
        // When
        let currency = LocaleCurrency(
            code: currencyCode,
            name: currencyName,
            minorUnits: currencyMinorUnits,
            symbol: currencySymbol,
            separator: decimalSeparator,
            delimiter: groupingDelimiter
        )
        // Then
        #expect(currency.code == currencyCode, "Currency code should match")
        #expect(currency.name == currencyName, "Currency name should match")
        #expect(currency.minorUnits == currencyMinorUnits, "Currency minor units should match")
        #expect(currency.symbol == currencySymbol, "Currency symbol should match")
        #expect(currency.separator == decimalSeparator, "Currency separator should match")
        #expect(currency.delimiter == groupingDelimiter, "Currency delimiter should match")
    }

    @Test func testCanCreateCurrencyFromCurrencyCode() {
        // Given
        let currencyCode = "EUR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)
        // Then
        #expect(currency != nil, "Could not create currency from currency code")
    }

    @Test func testRejectsInvalidCurrencyCode() {
        // Given
        let currencyCode = "BGR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)
        // Then
        #expect(currency == nil, "Should not create currency from invalid currency code")
    }

    @Test func testCreatesCurrencyForLocaleWithCurrency() {
        // Given
        let locale = Locale(identifier: "fr_FR")
        // When
        let currency = LocaleCurrency(locale: locale)
        // Then
        #expect(currency != nil, "Could not create currency from locale")
    }

    @Test func testRejectsLocaleWithoutCurrency() {
        // Given
        let locale = Locale(identifier: "en")
        // When
        let currency = LocaleCurrency(locale: locale)
        // Then
        #expect(currency == nil, "Should not create currency from locale")
    }

    @Test func testDefaultCurrencyUsesCurrentLocale() {
        #expect(LocaleCurrency() == LocaleCurrency(locale: .current))
    }

    @Test(arguments: [
        ("en_US", "USD", 2, ".", ","),
        ("de_DE", "EUR", 2, ",", "."),
    ])
    func testCurrencyMetadataMatchesLocale(
        _ localeID: String,
        _ code: String,
        _ scale: Int,
        _ separator: String,
        _ delimiter: String
    ) throws {
        let locale = Locale(identifier: localeID)
        let currency = try #require(LocaleCurrency(localeIdentifier: localeID))

        #expect(currency.code == code)
        #expect(currency.name == (locale.localizedString(forCurrencyCode: code) ?? code))
        #expect(currency.minorUnits == scale)
        #expect(currency.separator == separator)
        #expect(currency.delimiter == delimiter)
        if code == "USD" {
            #expect(currency.symbol == "$")
        }
    }

    @Test func testEuroMetadataMatchesISOCode() throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))

        #expect(currency.code == "EUR")
        #expect(currency.name == (Locale.current.localizedString(forCurrencyCode: "EUR") ?? "EUR"))
        #expect(currency.symbol == "€")
        #expect(currency.minorUnits == 2)
    }

    @Test func testTunisianDinarHasThreeMinorUnitDigits() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "fr_TN"))

        #expect(currency.code == "TND")
        #expect(currency.minorUnits == 3)
    }

    //
    // MARK: - Equal
    //

    @Test func testTwoCurrencyObjectsAreEqual() throws {
        // Given
        let currencyLHS = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let currencyRHS = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        // When
        let result = currencyLHS == currencyRHS
        // Then
        #expect(result == true, "Currencies should match")
    }

    @Test func testTwoCurrencyObjectsAreNotEqual() throws {
        // Given
        let currencyLHS = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let currencyRHS = try #require(LocaleCurrency(localeIdentifier: "fr_TN"))
        // When
        let result = currencyLHS == currencyRHS
        // Then
        #expect(result == false, "Currencies should not match")
    }

    @Test(arguments: [" $21.09 ", "\t$21.09\n", "\u{00A0}$21.09\u{202F}"])
    func testAcceptsOuterCurrencyWhitespace(_ input: String) throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let expected = Decimal(2109) / 100

        for locale: Locale? in [nil, Locale(identifier: "en_US")] {
            #expect(usd.number(from: input, locale: locale)?.decimalValue == expected)
            #expect(try Money(parsing: input, currency: usd, locale: locale).amount == expected)
        }
    }

    @Test(arguments: [" $ 21.09 ", " $21 .09 ", " $21.09 extra ", " \t "])
    func testRejectsMalformedPaddedCurrency(_ input: String) throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let locale = Locale(identifier: "en_US")

        #expect(usd.number(from: input, locale: locale) == nil)
        #expect(throws: Amount.ValidationError.invalidFormat) {
            _ = try Money(parsing: input, currency: usd, locale: locale)
        }
    }

    @Test func testCurrencyNumberParsesExactAmount() throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let locale = Locale(identifier: "de_DE")
        let parsed = try #require(currency.number(from: "1.234,56", locale: locale))

        #expect(parsed.decimalValue == Decimal(123_456) / 100)
        #expect(currency.number(from: "1.234,56 extra", locale: locale) == nil)
    }

    @Test(arguments: ["12.34,56", "1..234,56", "1.234,5.6"])
    func testRejectsInvalidGrouping(_ input: String) throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let locale = Locale(identifier: "de_DE")

        #expect(currency.number(from: input, locale: locale) == nil)
        #expect(throws: Amount.ValidationError.invalidFormat) {
            _ = try Money(parsing: input, currency: currency, locale: locale)
        }
    }

    @Test func testDefaultFormattingUsesCurrencySymbol() throws {
        var currency = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        currency.symbol = "TEST"
        let amount = NSDecimalNumber(value: 12)
        let source = try #require(currency.string(from: amount))
        let explicit = try #require(currency.string(from: amount, locale: Locale(identifier: "en_US")))

        #expect(source.contains("TEST"))
        #expect(!explicit.contains("TEST"))
        #expect(currency.number(from: source)?.decimalValue == Decimal(12))
    }

    @Test func testUnknownIsoCodeUsesCustomFormat() throws {
        let currency = LocaleCurrency(
            code: "ZZZ", name: "Example", minorUnits: 2, symbol: "ZZZ", separator: nil, delimiter: nil
        )
        let amount = NSDecimalNumber(value: 12)
        for locale: Locale? in [nil, Locale(identifier: "de_DE")] {
            let text = try #require(currency.string(from: amount, locale: locale))
            #expect(text == "12 ZZZ")
            #expect(currency.number(from: text, locale: locale)?.decimalValue == Decimal(12))
            #expect(currency.number(from: " \(text) ", locale: locale)?.decimalValue == Decimal(12))
        }
    }

    @Test func testConfiguresFormattersIndependently() throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let locale = Locale(identifier: "en_US")
        let first = currency.currencyFormatter(with: locale)
        first.currencySymbol = "Changed"

        let second = currency.currencyFormatter(with: locale)

        #expect(!(first === second))
        #expect(second.numberStyle == .currency)
        #expect(second.currencySymbol == currency.symbol)
    }
}
