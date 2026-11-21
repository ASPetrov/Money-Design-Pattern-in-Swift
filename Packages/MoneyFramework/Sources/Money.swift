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

        case invalidScalar
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

    /// Returns nil if the input cannot be parsed or rounded at the currency's scale.
    public init?(
        amount: String,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        do {
            try self.init(
                parsing: amount,
                currency: currency,
                roundingMode: roundingMode
            )
        } catch {
            return nil
        }
    }

    /// Returns nil if the localized input cannot be parsed or rounded at the currency's scale.
    public init?(
        amount: String,
        currency: T,
        locale: Locale,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        do {
            try self.init(
                parsing: amount,
                currency: currency,
                locale: locale,
                roundingMode: roundingMode
            )
        } catch {
            return nil
        }
    }

    /// Parses a monetary string and rounds the amount to the currency's scale.
    /// - Throws: `Amount.ValidationError` for invalid syntax, precision, or currency scale.
    public init(
        parsing amount: String,
        currency: T,
        locale: Locale? = nil,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws {
        let value = try currency.parseAmount(amount, locale: locale)
        try self.init(
            validating: value,
            currency: currency,
            roundingMode: roundingMode
        )
    }

    public init?(currency: T) {
        self.init(amount: .zero, currency: currency)
    }

    /// Returns nil for an invalid decimal amount or a failed currency rounding operation.
    public init?(
        amount: Decimal,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        do {
            let value = try Amount(decimal: amount)
            try self.init(
                validating: value,
                currency: currency,
                roundingMode: roundingMode
            )
        } catch {
            return nil
        }
    }

    /// Returns nil when the amount cannot be rounded at the currency's scale.
    public init?(
        value: Amount,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) {
        do {
            try self.init(
                validating: value,
                currency: currency,
                roundingMode: roundingMode
            )
        } catch {
            return nil
        }
    }

    /// Creates money by rounding the amount to the currency's scale.
    /// - Throws: `Amount.ValidationError` if the scale or rounded result is invalid.
    public init(
        validating value: Amount,
        currency: T,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws {
        let rounded = try value.rounded(
            scale: currency.minorUnits,
            mode: roundingMode
        )
        self.currency = currency
        self.value = rounded
    }
}

extension Money {

    // MARK: - Amount code suger

    public var isZero: Bool {
        amount.isZero
    }

    public var isNegative: Bool {
        amount.isSignMinus
    }

    /// Returns whether the rounded monetary amount is greater than zero.
    public var isPositive: Bool {
        amount > .zero
    }

    public var absoluteAmount: Decimal {
        amount.isSignMinus ? -amount : amount
    }
}

extension Money {

    // MARK: - Convert

    /// Converts to a currency of the same type using target units per source unit.
    /// The rate must be positive and finite. The result rounds to the target currency's scale using `.bankers` by default.
    /// - Throws: `ConvertCurrenciesStrategyError` for an invalid rate, the same currency,
    ///   a conflicting scale, or an unrepresentable result.
    public func convertTo(
        _ currency: T,
        usingExchangeRate multiplier: Decimal,
        roundingMode: Decimal.RoundingMode = .bankers
    ) throws -> Money {
        try NormalConvertStrategy.convert(
            self,
            to: currency,
            rate: multiplier,
            roundingMode: roundingMode
        )
    }

    /// Converts to a different currency type using target units per source unit.
    /// The rate must be positive and finite. The result rounds to the target currency's scale using `.bankers` by default.
    /// - Throws: `ConvertCurrenciesStrategyError` for an invalid rate, the same currency,
    ///   a conflicting scale, or an unrepresentable result.
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

extension Money {

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
            let result = Money(
                amount: amount,
                currency: currency,
                roundingMode: roundingMode
            )
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
        requireValidMoneyOperation("minor-unit count") { try checkedMinorUnits() }
    }

    /// Returns the signed count of the currency's smallest units, such as cents for USD.
    /// - Throws: `Amount.ValidationError` if the scale is invalid or the count is fractional
    ///   or outside the range of `Int`.
    public func checkedMinorUnits() throws -> Int {
        try value.minorUnits(scale: currency.minorUnits)
    }

    public var oneMinorUnit: Decimal {
        amount(from: 1)
    }

    public func amount(from subunits: Int) -> Decimal {
        requireValidMoneyOperation("major-unit amount") {
            try Amount(
                minorUnits: subunits,
                scale: currency.minorUnits
            ).decimalValue
        }
    }
}

extension Money: CustomStringConvertible {

    /// Formats the amount or returns a diagnostic with its decimal value and currency code.
    public var description: String {
        formatted() ?? "\(amount) \(currency.code) [formatting failed]"
    }

    /// Formats the amount for the supplied locale, or returns `nil` if formatting fails.
    /// With no locale, ISO currencies use their currency locale and custom currencies use the current locale.
    public func formatted(locale: Locale? = nil) -> String? {
        currency.string(
            from: NSDecimalNumber(decimal: amount),
            locale: locale
        )
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

extension Money: Sendable where T: Sendable { }

extension Money: Comparable {

    /// Requires matching currency identifiers and scales. Use `compare(to:)` for unvalidated currencies.
    public static func < (lhs: Money, rhs: Money) -> Bool {
        requireValidMoneyOperation("comparison") {
            try lhs.compare(to: rhs) == .orderedAscending
        }
    }

    public func compare<U: Currency>(
        to other: Money<U>
    ) throws -> ComparisonResult {
        try checkCompatibility(with: other)
        var lhs = amount
        var rhs = other.amount
        return NSDecimalCompare(&lhs, &rhs)
    }
}

func requireValidMoneyOperation<Value>(
    _ operation: StaticString, _ body: () throws -> Value
) -> Value {
    do {
        return try body()
    } catch {
        preconditionFailure("Money \(operation) failed: \(error)")
    }
}
