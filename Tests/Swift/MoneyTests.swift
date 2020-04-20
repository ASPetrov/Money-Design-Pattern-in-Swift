//
//  MoneyTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import XCTest
@testable import MoneyFramework

class MoneyTests: XCTestCase {

    //
    // MARK: - Initialization
    //

    func testCanCreateMoney() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        // Implicit Zero amount
        // When
        let money = Money(currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money")
    }

    func testCanCreateMoneyWithAmountAsDecimal() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(1)
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money with decimal amount")
    }

    func testCanCreateMoneyWithAmountAsString() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = "1"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money with string amount")
    }

    func testCanCreateMoneyWithAmountAsFormattedString() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "USD")!
        let amount = "$1"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money with formatted string amount")
    }

    func testCanNotCreateMoneyWithBadDecimal() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal.nan
        // When
        let money = Money(amount: amount, currency: currency )
        // Then
        XCTAssertNil(money, "Could not create money with not a number")
    }

    func testCanNotCreateMoneyWithBadString() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = "Random &^Ugjh2 string"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNil(money, "Could not create money with random string")
    }

    //
    // MARK: - Test Public Read Only Properties
    //

    func testCanReadCurrency() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "4.23")!
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertEqual(money?.currency, currency, "Money currency should match")
    }

    func testCanReadAmount() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "4.23")!
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertEqual(money?.amount, amount, "Money amount should match")
    }

    //
    // MARK: - Test Decimal/amount Facade Methods
    //

    func testIsZeroReturnsTrue() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        // When
        let money = Money(currency: currency)
        // Then
        XCTAssertEqual(money?.amount, .zero, "Money amount should be zero")
    }

    func testIsZeroReturnsFalse() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "4.23")!
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotEqual(money?.amount, .zero, "Money amount should not be zero")
    }

    func testIsNegativeReturnsTrue() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "-4.23")!
        // When
        let money = Money(amount: amount, currency: currency)!
        // Then
        XCTAssertTrue(money.isNegative, "Money amount should be negative")
    }

    func testIsNegativeReturnsFalse() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "4.23")!
        // When
        let money = Money(amount: amount, currency: currency)!
        // Then
        XCTAssertFalse(money.isNegative, "Money amount should not be negative")
    }

    func testIsPositiveReturnsTrue() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "4.23")!
        // When
        let money = Money(amount: amount, currency: currency)!
        // Then
        XCTAssertTrue(money.isPositive, "Money amount should be positive")
    }

    func testIsPositiveReturnsFalse() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "-4.23")!
        // When
        let money = Money(amount: amount, currency: currency)!
        // Then
        XCTAssertFalse(money.isPositive, "Money amount should not be positive")
    }

    func testAbsolute() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "-4.23")!
        // When
        let money = Money(amount: amount, currency: currency)!
        // Then
        XCTAssertFalse(money.absoluteAmount.isSignMinus, "Money amount should not be positive")
    }

    //
    // MARK: - Test Minor Units Methods
    //

    func testAmountInSubunits() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "4.23")!
        // When
        let money = Money(amount: amount, currency: currency)!
        // Then
        XCTAssertEqual(money.amountInMinorUnits, 423, "Subunits amount should match")
    }

    func testOneSubunit() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let oneMinorUnit = Decimal(string: "0.01")
        // When
        let money = Money(currency: currency)!
        // Then
        XCTAssertEqual(money.oneMinorUnit, oneMinorUnit, "Smallest subunit should match")
    }

    //
    // MARK: - Allocate
    //

    func testAllocateToRecepients() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "0.05")!
        let money = Money(amount: amount, currency: currency)!
         // When
        let array = money.allocate(2)
        // Then
        XCTAssertEqual(array[0].amount,
                       Decimal(string: "0.03"),
                       "First recepient should have 0.03")
        XCTAssertEqual(array[1].amount,
                       Decimal(string: "0.02"),
                       "Second recepient should have 0.02")
    }

    // TODO: Test Allocate to Zero Recepients (throws "Division by zero")

    func testAllocateToRecepientsUsingRatios() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "1")!
        let money = Money(amount: amount, currency: currency)!
        // When
        let array = money.allocate([70, 30])
        // Then
        XCTAssertEqual(array[0].amount,
                       Decimal(string: "0.70"),
                       "First recepient should have 0.70")
        XCTAssertEqual(array[1].amount,
                       Decimal(string: "0.30"),
                       "Second recepient should have 0.30")
    }

    //
    // MARK: - Convert
    //

    func testConvertEurosToDollars() {
        // Given
        let EUR = LocaleCurrency(isoCurrencyCode: "EUR")!
        let USD = LocaleCurrency(isoCurrencyCode: "USD")!
        let amount = Decimal(string: "20")!
        let euros = Money(amount: amount, currency: EUR)!
        let exchangeRate = Decimal(string: "1.1234")!
        // When
        let dollars = try! euros.convertTo(USD, usingExchangeRate: exchangeRate)
        // Then
        XCTAssertEqual(dollars.amount,
                       Decimal(string: "22.47"),
                       "Dollars amount should be 22.47")
    }

    // TODO: Test Convert ot Same Currency (NOTE: throws "Cannot convert to the same currency")
    // TODO: Test Convert with negative multiplier (NOTE:  throws "Cannot convert using a negative conversion multiplier")

    //
    // MARK: - Equal
    //

    // opertator == is using equals method (??? - no need to be tested)
    func testTwoMoneyObjectsWithSameAmountAndCurrencyAreEqual() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "0.0", currency: currency)!
        let moneyRHS = Money(amount: "0.0", currency: currency)!
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertTrue(result, "Money should match")
    }

    func testTwoMoneyObjectsWithDifferentAmountAndSameCurrencyAreNotEqual() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "0.0", currency: currency)!
        let moneyRHS = Money(amount: "15.0", currency: currency)!
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertFalse(result, "Money should not match")
    }

    func testTwoMoneyObjectsWithSameAmountAndDifferentCurrencyAreNotEqual() {
        // Given
        let currencyLHS = LocaleCurrency(localeIdentifier: "en_US")!
        let currencyRHS = LocaleCurrency(localeIdentifier: "fr_TN")!
        let moneyLHS = Money(amount: "0.0", currency: currencyLHS)!
        let moneyRHS = Money(amount: "0.0", currency: currencyRHS)!
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertFalse(result, "Money should not match")
    }

    func testTwoMoneyObjectsWithDifferentAmountAndDifferentCurrencyAreNotEqual() {
        // Given
        let currencyLHS = LocaleCurrency(localeIdentifier: "en_US")!
        let currencyRHS = LocaleCurrency(localeIdentifier: "fr_TN")!
        let moneyLHS = Money(amount: "0.0", currency: currencyLHS)!
        let moneyRHS = Money(amount: "13.33", currency: currencyRHS)!
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertFalse(result, "Money should not match")
    }

    //
    // MARK: - Comparable
    //

    func testLeftSideMoneyObjectAmountIsGreaterThanRightSideMoneyObjectAmount() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "15.0", currency: currency)!
        let moneyRHS = Money(amount: "2.0", currency: currency)!
        // When
        let result = moneyLHS > moneyRHS
        // Then
        XCTAssertTrue(result, "Money on the left side should have greater amount than  money on the right side")
    }

    func testLeftSideMoneyObjectAmmountIsLessThanRightSideMoneyObjectAmount() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "2.0", currency: currency)!
        let moneyRHS = Money(amount: "15.0", currency: currency)!
        // When
        let result = moneyLHS < moneyRHS
        // Then
        XCTAssertTrue(result, "Money on the left side should have less amount than  money on the right side")
    }

    // TODO: Test with different currencies

    //
    // MARK: - Arithmetic
    //

    func testAddMoney() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "12.0", currency: currency)!
        let moneyRHS = Money(amount: "2.0", currency: currency)!
        let result = moneyLHS.add(moneyRHS)
        // Then
        XCTAssertEqual(result.amount, Decimal(14), "Money amount should be $ 14.00")
    }

    func testAddAmount() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "12.0", currency: currency)!
        // When
        let result = moneyLHS.add(Decimal(2))
        // Then
        XCTAssertEqual(result.amount, Decimal(14), "Money amount should be $ 14.00")
    }

    func testSubtractMoney() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "12.0", currency: currency)!
        let moneyRHS = Money(amount: "2.0", currency: currency)!
        // When
        let result = moneyLHS.subtract(moneyRHS)
        // Then
        XCTAssertEqual(result.amount, Decimal(10), "Money amount should be $ 10.00")
    }

    func testSubtractAmount() {
        // Given
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "12.0", currency: currency)!
        // When
        let result = moneyLHS.subtract(Decimal(2))
        // Then
        XCTAssertEqual(result.amount, Decimal(10),  "Money amount should be $ 10.00")
    }


    func testMultiplyByAmount() {
        let currency = LocaleCurrency(localeIdentifier: "en_US")!
        let moneyLHS = Money(amount: "12.0", currency: currency)!
        let result = moneyLHS.multiply(Decimal(2))
        // Then
        XCTAssertEqual(result.amount, Decimal(24), "Money amount should be $ 24.00")
    }

    // TODO: Test Arithmetic operations with NaN
    // TODO: Test different currencies exceptions in compare and arithmetic methods
    // TODO: Test Unary minus operator (NOTE: it is based on multiply)
}
