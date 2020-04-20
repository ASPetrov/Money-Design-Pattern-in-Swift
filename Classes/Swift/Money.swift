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
    public let amount: Decimal
    
    // default rounding handler
    public let roundingMode: Decimal.RoundingMode

    // MARK: - Initialization
    
    public init?(amount: String, currency: T, roundingMode: Decimal.RoundingMode = .bankers) {
        let actualAmount = Decimal.decimal(from: amount, for: currency) ?? Decimal.nan
        self.init(amount: actualAmount, currency: currency, roundingMode: roundingMode)
    }
    
    public init?(currency: T) {
        self.init(amount: .zero, currency: currency)
    }

    public init?(amount: Decimal, currency: T, roundingMode: Decimal.RoundingMode = .bankers) {
        guard !amount.isNaN else {
            return nil
        }
        self.currency = currency
        self.roundingMode = roundingMode
        self.amount = amount.rounded(currency.minorUnits, roundingMode)
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

// NOTE: Works with currencies with decimal subunits
extension Money {

    // MARK: - Allocate

    public func allocate(_ n: Int) -> [Money] {
        precondition(n > 0, "Recepients count should be presented as positive number, greater than zero.")
        
        let low = devide(Decimal(n))
        let high = low.add(oneMinorUnit)
        
        // create array for all results and init it with nil
        var results = [Money?](repeating: nil, count: n)
        let reminder = amountInMinorUnits % n
        
        for (index, _) in results.enumerated() {
            if index < reminder {
                results[index] = high
            } else {
                results[index] = low
            }
        }
        
        return results.compactMap { $0 }
    }
    
    public func allocate(_ ratios: [Int]) -> [Money] {
        let total = ratios.reduce(0, +)
        precondition(total > 0, "Ratios total should be presented as positive number, greater than zero.")

        var reminder = amountInMinorUnits
        var results = [Money?](repeating: nil, count: ratios.count)
        
        for (index, item) in ratios.enumerated() {
            let minorUnits: Int = amountInMinorUnits * item / total
            results[index] = Money(amount: amount(from: minorUnits), currency: currency)
            reminder -= minorUnits
        }
        
        for index in 0..<reminder {
            let amount = results[index]!
            results[index] = amount.add(oneMinorUnit)
        }
        
        return results.compactMap { $0 }
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
    public func convertTo(_ currency: T, usingExchangeRate multiplier: Decimal, strategy: ConvertCurrenciesStrategy) throws -> Money {
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
    
    public var amountInMinorUnits: Int {
        return (amount * pow(10, currency.minorUnits)).intValue
    }
    
    public var oneMinorUnit: Decimal {
        let exponent = Int16(-currency.minorUnits)
        return Decimal.create(mantissa: 1, exponent: exponent, isNegative: false)
    }
    
    // helper for allocation
    public func amount(from subunits: Int) -> Decimal {
        let exponent = Int16(-currency.minorUnits)
        let mantissa = UInt64(abs(subunits))
        let isNegative = (subunits < 0)
        return Decimal.create(mantissa: mantissa, exponent: exponent, isNegative: isNegative)
    }
    
}

extension Money: CustomStringConvertible {
    public var description: String {
        let string = currency.string(from: amount.numberValue)
        return string ?? ""
    }
}

// NOTE: value objects are equal if all their fields are equal
extension Money: Equatable {
    public func equals(_ other: Money) -> Bool {
        return currency == other.currency && amount == other.amount
    }
    
    public static func ==(lhs: Money, rhs: Money) -> Bool {
        return lhs.equals(rhs)
    }
}

extension Money: Comparable {
    public static func <(lhs: Money, rhs: Money) -> Bool {
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
        let result = (amount + newAmount.decimalNumber).rounded(currency.minorUnits, roundingMode)
        return Money(amount: result, currency: currency)!
    }
    
    public func subtract(_ money: Money) -> Money {
        self.assert(sameCurrencyAs: money)
        return self.subtract(money.amount)
    }

    public func subtract(_ newAmount: DecimalRepresentable) -> Money {
        let result = (amount - newAmount.decimalNumber).rounded(currency.minorUnits, roundingMode)
        return Money(amount: result, currency: self.currency)!
    }

    public func multiply(_ multiplier: DecimalRepresentable) -> Money {
        let result = (amount * multiplier.decimalNumber).rounded(currency.minorUnits, roundingMode)
        return Money(amount: result, currency: self.currency)!
    }
    
    // NOTE: used when converting between currencies
    public func multiply(_ multiplier: DecimalRepresentable, currency: T) -> Money {
        let result = (amount * multiplier.decimalNumber).rounded(currency.minorUnits, roundingMode)
        return Money(amount: result, currency: currency)!
    }
    
    // NOTE: used when allocating
    public func devide(_ divisor: DecimalRepresentable) -> Money {
        precondition(!amount.isZero, "Division by zero")
        let newAmount = (amount / divisor.decimalNumber).rounded(currency.minorUnits, roundingMode)
        return Money(amount: newAmount, currency: self.currency)!
    }
}

extension Money {
    public static prefix func -(value: Money) -> Money {
        return value.multiply(Decimal.negativeOne)
    }

    public static func +<R : DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }

    public static func +<R : DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }

    public static func -<R : DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }
    
    public static func -<R : DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }

    public static func *<R : DecimalRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }
    
    public static func *<R : DecimalRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }
}
