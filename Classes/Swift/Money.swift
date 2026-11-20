//
//  Money.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

/// Swift implementation of Martin Fowler Money Design Pattern
///
/// Example of typical calculations with monetary values, implemented with NSDecimalNumber.

// !!! value objects should be entirely immutable
public struct Money<T: Currency> {
    public let currency: T
    private let value: Amount

    public var amount: Decimal {
        value.decimalValue
    }

    public enum ArithmeticError: Error, Equatable {
        case invalidDivisor
        case divisionByZero
        case unrepresentableResult
        case invalidRecipientCount
        case invalidRatios
        case totalWeightOutOfRange
    }

    // default rounding handler
    public let roundingMode: Decimal.RoundingMode

    // MARK: - Initialization

    public init?(amount: String, currency: T, roundingMode: Decimal.RoundingMode = .bankers) {
        guard let actualAmount = currency.number(from: amount)?.decimalValue ?? Decimal(string: amount) else {
            return nil
        }
        self.init(amount: actualAmount, currency: currency, roundingMode: roundingMode)
    }

    public init?(currency: T) {
        self.init(amount: .zero, currency: currency)
    }

    public init?(amount: Decimal, currency: T, roundingMode: Decimal.RoundingMode = .bankers) {
        guard let value = try? Amount(decimal: amount) else {
            return nil
        }
        self.init(value: value, currency: currency, roundingMode: roundingMode)
    }

    public init?(value: Amount, currency: T, roundingMode: Decimal.RoundingMode = .bankers) {
        guard let rounded = try? value.rounded(scale: currency.minorUnits, mode: roundingMode) else {
            return nil
        }
        self.currency = currency
        self.roundingMode = roundingMode
        self.value = rounded
    }
}

extension Money {

    // MARK: - Amount code suger

    public var isZero: Bool {
        return amount.isZero
    }

    public var isNegative: Bool {
        return amount.isSignMinus
    }

    public var isPositive: Bool {
        return !amount.isSignMinus
    }

    public var absoluteAmount: Decimal {
        return amount.isSignMinus ? -amount : amount
    }

}

extension Money {
    /// Maximum number of results produced by either checked allocation method.
    public static var maximumAllocationRecipients: Int { 1_000_000 }

    /// Allocates equally, assigning any remaining minor units in input order.
    public func allocate(recipientCount: Int) throws -> [Money] {
        guard (1 ... Self.maximumAllocationRecipients).contains(recipientCount) else {
            throw ArithmeticError.invalidRecipientCount
        }
        return try allocate(count: recipientCount, totalWeight: UInt(recipientCount)) { _ in 1 }
    }

    /// Allocates by nonnegative weights and assigns the remainder to positive weights in input order.
    public func allocate(ratios: [Int]) throws -> [Money] {
        guard (1 ... Self.maximumAllocationRecipients).contains(ratios.count) else {
            throw ArithmeticError.invalidRecipientCount
        }
        var totalWeight: UInt = 0
        for ratio in ratios {
            guard let weight = UInt(exactly: ratio) else {
                throw ArithmeticError.invalidRatios
            }
            let (sum, overflow) = totalWeight.addingReportingOverflow(weight)
            guard !overflow else {
                throw ArithmeticError.totalWeightOutOfRange
            }
            totalWeight = sum
        }
        guard totalWeight > 0 else {
            throw ArithmeticError.invalidRatios
        }
        return try allocate(count: ratios.count, totalWeight: totalWeight) { UInt(ratios[$0]) }
    }

    /// For validated inputs. Use allocate(recipientCount:) to handle errors.
    public func allocate(_ n: Int) -> [Money] {
        return try! allocate(recipientCount: n)
    }

    /// For validated inputs. Use allocate(ratios:) to handle errors.
    public func allocate(_ ratios: [Int]) -> [Money] {
        return try! allocate(ratios: ratios)
    }

    private func allocate(count: Int, totalWeight: UInt, weightAt: (Int) -> UInt) throws -> [Money] {
        let units = try checkedMinorUnits()
        let magnitude = units.magnitude
        var remaining = magnitude
        var shares: [UInt] = []
        shares.reserveCapacity(count)

        for index in 0 ..< count {
            let product = magnitude.multipliedFullWidth(by: weightAt(index))
            let share = totalWeight.dividingFullWidth(product).quotient
            shares.append(share)
            remaining -= share
        }
        for index in shares.indices where remaining > 0 && weightAt(index) > 0 {
            shares[index] += 1
            remaining -= 1
        }

        return try shares.map { share in
            // The magnitude can be one larger than Int.max only for a negative amount.
            let signedShare = units < 0 ? Int(bitPattern: 0 &- share) : Int(share)
            let value = try Amount(minorUnits: signedShare, scale: currency.minorUnits)
            guard let money = Money(value: value, currency: currency, roundingMode: roundingMode) else {
                throw ArithmeticError.unrepresentableResult
            }
            return money
        }
    }
}

extension Money {

    // MARK: - Convert

    /// throws  ConvertCurrenciesStrategyError
    public func convertTo(_ currency: T, usingExchangeRate multiplier: Decimal) throws -> Money {
        return try convertTo(currency, usingExchangeRate: multiplier, strategy: NormalConvertStrategy())
    }

    // NOTE: Don't forget to add unit test with your custom strategy
    /// throws  ConvertCurrenciesStrategyError
    public func convertTo(
        _ currency: T,
        usingExchangeRate multiplier: Decimal,
        strategy: ConvertCurrenciesStrategy
    ) throws -> Money {
        return try strategy.convertTo(self, toCurrency: currency, usingExchangeRate: multiplier)
    }

}

private extension Money {
    /// Test for same currency
    func assert(sameCurrencyAs other: Money) {
        precondition(currency == other.currency, "Both Money Objects must be of same currency")
    }
}

// NOTE: Minor Unit is a fraction of the base (ex. cents, stotinka, etc.)
extension Money {

    // MARK: - Minor Unit

    /// For amounts that fit in Int. Use checkedMinorUnits() to handle errors.
    public var amountInMinorUnits: Int {
        return try! checkedMinorUnits()
    }

    public func checkedMinorUnits() throws -> Int {
        return try value.minorUnits(scale: currency.minorUnits)
    }

    public var oneMinorUnit: Decimal {
        return amount(from: 1)
    }

    public func amount(from subunits: Int) -> Decimal {
        return try! Amount(minorUnits: subunits, scale: currency.minorUnits).decimalValue
    }

}

extension Money: CustomStringConvertible {
    public var description: String {
        let string = currency.string(from: NSDecimalNumber(decimal: amount))
        return string ?? ""
    }
}

// NOTE: value objects are equal if all their fields are equal
extension Money: Equatable {
    public func equals(_ other: Money) -> Bool {
        return currency == other.currency && amount == other.amount
    }

    public static func == (lhs: Money, rhs: Money) -> Bool {
        return lhs.equals(rhs)
    }
}

extension Money: Comparable {
    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.assert(sameCurrencyAs: rhs)
        return lhs.amount < rhs.amount
    }
}

/// Arithmetic Operators
// NOTE: if the left or the right side amount is nan result will be nan also
extension Money {
    public func add(_ money: Money) -> Money {
        self.assert(sameCurrencyAs: money)
        return self.add(money.amount)
    }

    public func add(_ newAmount: DecimalRepresentable) -> Money {
        let result = amount + newAmount.decimalNumber
        return Money(amount: result, currency: currency, roundingMode: roundingMode)!
    }

    public func subtract(_ money: Money) -> Money {
        self.assert(sameCurrencyAs: money)
        return self.subtract(money.amount)
    }

    public func subtract(_ newAmount: DecimalRepresentable) -> Money {
        let result = amount - newAmount.decimalNumber
        return Money(amount: result, currency: currency, roundingMode: roundingMode)!
    }

    public func multiply(_ multiplier: DecimalRepresentable) -> Money {
        let result = amount * multiplier.decimalNumber
        return Money(amount: result, currency: currency, roundingMode: roundingMode)!
    }

    // NOTE: used when converting between currencies
    public func multiply(_ multiplier: DecimalRepresentable, currency: T) -> Money {
        let result = amount * multiplier.decimalNumber
        return Money(amount: result, currency: currency, roundingMode: roundingMode)!
    }

    /// Divides using the currency precision and this value's rounding mode.
    public func divide(by divisor: DecimalRepresentable) throws -> Money {
        var denominator = divisor.decimalNumber
        guard !denominator.isNaN else {
            throw ArithmeticError.invalidDivisor
        }
        guard !denominator.isZero else {
            throw ArithmeticError.divisionByZero
        }

        var numerator = amount
        var quotient = Decimal()
        let status = NSDecimalDivide(&quotient, &numerator, &denominator, roundingMode)
        // Accept a truncated intermediate only when currency rounding discards further digits.
        guard
            (status == .noError || status == .lossOfPrecision),
            let result = Money(amount: quotient, currency: currency, roundingMode: roundingMode),
            status != .lossOfPrecision || result.amount != quotient
        else {
            throw ArithmeticError.unrepresentableResult
        }
        return result
    }

    /// For validated inputs. Use divide(by:) to handle errors.
    public func devide(_ divisor: DecimalRepresentable) -> Money {
        return try! divide(by: divisor)
    }

}

extension Money {
    public static prefix func - (value: Money) -> Money {
        return value.multiply(-1)
    }

    public static func + <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }

    public static func + <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }

    public static func - <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.subtract(rhs)
    }

    public static func - <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        let result = lhs.decimalNumber - rhs.amount
        return Money(amount: result, currency: rhs.currency, roundingMode: rhs.roundingMode)!
    }

    public static func * <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.multiply(rhs)
    }

    public static func * <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.multiply(lhs)
    }
}
