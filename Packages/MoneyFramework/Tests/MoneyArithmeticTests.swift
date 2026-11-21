//
//  MoneyArithmeticTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import Testing

private let roundingCases: [(Int, Decimal.RoundingMode, Int)] = [
    (4, .bankers, 0), (5, .bankers, 0), (6, .bankers, 1), (15, .bankers, 2),
    (-4, .bankers, 0), (-5, .bankers, 0), (-6, .bankers, -1), (-15, .bankers, -2),
    (5, .plain, 1), (-5, .plain, -1),
    (4, .down, 0), (-4, .down, -1),
    (4, .up, 1), (-4, .up, 0),
]

struct MoneyArithmeticTests {

    @Test func testScalarRoundingPastHalfCent() throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let one = try Money(parsing: "1.00", currency: usd)
        let elevenCents = try Money(parsing: "0.11", currency: usd)
        let oneCent = try Money(parsing: "0.01", currency: usd)
        let rounded = try Money(parsing: "1.01", currency: usd)

        #expect(one.addingChecked("0.0050000000000000000000000000000000000001") == .success(rounded))
        #expect(one.subtractingChecked("-0.0050000000000000000000000000000000000001") == .success(rounded))
        #expect(elevenCents.multiplyingChecked(by: "9.1363636363636363636363636363636363637") == .success(rounded))
        #expect(oneCent.dividingChecked(by: "0.0099502487562189054726368159203980099502") == .success(rounded))
    }

    @Test(arguments: roundingCases, ["USD", "JPY"])
    func testDivisionAtRoundingBoundaries(
        example: (amount: Int, mode: Decimal.RoundingMode, units: Int),
        code: String
    ) throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: code))
        let money = try Money(validating: Amount(integer: example.amount), currency: currency)
        let divisor = code == "JPY" ? 10 : 1000

        let result = try money.divide(by: divisor, roundingMode: example.mode)

        #expect(try result.checkedMinorUnits() == example.units)
    }

    @Test func testConversionRoundsPastHalfCent() throws {
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let eur = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let source = try Money(parsing: "0.11", currency: usd)
        let rate = try Amount(decimalString: "9.1363636363636363636363636363636363637")
        let expected = try Money(parsing: "1.01", currency: eur)

        #expect(try source.convertTo(eur, usingExchangeRate: rate.decimalValue) == expected)
    }

    @Test func testAddMoney() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "12.0", currency: currency))
        let moneyRHS = try #require(Money(amount: "2.0", currency: currency))
        let result = moneyLHS.add(moneyRHS)
        // Then
        #expect(result.amount == Decimal(14), "Money amount should be $ 14.00")
    }

    @Test func testAddAmount() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "12.0", currency: currency))
        // When
        let result = moneyLHS.add(Decimal(2))
        // Then
        #expect(result.amount == Decimal(14), "Money amount should be $ 14.00")
    }

    @Test func testSubtractMoney() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "12.0", currency: currency))
        let moneyRHS = try #require(Money(amount: "2.0", currency: currency))
        // When
        let result = moneyLHS.subtract(moneyRHS)
        // Then
        #expect(result.amount == Decimal(10), "Money amount should be $ 10.00")
    }

    @Test func testSubtractAmount() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "12.0", currency: currency))
        // When
        let result = moneyLHS.subtract(Decimal(2))
        // Then
        #expect(result.amount == Decimal(10), "Money amount should be $ 10.00")
    }

    @Test func testMultiplyByAmount() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "12.0", currency: currency))
        let result = moneyLHS.multiply(Decimal(2))
        // Then
        #expect(result.amount == Decimal(24), "Money amount should be $ 24.00")
    }

    @Test func testSubtractsWithMoneyOnEitherSide() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try #require(Money(amount: Decimal(10), currency: currency))

        #expect((money - 3).amount == Decimal(7))
        #expect((3 - money).amount == Decimal(-7))
        #expect((3 - money).currency == currency)
    }

    @Test func testMultipliesWithMoneyOnEitherSide() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try #require(Money(amount: Decimal(10), currency: currency))

        #expect((money * 3).amount == Decimal(30))
        #expect((3 * money).amount == Decimal(30))
        #expect((3 * money).currency == currency)
    }

    @Test func testSelectsRoundingPerOperation() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let initialAmount = try #require(Decimal(string: "1.01"))
        let money = try #require(Money(amount: initialAmount, currency: currency, roundingMode: .plain))
        let halfCent = try #require(Decimal(string: "0.005"))

        let first = money.add(halfCent, roundingMode: .plain)

        #expect(first.amount == Decimal(string: "1.02"))
        #expect((first + halfCent).amount == Decimal(string: "1.02"))
        #expect(first.add(halfCent, roundingMode: .plain).amount == Decimal(string: "1.03"))
    }

    @Test func testScalarMinusMoneyUsesDefaultRounding() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try #require(Money(amount: Decimal(1), currency: currency, roundingMode: .up))
        let scalar = try #require(Decimal(string: "0.995"))

        let result = scalar - money

        #expect(result.amount == .zero)
        let multiplier = try Amount(decimalString: "0.125")
        #expect((money * multiplier).amount == Decimal(string: "0.12"))
        #expect(money.multiply(multiplier, roundingMode: .up).amount == Decimal(string: "0.13"))
    }

    @Test func testMultiplyKeepsTargetCurrency() throws {
        let euros = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let dollars = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        var target = euros
        target.name = "Target euro"
        let amount = try Amount(decimalString: "0.25")
        let money = try Money(validating: amount, currency: euros)

        let product = money.multiply(0.5, currency: target, roundingMode: .plain)
        #expect(product.amount == Decimal(string: "0.13"))
        #expect(product.currency.name == target.name)
        let converted = money.multiply(2, currency: dollars)
        #expect(converted.amount == Decimal(string: "0.50"))
        #expect(converted.currency == dollars)
    }

    @Test func testCheckedArithmeticReturnsFailures() throws {
        let eur = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let usd = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let money = try Money(validating: Amount(integer: 10), currency: eur)
        let dollars = try Money(validating: Amount(integer: 1), currency: usd)
        let largeAmount = try #require(Decimal(string: "1e120"))
        let factor = try #require(Decimal(string: "1e60"))
        let large = try Money(validating: Amount(decimal: largeAmount), currency: eur)

        #expect(money.addingChecked(2) == .success(money + 2))
        #expect(money.subtractingChecked(2) == .success(money - 2))
        #expect(money.multiplyingChecked(by: 2) == .success(money * 2))
        let quotient = try money.divide(by: 2)
        #expect(money.dividingChecked(by: 2) == .success(quotient))
        #expect(money.addingChecked(dollars) == .failure(.incompatibleCurrencies))
        #expect(money.subtractingChecked(dollars) == .failure(.incompatibleCurrencies))
        #expect(money.addingChecked("invalid") == .failure(.invalidScalar))
        #expect(money.dividingChecked(by: 0) == .failure(.divisionByZero))
        #expect(large.multiplyingChecked(by: factor) == .failure(.unrepresentableResult))
    }

    @Test func testCheckedDivisionWithZeroAndRounding() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let zero = try #require(Money(currency: currency))
        let money = try #require(Money(amount: Decimal(1), currency: currency, roundingMode: .plain))

        #expect(try zero.divide(by: 3).amount == .zero)
        #expect(try money.divide(by: 3).amount == Decimal(string: "0.33"))
        let result = try money.divide(by: 8, roundingMode: .plain)
        #expect(result.amount == Decimal(string: "0.13"))
        #expect(try money.divide(by: 8).amount == Decimal(string: "0.12"))
        #expect(throws: Money<LocaleCurrency>.ArithmeticError.divisionByZero) {
            _ = try money.divide(by: 0)
        }
        #expect(throws: Money<LocaleCurrency>.ArithmeticError.invalidDivisor) {
            _ = try money.divide(by: Decimal.nan)
        }
        let largeAmount = try #require(Decimal(string: "1e120"))
        let tinyDivisor = try #require(Decimal(string: "1e-60"))
        let large = try #require(Money(amount: largeAmount, currency: currency))
        #expect(throws: Money<LocaleCurrency>.ArithmeticError.unrepresentableResult) {
            _ = try large.divide(by: tinyDivisor)
        }
    }

    @Test(arguments: [423, -423, 0])
    func testNegationFlipsSignAndKeepsCurrency(units: Int) throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let value = try Amount(minorUnits: units, scale: currency.minorUnits)
        let money = try #require(Money(value: value, currency: currency))
        let negated = -money

        #expect(negated.currency == currency)
        #expect(try negated.checkedMinorUnits() == -units)
    }
}
