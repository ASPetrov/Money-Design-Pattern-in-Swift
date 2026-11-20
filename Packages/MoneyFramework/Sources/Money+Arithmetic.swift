//
//  Money+Arithmetic.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

extension Money {
    /// Requires compatible currencies and a representable result.
    public func add(_ money: Money) -> Money {
        requireValidMoneyOperation("addition") {
            addingChecked(money)
        }
    }

    /// Adds compatible monetary values and reports any arithmetic error.
    public func addingChecked<U: Currency>(
        _ money: Money<U>
    ) -> Result<Money, ArithmeticError> {
        arithmeticResult { try adding(money) }
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
        requireValidMoneyOperation("scalar addition") {
            addingChecked(newAmount, roundingMode: roundingMode)
        }
    }

    /// Adds a scalar in major currency units and reports any arithmetic error.
    public func addingChecked(
        _ scalar: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Result<Money, ArithmeticError> {
        checkedScalarOperation(
            amount,
            scalar.decimalNumber,
            roundingMode: roundingMode,
            calculate: NSDecimalAdd
        )
    }

    /// Requires compatible currencies and a representable result.
    public func subtract(_ money: Money) -> Money {
        requireValidMoneyOperation("subtraction") {
            subtractingChecked(money)
        }
    }

    /// Subtracts compatible monetary values and reports any arithmetic error.
    public func subtractingChecked<U: Currency>(
        _ money: Money<U>
    ) -> Result<Money, ArithmeticError> {
        arithmeticResult { try subtracting(money) }
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
        requireValidMoneyOperation("scalar subtraction") {
            subtractingChecked(
                newAmount,
                roundingMode: roundingMode
            )
        }
    }

    /// Subtracts a scalar in major currency units and reports any arithmetic error.
    public func subtractingChecked(
        _ scalar: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Result<Money, ArithmeticError> {
        checkedScalarOperation(
            amount, scalar.decimalNumber,
            roundingMode: roundingMode,
            calculate: NSDecimalSubtract
        )
    }

    public func multiply(
        _ multiplier: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        requireValidMoneyOperation("multiplication") {
            multiplyingChecked(
                by: multiplier,
                roundingMode: roundingMode
            )
        }
    }

    /// Multiplies by a dimensionless scalar and reports any arithmetic error.
    public func multiplyingChecked(
        by multiplier: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Result<Money, ArithmeticError> {
        checkedScalarOperation(
            amount,
            multiplier.decimalNumber,
            roundingMode: roundingMode,
            calculate: NSDecimalMultiply
        )
    }

    public func multiply(
        _ multiplier: DecimalRepresentable,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        requireValidMoneyOperation("multiplication with target currency") {
            if self.currency.identifier == currency.identifier && self.currency.minorUnits == currency.minorUnits {
                let product: Money = requireValidMoneyOperation("multiplication with target currency") {
                    multiplyingChecked(by: multiplier, roundingMode: roundingMode)
                }
                return try Money(
                    validating: product.value,
                    currency: currency,
                    roundingMode: roundingMode
                )
            }
            return try convertTo(
                currency,
                usingExchangeRate: multiplier.decimalNumber,
                roundingMode: roundingMode
            )
        }
    }

    /// Divides by a scalar and reports any arithmetic error.
    public func dividingChecked(
        by divisor: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Result<Money, ArithmeticError> {
        arithmeticResult {
            try divide(by: divisor, roundingMode: roundingMode)
        }
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
        requireValidMoneyOperation("division") {
            dividingChecked(by: divisor)
        }
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
        requireValidMoneyOperation("scalar minus money") {
            rhs.checkedScalarOperation(
                lhs.decimalNumber,
                rhs.amount,
                roundingMode: .bankers,
                calculate: NSDecimalSubtract
            )
        }
    }

    public static func * <R: DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        lhs.multiply(rhs)
    }

    public static func * <R: DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        rhs.multiply(lhs)
    }
}

extension Money {
    private typealias DecimalCalculation = (
        UnsafeMutablePointer<Decimal>,
        UnsafePointer<Decimal>,
        UnsafePointer<Decimal>,
        Decimal.RoundingMode
    ) -> Decimal.CalculationError

    private func arithmeticResult(
        _ operation: () throws -> Money
    ) -> Result<Money, ArithmeticError> {
        Result(catching: operation).mapError {
            $0 as? ArithmeticError ?? .unrepresentableResult
        }
    }

    private func checkedScalarOperation(
        _ lhs: Decimal,
        _ rhs: Decimal,
        roundingMode: Decimal.RoundingMode,
        calculate: DecimalCalculation
    ) -> Result<Money, ArithmeticError> {
        guard !lhs.isNaN, !rhs.isNaN else {
            return .failure(.invalidScalar)
        }
        var lhs = lhs
        var rhs = rhs
        var calculated = Decimal()
        let status = calculate(&calculated, &lhs, &rhs, roundingMode)
        guard status == .noError || status == .lossOfPrecision else {
            return .failure(.unrepresentableResult)
        }
        return arithmeticResult {
            let rounded = try result(amount: calculated, roundingMode: roundingMode)
            guard status != .lossOfPrecision || rounded.amount != calculated else {
                throw ArithmeticError.unrepresentableResult
            }
            return rounded
        }
    }
}

private func requireValidMoneyOperation<Value, Failure: Error>(
    _ operation: StaticString,
    _ body: () -> Result<Value, Failure>
) -> Value {
    switch body() {
    case let .success(value):
        return value
    case let .failure(error):
        preconditionFailure("Money \(operation) failed: \(error)")
    }
}
