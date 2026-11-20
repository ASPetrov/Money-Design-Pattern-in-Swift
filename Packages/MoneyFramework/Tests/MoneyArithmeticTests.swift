//
//  MoneyArithmeticTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import XCTest

final class MoneyArithmeticTests: XCTestCase {
    func testAddMoney() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "12.0", currency: currency))
        let moneyRHS = try XCTUnwrap(Money(amount: "2.0", currency: currency))
        let result = moneyLHS.add(moneyRHS)
        // Then
        XCTAssertEqual(result.amount, Decimal(14), "Money amount should be $ 14.00")
    }

    func testAddAmount() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "12.0", currency: currency))
        // When
        let result = moneyLHS.add(Decimal(2))
        // Then
        XCTAssertEqual(result.amount, Decimal(14), "Money amount should be $ 14.00")
    }

    func testSubtractMoney() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "12.0", currency: currency))
        let moneyRHS = try XCTUnwrap(Money(amount: "2.0", currency: currency))
        // When
        let result = moneyLHS.subtract(moneyRHS)
        // Then
        XCTAssertEqual(result.amount, Decimal(10), "Money amount should be $ 10.00")
    }

    func testSubtractAmount() throws {
        // Given
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "12.0", currency: currency))
        // When
        let result = moneyLHS.subtract(Decimal(2))
        // Then
        XCTAssertEqual(result.amount, Decimal(10),  "Money amount should be $ 10.00")
    }

    func testMultiplyByAmount() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try XCTUnwrap(Money(amount: "12.0", currency: currency))
        let result = moneyLHS.multiply(Decimal(2))
        // Then
        XCTAssertEqual(result.amount, Decimal(24), "Money amount should be $ 24.00")
    }

    func testSubtractOperatorWithMoneyOnEitherSide() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try XCTUnwrap(Money(amount: Decimal(10), currency: currency))

        XCTAssertEqual((money - 3).amount, Decimal(7))
        XCTAssertEqual((3 - money).amount, Decimal(-7))
        XCTAssertEqual((3 - money).currency, currency)
    }

    func testMultiplyOperatorWithMoneyOnEitherSide() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try XCTUnwrap(Money(amount: Decimal(10), currency: currency))

        XCTAssertEqual((money * 3).amount, Decimal(30))
        XCTAssertEqual((3 * money).amount, Decimal(30))
        XCTAssertEqual((3 * money).currency, currency)
    }

    func testArithmeticRoundingIsSelectedPerOperation() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let initialAmount = try XCTUnwrap(Decimal(string: "1.01"))
        let money = try XCTUnwrap(Money(amount: initialAmount, currency: currency, roundingMode: .plain))
        let halfCent = try XCTUnwrap(Decimal(string: "0.005"))

        let first = money.add(halfCent, roundingMode: .plain)

        XCTAssertEqual(first.amount, Decimal(string: "1.02"))
        XCTAssertEqual((first + halfCent).amount, Decimal(string: "1.02"))
        XCTAssertEqual(first.add(halfCent, roundingMode: .plain).amount, Decimal(string: "1.03"))
    }

    func testScalarMinusMoneyUsesDefaultRounding() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try XCTUnwrap(Money(amount: Decimal(1), currency: currency, roundingMode: .up))
        let scalar = try XCTUnwrap(Decimal(string: "0.995"))

        let result = scalar - money

        XCTAssertEqual(result.amount, .zero)
        let multiplier = try Amount(decimalString: "0.125")
        XCTAssertEqual((money * multiplier).amount, Decimal(string: "0.12"))
        XCTAssertEqual(money.multiply(multiplier, roundingMode: .up).amount, Decimal(string: "0.13"))
    }

    func testCheckedDivisionHandlesZeroAndAppliesRequestedRounding() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let zero = try XCTUnwrap(Money(currency: currency))
        let money = try XCTUnwrap(Money(amount: Decimal(1), currency: currency, roundingMode: .plain))

        XCTAssertEqual(try zero.divide(by: 3).amount, .zero)
        XCTAssertEqual(try money.divide(by: 3).amount, Decimal(string: "0.33"))
        let result = try money.divide(by: 8, roundingMode: .plain)
        XCTAssertEqual(result.amount, Decimal(string: "0.13"))
        XCTAssertEqual(try money.divide(by: 8).amount, Decimal(string: "0.12"))
        XCTAssertThrowsError(try money.divide(by: 0)) {
            XCTAssertEqual($0 as? Money<LocaleCurrency>.ArithmeticError, .divisionByZero)
        }
        XCTAssertThrowsError(try money.divide(by: Decimal.nan)) {
            XCTAssertEqual($0 as? Money<LocaleCurrency>.ArithmeticError, .invalidDivisor)
        }
        let largeAmount = try XCTUnwrap(Decimal(string: "1e120"))
        let tinyDivisor = try XCTUnwrap(Decimal(string: "1e-60"))
        let large = try XCTUnwrap(Money(amount: largeAmount, currency: currency))
        XCTAssertThrowsError(try large.divide(by: tinyDivisor)) {
            XCTAssertEqual($0 as? Money<LocaleCurrency>.ArithmeticError, .unrepresentableResult)
        }
    }

    func testUnaryMinusReversesTheSignAndPreservesCurrency() throws {
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        for units in [423, -423, 0] {
            let value = try Amount(minorUnits: units, scale: currency.minorUnits)
            let money = try XCTUnwrap(Money(value: value, currency: currency))
            let negated = -money

            XCTAssertEqual(negated.currency, currency)
            XCTAssertEqual(try negated.checkedMinorUnits(), -units)
        }
    }
}
