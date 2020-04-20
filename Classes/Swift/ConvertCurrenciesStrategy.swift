//
//  ConvertCurrenciesStrategy.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 18.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

public protocol ConvertCurrenciesStrategy {
    // work only with one actual implementation of Currency
    func convertTo<T>(_ money: Money<T>, toCurrency currency: T, usingExchangeRate multiplier: Decimal) throws -> Money<T>
}

public final class NormalConvertStrategy: ConvertCurrenciesStrategy {
    public func convertTo<T>(_ money: Money<T>, toCurrency currency: T, usingExchangeRate multiplier: Decimal) throws -> Money<T> {
        guard money.currency != currency else {
            throw ConvertCurrenciesStrategyError.negativeExchangeRate
        }
        guard !multiplier.isSignMinus else {
            throw ConvertCurrenciesStrategyError.negativeExchangeRate
        }
        precondition(!multiplier.isSignMinus, "")

        // Uses target currency scale for rounding
        return money.multiply(multiplier, currency: currency)
    }
}

enum ConvertCurrenciesStrategyError: Error {
    /// Cannot convert to the same currency
    case sameCurrency
    /// Cannot convert using a negative conversion multiplier
    case negativeExchangeRate
    
}
