//
//  Currency.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import UIKit
import XCTest
@testable import MoneyFramework

// NOTE: Factory methods are build over constructors - no need to be tested
// TODO: Test formatter methods

class CurrencyTests: XCTestCase {

    //
    // MARK: - Test Initialization
    //

    func testDefaultConstructorShouldStoreAllPassedValues() {
        // Given
        let currencyCode = "EUR"
        let currencyName = "Euro"
        let currencyMinorUnits = 2
        let currencySymbol = "€"
        let currencyDecimalSeparator = "."
        let currencyGroupingDelimiter = " "
        // When
        let currency = LocaleCurrency(code: currencyCode,
                                      name: currencyName,
                                      minorUnits: currencyMinorUnits,
                                      symbol: currencySymbol,
                                      separator: currencyDecimalSeparator,
                                      delimiter: currencyGroupingDelimiter)
        // Then
        XCTAssertEqual(currency.code, currencyCode, "Currency code should match")
        XCTAssertEqual(currency.name, currencyName, "Currency name should match")
        XCTAssertEqual(currency.minorUnits, currencyMinorUnits, "Currency minor units should match")
        XCTAssertEqual(currency.symbol, currencySymbol, "Currency symbol should match")
        XCTAssertEqual(currency.separator, currencyDecimalSeparator, "Currency separator should match")
        XCTAssertEqual(currency.delimiter, currencyGroupingDelimiter, "Currency delimiter should match")
    }

    func testCanCreateCurrencyFromCurrencyCode() {
        // Given
        let currencyCode = "EUR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)
        // Then
        XCTAssertNotNil(currency, "Could not create currency from currency code")
    }

    func testCanNotCreateCurrencyFromInvalidCurrencyCode() {
        // Given
        let currencyCode = "BGR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)
        // Then
        XCTAssertNil(currency, "Should not create currency from invalid currency code")
    }
    
    func testCanCreateCurrencyFromLocaleWithAssociatedCurrency() {
        // Given
        let locale = Locale(identifier: "fr_FR")
        // When
        let currency = LocaleCurrency(locale: locale)
        // Then
        XCTAssertNotNil(currency, "Could not create currency from locale")
    }
    
    func testCanNotCreateCurrencFromLocaleWithoutAssociatedCurrency() {
        // Given
        let locale = Locale(identifier: "en")
        // When
        let currency = LocaleCurrency(locale: locale)
        // Then
        XCTAssertNil(currency, "Should not create currency from locale")
    }

    // NOTE: This could be a bad idea if current locale doesn't have associated currency
    func testCanCreateCurrencyFromCurrentLocale() {
        // Given
        // Implicit current locale
        // When
        let currency = LocaleCurrency()
        // Then
        XCTAssertNotNil(currency, "Could not create currency from current locale")
    }
    
    //
    // MARK: - Properties
    //
    
    func testCurrencyCodeMatch() {
        // Given
        let currencyCode = "EUR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)!
        // Then
        XCTAssertEqual(currency.code, currencyCode, "Currency code should match")
    }
    
    func testCurrencyCodeNotMatch() {
        // Given
        let localeIdentifier = "en_US"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertNotEqual(currency.code, "EUR", "Currency code should not match")
    }

    func testCurrencyNameMatch() {
        // Given
        let currencyCode = "EUR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)!
        // Then
        XCTAssertEqual(currency.name.lowercased(), "Euro".lowercased(), "Currency code should match")
    }

    func testCurrencyNameNotMatch() {
        // Given
        let localeIdentifier = "en_US"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertNotEqual(currency.name.lowercased(), "Euro".lowercased(), "Currency code should not match")
    }
    
    func testCurrencySymbolMatch() {
        // Given
        let localeIdentifier = "en_US"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertEqual(currency.symbol, "$", "Currency symbol should match")
    }
    
    func testCurrencySymbolNotMatch() {
        // Given
        let currencyCode = "EUR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)!
        // Then
        XCTAssertNotEqual(currency.symbol, "$", "Currency symbol should not match")
    }
    
    func testCurrencyMaximumFractionDigitsMatch() {
        // Given
        let localeIdentifier = "fr_TN"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertEqual(currency.minorUnits, 3, "Currency maximum fraction digits should match")
    }
    
    func testCurrencyMaximumFractionDigitsNotMatch() {
        // Given
        let currencyCode = "EUR"
        // When
        let currency = LocaleCurrency(isoCurrencyCode: currencyCode)!
        // Then
        XCTAssertNotEqual(currency.minorUnits, 3, "Currency maximum fraction digits should not match")
    }
    
    func testCurrencDecimalSeparatorMatch() {
        // Given
        let localeIdentifier = "de_DE"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertEqual(currency.separator, ",", "Currency decimal separator should match")
    }
    
    func testCurrencyDecimalSeparatorNotMatch() {
        // Given
        let localeIdentifier = "en_US"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertNotEqual(currency.separator, ",", "Currency decimal separator should not match")
    }
    
    func testCurrencGroupingSeparatorMatch() {
        // Given
        let localeIdentifier = "en_US"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertEqual(currency.delimiter, ",", "Currency grouping separator should match")
    }
    
    func testCurrencyGroupingSeparatorNotMatch() {
        // Given
        let localeIdentifier = "de_DE"
        // When
        let currency = LocaleCurrency(localeIdentifier: localeIdentifier)!
        // Then
        XCTAssertNotEqual(currency.delimiter, ",", "Currency grouping separator should not match")
    }

    //
    // MARK: - Equal
    //
    
    func testTwoCurrencyObjectsAreEqual() {
        // Given
        let currencyLHS = LocaleCurrency(localeIdentifier: "en_US")!
        let currencyRHS = LocaleCurrency(isoCurrencyCode: "USD")!
        // When
        let result = currencyLHS == currencyRHS
        // Then
        XCTAssertEqual(result, true, "Currencies should match")
    }
    
    func testTwoCurrencyObjectsAreNotEqual() {
        // Given
        let currencyLHS = LocaleCurrency(localeIdentifier: "en_US")!
        let currencyRHS = LocaleCurrency(localeIdentifier: "fr_TN")!
        // When
        let result = currencyLHS == currencyRHS
        // Then
        XCTAssertEqual(result, false, "Currencies should not match")
    }
    
    //
    // MARK: - Test Performance
    //
    
    func testCreateCurrencyWithLocaleIdentifierPerformance() {
        self.measure() {
            _ = LocaleCurrency(localeIdentifier: "en_US")
        }
    }
    
    func testCreateCurrencyWithCurrencyCodePerformance() {
        self.measure() {
            _ = LocaleCurrency(isoCurrencyCode: "EUR")
        }
    }

}
