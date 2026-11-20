//
//  Money+Arithmetic.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

/// Arithmetic Operators
// NOTE: if the left or the right side amount is nan result will be nan also
extension Money {
    public func add(_ money: Money) -> Money {
        try! adding(money)
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
        try! subtracting(money)
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

    public func multiply(
        _ multiplier: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
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
            return Money(
                amount: result,
                currency: currency,
                roundingMode: roundingMode
            )!
        }
        return try! convertTo(
            currency,
            usingExchangeRate: multiplier.decimalNumber,
            roundingMode: roundingMode
        )
    }

    /// Divides by a dimensionless number and rounds to the currency's minor units using `.bankers` by default.
    /// - Throws: `ArithmeticError` if the divisor is zero or invalid, or the result is unrepresentable.
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
        let status = NSDecimalDivide(
            &quotient,
            &numerator,
            &denominator,
            roundingMode
        )
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

    /// Divides a validated amount with the default rounding mode. Traps if the division fails.
    @available(*, deprecated, message: "Use try divide(by:) to handle invalid divisors and unrepresentable results.")
    public func devide(_ divisor: DecimalRepresentable) -> Money {
        try! divide(by: divisor)
    }
}

extension Money {
    public static func + (lhs: Money, rhs: Money) -> Money {
        lhs.add(rhs)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        lhs.subtract(rhs)
    }

    public static prefix func - (value: Money) -> Money {
        value.multiply(-1)
    }

    public static func + <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        lhs.add(rhs)
    }

    public static func + <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        rhs.add(lhs)
    }

    public static func - <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        lhs.subtract(rhs)
    }

    public static func - <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        let result = lhs.decimalNumber - rhs.amount
        return try! rhs.result(amount: result)
    }

    public static func * <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        lhs.multiply(rhs)
    }

    public static func * <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        rhs.multiply(lhs)
    }
}
