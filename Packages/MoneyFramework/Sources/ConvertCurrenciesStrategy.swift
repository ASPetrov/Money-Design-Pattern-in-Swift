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
        var amount = money.amount
        var rate = rate
        var product = Decimal()
        let status = NSDecimalMultiply(&product, &amount, &rate, roundingMode)
        guard status == .noError || status == .lossOfPrecision else {
            throw ConvertCurrenciesStrategyError.unrepresentableResult
        }
        guard
            let result = Money(
                amount: product,
                currency: currency,
                roundingMode: roundingMode
            ),
            status != .lossOfPrecision || result.amount != product
        else {
            throw ConvertCurrenciesStrategyError.unrepresentableResult
        }
        return result
    }

    private static func validateConversion<T: Currency, U: Currency>(
        from source: T,
        to currency: U,
        rate: Decimal
    ) throws {
        if source.identifier == currency.identifier {
            guard source.minorUnits == currency.minorUnits else {
                throw ConvertCurrenciesStrategyError.incompatibleCurrencyScale
            }

            throw ConvertCurrenciesStrategyError.sameCurrency
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
