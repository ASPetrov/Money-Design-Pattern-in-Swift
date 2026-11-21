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
