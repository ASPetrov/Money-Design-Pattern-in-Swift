//
//  Currency.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import UIKit
import XCTest

class CurrencyTests: XCTestCase {
    
    //
    // MARK: - Test Initialization
    //
    
    func testCanCreateCurrencyFromLocaleWithAssociatedCurrency() {
        let locale      = NSLocale(localeIdentifier: "fr_FR")
        let currency    = Currency(locale: locale)
        XCTAssertNotNil(currency, "Could not create currency from locale")
    }
    
    func testCanNotCreateCurrencFromLocaleWithoutAssociatedCurrency() {
        let locale      = NSLocale(localeIdentifier: "en")
        let currency    = Currency(locale: locale)
        XCTAssertNil(currency, "Should not create currency from locale")
    }
    
    func testCanCreateCurrencyFromCurrentLocale() {
        let currency    = Currency()
        XCTAssertNotNil(currency, "Could not create currency from current locale")
    }
    
    //
    // MARK: - Class Methods
    //
    
    func testCanCreateCurrencyWithLocaleIdentifier() {
        let currency    = Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")
        XCTAssertNotNil(currency, "Could not create currency from locale")
    }
    
    func testCanNotCreateCurrencyWithInvalidLocaleIdentifier() {
        let currency    =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "randomString")
        XCTAssertNil(currency, "Should not create currency from invalid locale Identifier")
    }
    
    func testCanCreateCurrencyWithCurrencyCode() {
        let currency    = Currency.currencyWithCurrencyCode(currencyCode: "EUR")
        XCTAssertNotNil(currency, "Could not create currency with currency code")
    }
    
    func testCanNotCreateCurrencyWithInvalidCurrencyCode() {
        let currency    =
            Currency.currencyWithCurrencyCode(currencyCode: "randomString")
        XCTAssertNil(currency, "Should not create currency with invalid currency code")
    }
    
    //
    // MARK: - Properties
    //
    
    func testCurrencyCodeMatch() {
        let currency    = Currency.currencyWithCurrencyCode(currencyCode: "EUR")!
        XCTAssertEqual(currency.code, "EUR", "Currency code should match")
    }
    
    func testCurrencyCodeNotMatch() {
        let currency    =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        XCTAssertNotEqual(currency.code, "EUR", "Currency code should not match")
    }
    
    func testCurrencySymbolMatch() {
        let currency    =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        XCTAssertEqual(currency.symbol, "$", "Currency symbol should match")
    }
    
    func testCurrencySymbolNotMatch() {
        let currency    = Currency.currencyWithCurrencyCode(currencyCode: "EUR")!
        XCTAssertNotEqual(currency.symbol, "$", "Currency symbol should not match")
    }
    
    func testCurrencyMaximumFractionDigitsMatch() {
        let currency    =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "fr_TN")!
        XCTAssertEqual(currency.maximumFractionDigits, 3, "Currency maximum fraction digits should match")
    }
    
    func testCurrencyMaximumFractionDigitsNotMatch() {
        let currency    = Currency.currencyWithCurrencyCode(currencyCode: "EUR")!
        XCTAssertNotEqual(currency.maximumFractionDigits, 3, "Currency maximum fraction digits should not match")
    }
    
    func testCanSetNewCurrencyCode() {
        let currency    = Currency()!
        currency.code   = "EUR"
        XCTAssertEqual(currency.code, "EUR", "Currency code should match")
    }
    
    func testCanSetNewCurrencySymbol() {
        let currency    = Currency()!
        currency.symbol = "%"
        XCTAssertEqual(currency.symbol, "%", "Currency symbol should match")
    }
    
    func testCanSetNewCurrencyMaximumFractionDigits() {
        let currency    = Currency()!
        currency.maximumFractionDigits = 1
        XCTAssertEqual(currency.maximumFractionDigits, 1, "Currency maximum fraction digits should match")
    }
    
    func testCanNotSetNewCurrencyMaximumFractionDigits() {
        let currency    = Currency()!
        currency.maximumFractionDigits = 5
        XCTAssertNotEqual(currency.maximumFractionDigits, 5, "Currency maximum fraction digits should not match")
    }
    
    func testCurrencDecimalSeparatorMatch() {
        let currency    =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "de_DE")!
        XCTAssertEqual(currency.decimalSeparator, ",", "Currency decimal separator should match")
    }
    
    func testCurrencyDecimalSeparatorNotMatch() {
        let currency    = Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        XCTAssertNotEqual(currency.decimalSeparator, ",", "Currency decimal separator should not match")
    }
    
    func testCurrencGroupingSeparatorMatch() {
        let currency    =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        XCTAssertEqual(currency.groupingSeparator, ",", "Currency grouping separator should match")
    }
    
    func testCurrencyGroupingSeparatorNotMatch() {
        let currency    = Currency.currencyForLocaleIdentifier(localeIdentifier: "de_DE")!
        XCTAssertNotEqual(currency.groupingSeparator, ",", "Currency grouping separator should not match")
    }
    
    //
    // MARK: - Equal
    //
    
    func testTwoCurrencyObjectsAreEqual() {
        let currencyLHS =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        let currencyRHS = Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        XCTAssertEqual(currencyLHS == currencyRHS, true, "Currencies should match")
    }
    
    func testTwoCurrencyObjectsAreNotEqual() {
        let currencyLHS =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
        let currencyRHS =
            Currency.currencyForLocaleIdentifier(localeIdentifier: "fr_TN")!
        XCTAssertEqual(currencyLHS == currencyRHS, false, "Currencies should not match")
    }
    
    //
    // MARK: - Test Performance
    //
    
    func testCreateCurrencyWithLocaleIdentifierPerformance() {
        self.measureBlock() {
            Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")
        }
    }
    
    func testCreateCurrencyWithCurrencyCodePerformance() {
        self.measureBlock() {
            Currency.currencyWithCurrencyCode(currencyCode: "EUR")
        }
    }

}
