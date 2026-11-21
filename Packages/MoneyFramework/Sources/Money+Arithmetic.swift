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
        MoneyOperation.require("addition") {
            addingChecked(money)
        }
    }

    /// Adds compatible monetary values and reports any arithmetic error.
    public func addingChecked<U: Currency>(
        _ money: Money<U>
    ) -> Result<Money, ArithmeticError> {
        arithmeticResult {
            try adding(money)
        }
    }

    public func adding<U: Currency>(_ money: Money<U>) throws -> Money {
        try checkCompatibility(with: money)
        return try roundedOperation(amount, money.amount, roundingMode: .bankers, operation: .add)
    }

    public func add(_ newAmount: DecimalRepresentable, roundingMode: Decimal.RoundingMode = .bankers) -> Money {
        MoneyOperation.require("scalar addition") {
            addingChecked(newAmount, roundingMode: roundingMode)
        }
    }

    /// Adds a scalar in major currency units and reports any arithmetic error.
    public func addingChecked(
        _ scalar: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Result<Money, ArithmeticError> {
        withDecimalScalar(scalar) { decimal in
            checkedScalarOperation(
                amount, decimal,
                roundingMode: roundingMode,
                operation: .add
            )
        }
    }

    /// Requires compatible currencies and a representable result.
    public func subtract(_ money: Money) -> Money {
        MoneyOperation.require("subtraction") {
            subtractingChecked(money)
        }
    }

    /// Subtracts compatible monetary values and reports any arithmetic error.
    public func subtractingChecked<U: Currency>(
        _ money: Money<U>
    ) -> Result<Money, ArithmeticError> {
        arithmeticResult {
            try subtracting(money)
        }
    }

    public func subtracting<U: Currency>(_ money: Money<U>) throws -> Money {
        try checkCompatibility(with: money)
        return try roundedOperation(amount, money.amount, roundingMode: .bankers, operation: .subtract)
    }

    public func subtract(
        _ newAmount: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        MoneyOperation.require("scalar subtraction") {
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
        withDecimalScalar(scalar) { decimal in
            checkedScalarOperation(
                amount, decimal,
                roundingMode: roundingMode,
                operation: .subtract
            )
        }
    }

    public func multiply(
        _ multiplier: DecimalRepresentable,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        MoneyOperation.require("multiplication") {
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
        withDecimalScalar(multiplier) { decimal in
            checkedScalarOperation(
                amount, decimal,
                roundingMode: roundingMode,
                operation: .multiply
            )
        }
    }

    public func multiply(
        _ multiplier: DecimalRepresentable,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) -> Money {
        MoneyOperation.require("multiplication with target currency") {
            if
                self.currency.identifier == currency.identifier
                && self.currency.minorUnits == currency.minorUnits {
                return try multiplyInCurrency(
                    multiplier,
                    currency: currency,
                    roundingMode: roundingMode
                )
            }
            guard case let .success(rate) = multiplier.decimalConversion else {
                throw ArithmeticError.invalidScalar
            }
            return try convertTo(
                currency,
                usingExchangeRate: rate,
                roundingMode: roundingMode
            )
        }
    }

    private func multiplyInCurrency(
        _ multiplier: DecimalRepresentable,
        currency: T,
        roundingMode: Decimal.RoundingMode
    ) throws -> Money {
        switch multiplyingChecked(by: multiplier, roundingMode: roundingMode) {
        case let .success(product):
            return try Money(
                validating: product.value,
                currency: currency,
                roundingMode: roundingMode
            )
        case let .failure(error):
            throw error
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
        guard
            case let .success(decimal) = divisor.decimalConversion,
            !decimal.isNaN
        else {
            throw ArithmeticError.invalidDivisor
        }
        guard !decimal.isZero else {
            throw ArithmeticError.divisionByZero
        }
        return try roundedOperation(
            amount, decimal,
            roundingMode: roundingMode,
            operation: .divide
        )
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
        MoneyOperation.require("scalar minus money") {
            rhs.withDecimalScalar(lhs) { decimal in
                rhs.checkedScalarOperation(
                    decimal,
                    rhs.amount,
                    roundingMode: .bankers,
                    operation: .subtract
                )
            }
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

    private func arithmeticResult(
        _ operation: () throws -> Money
    ) -> Result<Money, ArithmeticError> {
        Result(catching: operation).mapError {
            $0 as? ArithmeticError ?? .unrepresentableResult
        }
    }

    private func withDecimalScalar(
        _ scalar: DecimalRepresentable,
        _ operation: (Decimal) -> Result<Money, ArithmeticError>
    ) -> Result<Money, ArithmeticError> {
        guard case let .success(decimal) = scalar.decimalConversion else {
            return .failure(.invalidScalar)
        }
        return operation(decimal)
    }

    private func checkedScalarOperation(
        _ lhs: Decimal,
        _ rhs: Decimal,
        roundingMode: Decimal.RoundingMode,
        operation: MonetaryRounding.Operation
    ) -> Result<Money, ArithmeticError> {
        guard !lhs.isNaN, !rhs.isNaN else {
            return .failure(.invalidScalar)
        }
        return arithmeticResult {
            try roundedOperation(
                lhs,
                rhs,
                roundingMode: roundingMode,
                operation: operation
            )
        }
    }

    private func roundedOperation(
        _ lhs: Decimal,
        _ rhs: Decimal,
        roundingMode: Decimal.RoundingMode,
        operation: MonetaryRounding.Operation
    ) throws -> Money {
        do {
            let rounded = try MonetaryRounding.calculate(
                lhs,
                rhs,
                operation: operation,
                scale: currency.minorUnits,
                mode: roundingMode
            )
            return try result(amount: rounded, roundingMode: roundingMode)
        } catch {
            throw ArithmeticError.unrepresentableResult
        }
    }
}
