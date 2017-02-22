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
    //MARK: - Test Initialization
    //
    
    func testCanCreateCurrencyFromLocaleWithAssociatedCurrency() {
        let locale      = Locale(identifier: "fr_FR")
        let currency    = LocaleCurrency(locale)
        XCTAssertNotNil(currency, "Could not create currency from locale")
    }
    
    func testCanNotCreateCurrencFromLocaleWithoutAssociatedCurrency() {
        let locale      = Locale(identifier: "en")
        let currency    = LocaleCurrency(locale)
        XCTAssertNil(currency, "Should not create currency from locale")
    }
    
    func testCanCreateCurrencyFromCurrentLocale() {
        let currency    = LocaleCurrency()
        XCTAssertNotNil(currency, "Could not create currency from current locale")
    }
    
    //
    //MARK: - Class Methods
    //
    
    func testCanCreateCurrencyWithLocaleIdentifier() {
        let currency    = LocaleCurrency.create(from: "en_US")
        XCTAssertNotNil(currency, "Could not create currency from locale")
    }
    
    func testCanNotCreateCurrencyWithInvalidLocaleIdentifier() {
        let currency    = LocaleCurrency.create(from: "randomString")
        XCTAssertNil(currency, "Should not create currency from invalid locale Identifier")
    }
    
    func testCanCreateCurrencyWithCurrencyCode() {
        let currency    = LocaleCurrency.create(with: "EUR")
        XCTAssertNotNil(currency, "Could not create currency with currency code")
    }
    
    func testCanNotCreateCurrencyWithInvalidCurrencyCode() {
        let currency    = LocaleCurrency.create(with: "randomString")
        XCTAssertNil(currency, "Should not create currency with invalid currency code")
    }
    
    //
    //MARK: - Properties
    //
    
    func testCurrencyCodeMatch() {
        let currency    = LocaleCurrency.create(with: "EUR")!
        XCTAssertEqual(currency.code, "EUR", "Currency code should match")
    }
    
    func testCurrencyCodeNotMatch() {
        let currency    = LocaleCurrency.create(from: "en_US")!
        XCTAssertNotEqual(currency.code, "EUR", "Currency code should not match")
    }
    
    func testCurrencySymbolMatch() {
        let currency    = LocaleCurrency.create(from: "en_US")!
        XCTAssertEqual(currency.symbol, "$", "Currency symbol should match")
    }
    
    func testCurrencySymbolNotMatch() {
        let currency    = LocaleCurrency.create(with: "EUR")!
        XCTAssertNotEqual(currency.symbol, "$", "Currency symbol should not match")
    }
    
    func testCurrencyMaximumFractionDigitsMatch() {
        let currency    = LocaleCurrency.create(from: "fr_TN")!
        XCTAssertEqual(currency.exponent, 3, "Currency maximum fraction digits should match")
    }
    
    func testCurrencyMaximumFractionDigitsNotMatch() {
        let currency    = LocaleCurrency.create(with: "EUR")!
        XCTAssertNotEqual(currency.exponent, 3, "Currency maximum fraction digits should not match")
    }
    
//    func testCanSetNewCurrencyCode() {
//        let currency    = LocaleCurrency()!
//        currency.code   = "EUR"
//        XCTAssertEqual(currency.code, "EUR", "Currency code should match")
//    }
//    
//    func testCanSetNewCurrencySymbol() {
//        let currency    = LocaleCurrency()!
//        currency.symbol = "%"
//        XCTAssertEqual(currency.symbol, "%", "Currency symbol should match")
//    }
//    
//    func testCanSetNewCurrencyMaximumFractionDigits() {
//        let currency    = LocaleCurrency()!
//        currency.exponent = 1
//        XCTAssertEqual(currency.exponent, 1, "Currency maximum fraction digits should match")
//    }
//    
//    func testCanNotSetNewCurrencyMaximumFractionDigits() {
//        let currency    = LocaleCurrency()!
//        currency.exponent = 5
//        XCTAssertNotEqual(currency.exponent, 5, "Currency maximum fraction digits should not match")
//    }
    
    func testCurrencDecimalSeparatorMatch() {
        let currency    = LocaleCurrency.create(from: "de_DE")!
        XCTAssertEqual(currency.separator, ",", "Currency decimal separator should match")
    }
    
    func testCurrencyDecimalSeparatorNotMatch() {
        let currency    = LocaleCurrency.create(from: "en_US")!
        XCTAssertNotEqual(currency.separator, ",", "Currency decimal separator should not match")
    }
    
    func testCurrencGroupingSeparatorMatch() {
        let currency    = LocaleCurrency.create(from: "en_US")!
        XCTAssertEqual(currency.delimiter, ",", "Currency grouping separator should match")
    }
    
    func testCurrencyGroupingSeparatorNotMatch() {
        let currency    = LocaleCurrency.create(from: "de_DE")!
        XCTAssertNotEqual(currency.delimiter, ",", "Currency grouping separator should not match")
    }
    
    //
    //MARK: - Test Public Static Methods
    //
    
    func testDefaultCurrencyIsUSD() {
        let currency            = LocaleCurrency.default
        XCTAssertEqual(currency.code, "USD", "Currency code should match")
    }
    
    //
    //MARK: - Equal
    //
    
    func testTwoCurrencyObjectsAreEqual() {
        let currencyLHS = LocaleCurrency.create(from: "en_US")!
        let currencyRHS = LocaleCurrency.create(from: "en_US")!
        XCTAssertEqual(currencyLHS == currencyRHS, true, "Currencies should match")
    }
    
    func testTwoCurrencyObjectsAreNotEqual() {
        let currencyLHS = LocaleCurrency.create(from: "en_US")!
        let currencyRHS = LocaleCurrency.create(from: "fr_TN")!
        XCTAssertEqual(currencyLHS == currencyRHS, false, "Currencies should not match")
    }
    
    //
    //MARK: - Test Performance
    //
    
    func testCreateCurrencyWithLocaleIdentifierPerformance() {
        self.measure() {
            _ = LocaleCurrency.create(from: "en_US")
        }
    }
    
    func testCreateCurrencyWithCurrencyCodePerformance() {
        self.measure() {
            _ = LocaleCurrency.create(with: "EUR")
        }
    }

}
