//
//  ConvertCurrenciesStrategy.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 18.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

public protocol ConvertCurrenciesStrategy {

    func convertTo<T: Currency>(
        _ money: Money<T>,
        toCurrency currency: T,
        usingExchangeRate multiplier: Decimal
    ) throws -> Money<T>
}

public final class NormalConvertStrategy: ConvertCurrenciesStrategy {

    public init() {
        // no-op
    }

    public func convertTo<T: Currency>(
        _ money: Money<T>,
        toCurrency currency: T,
        usingExchangeRate multiplier: Decimal
    ) throws -> Money<T> {
        try Self.convert(
            money,
            to: currency,
            rate: multiplier,
            roundingMode: .bankers
        )
    }

    static func convert<T: Currency, U: Currency>(
        _ money: Money<T>,
        to currency: U,
        rate: Decimal,
        roundingMode: Decimal.RoundingMode
    ) throws -> Money<U> {
        try validateConversion(from: money.currency, to: currency, rate: rate)
        do {
            let rounded = try MonetaryRounding.calculate(
                money.amount, rate, operation: .multiply, scale: currency.minorUnits, mode: roundingMode
            )
            return try Money(validating: Amount(decimal: rounded), currency: currency, roundingMode: roundingMode)
        } catch {
            throw ConvertCurrenciesStrategyError.unrepresentableResult
        }
    }

    private static func validateConversion<T: Currency, U: Currency>(
        from source: T,
        to currency: U,
        rate: Decimal
    ) throws {
        guard source.identifier != currency.identifier else {
            throw source.minorUnits == currency.minorUnits
                ? ConvertCurrenciesStrategyError.sameCurrency
                : ConvertCurrenciesStrategyError.incompatibleCurrencyScale
        }
        guard !rate.isNaN, rate > .zero else {
            throw ConvertCurrenciesStrategyError.invalidExchangeRate
        }
    }
}

public enum ConvertCurrenciesStrategyError: Error, Equatable {

    case sameCurrency
    case incompatibleCurrencyScale
    case invalidExchangeRate
    case unrepresentableResult
}
