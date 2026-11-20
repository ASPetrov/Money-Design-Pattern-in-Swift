//
//  MoneyTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import XCTest

class MoneyTests: XCTestCase {

    //
    // MARK: - Initialization
    //

    func testCanCreateMoney() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        // Implicit Zero amount
        // When
        let money = Money(currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money")
    }

    func testCanCreateMoneyWithAmountAsDecimal() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = Decimal(1)
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money with decimal amount")
    }

    func testCanCreateMoneyWithAmountAsString() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = "1"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money with string amount")
    }

    func testCanCreateMoneyWithAmountAsFormattedString() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "USD"))
        let amount = "$1"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotNil(money, "Could not create money with formatted string amount")
    }

    func testCanNotCreateMoneyWithBadDecimal() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = Decimal.nan
        // When
        let money = Money(amount: amount, currency: currency )
        // Then
        XCTAssertNil(money, "Could not create money with not a number")
    }

    func testCanNotCreateMoneyWithBadString() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = "Random &^Ugjh2 string"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNil(money, "Could not create money with random string")
    }

    //
    // MARK: - Test Public Read Only Properties
    //

    func testCanReadCurrency() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "4.23"))
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertEqual(money?.currency, currency, "Money currency should match")
    }

    func testCanReadAmount() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "4.23"))
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertEqual(money?.amount, amount, "Money amount should match")
    }

    //
    // MARK: - Test Decimal/amount Facade Methods
    //

    func testIsZeroReturnsTrue() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        // When
        let money = Money(currency: currency)
        // Then
        XCTAssertEqual(money?.amount, .zero, "Money amount should be zero")
    }

    func testIsZeroReturnsFalse() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "4.23"))
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        XCTAssertNotEqual(money?.amount, .zero, "Money amount should not be zero")
    }

    func testIsNegativeReturnsTrue() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "-4.23"))
        // When
        let money = try XCTUnwrap(Money(amount: amount, currency: currency))
        // Then
        XCTAssertTrue(money.isNegative, "Money amount should be negative")
    }

    func testIsNegativeReturnsFalse() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "4.23"))
        // When
        let money = try XCTUnwrap(Money(amount: amount, currency: currency))
        // Then
        XCTAssertFalse(money.isNegative, "Money amount should not be negative")
    }

    func testIsPositiveReturnsTrue() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "4.23"))
        // When
        let money = try XCTUnwrap(Money(amount: amount, currency: currency))
        // Then
        XCTAssertTrue(money.isPositive, "Money amount should be positive")
    }

    func testIsPositiveReturnsFalse() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "-4.23"))
        // When
        let money = try XCTUnwrap(Money(amount: amount, currency: currency))
        // Then
        XCTAssertFalse(money.isPositive, "Money amount should not be positive")
    }

    func testAbsolute() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "-4.23"))
        // When
        let money = try XCTUnwrap(Money(amount: amount, currency: currency))
        // Then
        XCTAssertFalse(money.absoluteAmount.isSignMinus, "Money amount should not be positive")
    }

    //
    // MARK: - Test Minor Units Methods
    //

    func testAmountInSubunits() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try XCTUnwrap(Decimal(string: "4.23"))
        // When
        let money = try XCTUnwrap(Money(amount: amount, currency: currency))
        // Then
        XCTAssertEqual(money.amountInMinorUnits, 423, "Subunits amount should match")
    }

    func testOneSubunit() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let oneMinorUnit = Decimal(string: "0.01")
        // When
        let money = try XCTUnwrap(Money(currency: currency))
        // Then
        XCTAssertEqual(money.oneMinorUnit, oneMinorUnit, "Smallest subunit should match")
    }

    //
    // MARK: - Convert
    //

    func testConvertEurosToDollars() throws {
        // Given
        let EUR = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let USD = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "USD"))
        let amount = try XCTUnwrap(Decimal(string: "20"))
        let euros = try XCTUnwrap(Money(amount: amount, currency: EUR))
        let exchangeRate = try XCTUnwrap(Decimal(string: "1.1234"))
        // When
        let dollars = try euros.convertTo(USD, usingExchangeRate: exchangeRate)
        // Then
        XCTAssertEqual(
            dollars.amount,
            Decimal(string: "22.47"),
            "Dollars amount should be 22.47"
        )
    }

    // TODO: Test Convert ot Same Currency (NOTE: throws "Cannot convert to the same currency")
    // TODO: Test Convert with negative multiplier (NOTE:  throws "Cannot convert using a negative conversion multiplier")

    //
    // MARK: - Equal
    //

    // opertator == is using equals method (??? - no need to be tested)
    func testTwoMoneyObjectsWithSameAmountAndCurrencyAreEqual() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "0.0", currency: currency))
        let moneyRHS = try XCTUnwrap(Money(amount: "0.0", currency: currency))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertTrue(result, "Money should match")
    }

    func testTwoMoneyObjectsWithDifferentAmountAndSameCurrencyAreNotEqual() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "0.0", currency: currency))
        let moneyRHS = try XCTUnwrap(Money(amount: "15.0", currency: currency))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertFalse(result, "Money should not match")
    }

    func testTwoMoneyObjectsWithSameAmountAndDifferentCurrencyAreNotEqual() throws {
        // Given
        let currencyLHS = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let currencyRHS = try XCTUnwrap(LocaleCurrency(localeIdentifier: "fr_TN"))
        let moneyLHS = try XCTUnwrap(Money(amount: "0.0", currency: currencyLHS))
        let moneyRHS = try XCTUnwrap(Money(amount: "0.0", currency: currencyRHS))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertFalse(result, "Money should not match")
    }

    func testTwoMoneyObjectsWithDifferentAmountAndDifferentCurrencyAreNotEqual() throws {
        // Given
        let currencyLHS = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let currencyRHS = try XCTUnwrap(LocaleCurrency(localeIdentifier: "fr_TN"))
        let moneyLHS = try XCTUnwrap(Money(amount: "0.0", currency: currencyLHS))
        let moneyRHS = try XCTUnwrap(Money(amount: "13.33", currency: currencyRHS))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        XCTAssertFalse(result, "Money should not match")
    }

    //
    // MARK: - Comparable
    //

    func testLeftSideMoneyObjectAmountIsGreaterThanRightSideMoneyObjectAmount() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "15.0", currency: currency))
        let moneyRHS = try XCTUnwrap(Money(amount: "2.0", currency: currency))
        // When
        let result = moneyLHS > moneyRHS
        // Then
        XCTAssertTrue(result, "Money on the left side should have greater amount than  money on the right side")
    }

    func testLeftSideMoneyObjectAmmountIsLessThanRightSideMoneyObjectAmount() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "2.0", currency: currency))
        let moneyRHS = try XCTUnwrap(Money(amount: "15.0", currency: currency))
        // When
        let result = moneyLHS < moneyRHS
        // Then
        XCTAssertTrue(result, "Money on the left side should have less amount than  money on the right side")
    }

    // TODO: Test with different currencies

    func testConversionAppliesRequestedRoundingAtTargetCurrencyPrecision() throws {
        let usd = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let jpy = try XCTUnwrap(LocaleCurrency(localeIdentifier: "ja_JP"))
        let money = try XCTUnwrap(Money(amount: Decimal(1), currency: usd, roundingMode: .plain))
        let rate = try XCTUnwrap(Decimal(string: "2.5"))

        let converted = try money.convertTo(jpy, usingExchangeRate: rate, roundingMode: .plain)

        XCTAssertEqual(converted.currency, jpy)
        XCTAssertEqual(converted.amount, Decimal(3))
        XCTAssertEqual(try money.convertTo(jpy, usingExchangeRate: rate).amount, Decimal(2))
    }

    func testAmountBackedMoneyPreservesPublicDecimalAccessAndRounding() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let value = try Amount(decimalString: "1.025")
        let money = try XCTUnwrap(Money(value: value, currency: currency, roundingMode: .plain))
        let amount: Decimal = money.amount

        XCTAssertEqual(amount, Decimal(string: "1.03"))
        XCTAssertEqual(money.value.decimalValue, amount)
        XCTAssertEqual(Money(amount: .zero, currency: currency)?.amount, .zero)
        XCTAssertEqual(Money(amount: "1.25", currency: currency)?.amount, Decimal(string: "1.25"))
        XCTAssertEqual(Money(currency: currency)?.amount, .zero)
    }
}
