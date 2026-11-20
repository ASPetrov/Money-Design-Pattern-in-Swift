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
    public let value: Amount

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
        case incompatibleCurrencies
        case incompatibleCurrencyScale
    }

    // MARK: - Initialization

    public init?(
        amount: String,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        guard let value = currency.parseAmount(amount, locale: nil) else {
            return nil
        }
        self.init(value: value, currency: currency, roundingMode: roundingMode)
    }

    public init?(
        amount: String,
        currency: T,
        locale: Locale,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        guard let value = currency.parseAmount(amount, locale: locale) else {
            return nil
        }
        self.init(value: value, currency: currency, roundingMode: roundingMode)
    }

    public init?(currency: T) {
        self.init(amount: .zero, currency: currency)
    }

    public init?(
        amount: Decimal,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        guard let value = try? Amount(decimal: amount) else {
            return nil
        }
        self.init(value: value, currency: currency, roundingMode: roundingMode)
    }

    public init?(
        value: Amount,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        let scale = currency.minorUnits
        guard
            let rounded = try? value.rounded(scale: scale, mode: roundingMode)
        else {
            return nil
        }
        self.currency = currency
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
        guard
            (1 ... Self.maximumAllocationRecipients).contains(recipientCount)
        else {
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
            return try result(amount: value.decimalValue)
        }
    }
}

extension Money {

    // MARK: - Convert

    public func convertTo(
        _ currency: T,
        usingExchangeRate multiplier: Decimal,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws -> Money {
        return try NormalConvertStrategy.convert(self, to: currency, rate: multiplier, roundingMode: roundingMode)
    }

    public func convertTo<U: Currency>(
        _ currency: U,
        usingExchangeRate multiplier: Decimal,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws -> Money<U> {
        try NormalConvertStrategy.convert(
            self,
            to: currency,
            rate: multiplier,
            roundingMode: roundingMode
        )
    }

    public func convertTo(
        _ currency: T,
        usingExchangeRate multiplier: Decimal,
        strategy: ConvertCurrenciesStrategy
    ) throws -> Money {
        try strategy.convertTo(
            self, toCurrency: currency,
            usingExchangeRate: multiplier
        )
    }

}

private extension Money {
    func checkCompatibility<U: Currency>(with other: Money<U>) throws {
        guard currency.identifier == other.currency.identifier else {
            throw ArithmeticError.incompatibleCurrencies
        }
        guard currency.minorUnits == other.currency.minorUnits else {
            throw ArithmeticError.incompatibleCurrencyScale
        }
    }

    func result(
        amount: Decimal,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws -> Money {
        guard
            let result = Money(amount: amount, currency: currency, roundingMode: roundingMode)
        else {
            throw ArithmeticError.unrepresentableResult
        }
        return result
    }
}

// NOTE: Minor Unit is a fraction of the base (ex. cents, stotinka, etc.)
extension Money {

    // MARK: - Minor Unit

    /// For amounts that fit in Int. Use checkedMinorUnits() to handle errors.
    public var amountInMinorUnits: Int {
        try! checkedMinorUnits()
    }

    public func checkedMinorUnits() throws -> Int {
        try value.minorUnits(scale: currency.minorUnits)
    }

    public var oneMinorUnit: Decimal {
        amount(from: 1)
    }

    public func amount(from subunits: Int) -> Decimal {
        try! Amount(minorUnits: subunits, scale: currency.minorUnits).decimalValue
    }

}

extension Money: CustomStringConvertible {
    public var description: String { formatted() ?? "" }

    public func formatted(locale: Locale? = nil) -> String? {
        currency.string(from: NSDecimalNumber(decimal: amount), locale: locale)
    }
}

// NOTE: value objects are equal if all their fields are equal
extension Money: Equatable {
    public func equals(_ other: Money) -> Bool {
        currency.identifier == other.currency.identifier
            && currency.minorUnits == other.currency.minorUnits
            && value == other.value
    }

    public static func == (lhs: Money, rhs: Money) -> Bool {
        lhs.equals(rhs)
    }
}

extension Money: Comparable {
    public static func < (lhs: Money, rhs: Money) -> Bool {
        return try! lhs.compare(to: rhs) == .orderedAscending
    }

    public func compare<U: Currency>(to other: Money<U>) throws -> ComparisonResult {
        try checkCompatibility(with: other)
        var lhs = amount
        var rhs = other.amount
        return NSDecimalCompare(&lhs, &rhs)
    }
}

/// Arithmetic Operators
// NOTE: if the left or the right side amount is nan result will be nan also
extension Money {
    public func add(_ money: Money) -> Money {
        return try! adding(money)
    }

    public func adding<U: Currency>(_ money: Money<U>) throws -> Money {
        try checkCompatibility(with: money)
        var lhs = amount
        var rhs = money.amount
        var sum = Decimal()
        guard NSDecimalAdd(&sum, &lhs, &rhs, .bankers) == .noError else {
            throw ArithmeticError.unrepresentableResult
        }
        return try result(amount: sum)
    }

    public func add(_ newAmount: DecimalRepresentable, roundingMode: Decimal.RoundingMode = .bankers) -> Money {
        try! result(
            amount: amount + newAmount.decimalNumber,
            roundingMode: roundingMode
        )
    }

    public func subtract(_ money: Money) -> Money {
        return try! subtracting(money)
    }

    public func subtracting<U: Currency>(_ money: Money<U>) throws -> Money {
        try checkCompatibility(with: money)
        var lhs = amount
        var rhs = money.amount
        var difference = Decimal()
        guard
            NSDecimalSubtract(&difference, &lhs, &rhs, .bankers) == .noError
        else {
            throw ArithmeticError.unrepresentableResult
        }
        return try result(amount: difference)
    }

    public func subtract(
        _ newAmount: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        try! result(
            amount: amount - newAmount.decimalNumber,
            roundingMode: roundingMode
        )
    }

    public func multiply(_ multiplier: DecimalRepresentable, roundingMode: Decimal.RoundingMode = .bankers) -> Money {
        try! result(
            amount: amount * multiplier.decimalNumber,
            roundingMode: roundingMode
        )
    }

    public func multiply(
        _ multiplier: DecimalRepresentable,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        if self.currency.identifier == currency.identifier && self.currency.minorUnits == currency.minorUnits {
            let result = amount * multiplier.decimalNumber
            return Money(amount: result, currency: currency, roundingMode: roundingMode)!
        }
        return try! convertTo(
            currency,
            usingExchangeRate: multiplier.decimalNumber,
            roundingMode: roundingMode
        )
    }

    public func divide(
        by divisor: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws -> Money {
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
        guard status == .noError || status == .lossOfPrecision else {
            throw ArithmeticError.unrepresentableResult
        }
        let rounded = try result(amount: quotient, roundingMode: roundingMode)
        guard status != .lossOfPrecision || rounded.amount != quotient else {
            throw ArithmeticError.unrepresentableResult
        }
        return rounded
    }

    /// For validated inputs. Use divide(by:) to handle errors.
    public func devide(_ divisor: DecimalRepresentable) -> Money {
        return try! divide(by: divisor)
    }

}

extension Money {
    public static func + (lhs: Money, rhs: Money) -> Money {
        return lhs.add(rhs)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        return lhs.subtract(rhs)
    }

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
        return try! rhs.result(amount: result)
    }

    public static func * <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.multiply(rhs)
    }

    public static func * <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.multiply(lhs)
    }
}
