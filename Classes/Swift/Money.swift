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
    public let amount: NSDecimalNumber
    
    // default rounding handler
    public let roundingHandler: NSDecimalNumberHandler
}

extension Money {
    
    //
    //MARK: - Initialization
    //
    
    public init(amount: String, currency: T, roundingMode: NSDecimalNumber.RoundingMode = .bankers) {
        let actualAmount = Money.decimalNumber(from: amount, for: currency)
        self.init(amount: actualAmount, currency: currency, roundingMode: roundingMode)
    }
    
    public init(currency: T) {
        self.init(amount: .zero, currency: currency)
    }

    public init(amount: NSDecimalNumber, currency: T, roundingMode: NSDecimalNumber.RoundingMode = .bankers) {
        self.currency           = currency
        
        // Since there is no error handling in Swift 1.0 all NSDecimalNumber exceptions are suppressed
        // instead in case of error operations will return NaN
        self.roundingHandler    = NSDecimalNumberHandler(roundingMode: roundingMode,
                                                         scale: Int16(self.currency.exponent),
                                                         raiseOnExactness: false,
                                                         raiseOnOverflow: false,
                                                         raiseOnUnderflow: false,
                                                         raiseOnDivideByZero: false)
        
        // set amount - insure valid value is stored
        let actualAmount        = (amount != .notANumber) ? amount : .zero
        self.amount             =
            actualAmount.rounding(accordingToBehavior: self.roundingHandler)
    }
    
}

extension Money {
    public var isZero: Bool {
        return self.amount.isZero
    }
    
    public var isNegative: Bool {
        return self.amount.isNegative
    }
    
    public var isPositive: Bool {
        return self.amount.isPositive
    }
    
    public var absoluteAmount: NSDecimalNumber {
        return self.isPositive ? self.amount : self.amount.inverted
    }
}

// !!! Works with currencies with decimal subunits
extension Money {
    
    //
    //MARK: - Allocate
    //

    public func allocate(_ n: Int) -> [Money] {
        precondition(n > 0,
                     "Recepients count should be presented as positive number, greater than zero.")
        
        let low         = self.devide(NSDecimalNumber(value: n as Int))
        let high        = low.add(self.oneSubunit)
        
        // create array for all results and init it with nil
        var results     = [Money?](repeating: nil, count: n)
        let reminder    = self.amountInSubunits % n
        
        for (index, _) in results.enumerated() {
            if index < reminder {
                results[index] = high
            } else {
                results[index] = low
            }
        }
        
        return results.map { $0! }
    }
    
    public func allocate(_ ratios: [Int]) -> [Money] {
        let total       = ratios.reduce(0, +)
        var reminder    = self.amountInSubunits
        var results     = Array<Money?>(repeating: nil, count: ratios.count)
        
        precondition(total > 0,
                     "Ratios total should be presented as positive number, greater than zero.")
        
        for (index, item) in ratios.enumerated() {
            let subunits: Int  = self.amountInSubunits * item / total
            results[index]  =
                Money(amount: self.amount(from: subunits), currency: self.currency)
            reminder        -= subunits
        }
        
        for index in 0..<reminder {
            let amount = results[index]!
            results[index] = amount.add(self.oneSubunit)
        }
        
        return results.map { $0! }
    }
    
}

extension Money {
    
    //
    //MARK: - Convert
    //
    
    public func convertTo(_ currency: T, usingExchangeRate multiplier: NSDecimalNumber) -> Money {
        return self.convertTo(currency, usingExchangeRate: multiplier, strategy: NormalConvertStrategy())
    }
    
    // Don't forget to add unit test with your custom strategy
    public func convertTo(_ currency: T, usingExchangeRate multiplier: NSDecimalNumber, strategy: ConvertCurrenciesStrategy) -> Money {
        return strategy.convertTo(self, toCurrency: currency, usingExchangeRate: multiplier)
    }
    
}

extension Money {
    
    //
    //MARK: - Test for same currency
    //
    
    fileprivate func assert(sameCurrencyAs other: Money) {
        precondition(self.currency == other.currency, "Both Money Objects must be of same currency")
    }
    
}

// Subunits is a fraction of the base (ex. cents, stotinka, etc.)
extension Money {
    
    //
    //MARK: - Subunits
    //
    
    public var amountInSubunits: Int {
        let power = Int16(self.currency.exponent)
        return self.amount.multiplying(byPowerOf10: power).intValue
    }
    
    public var oneSubunit: NSDecimalNumber {
        let exp = Int16(-self.currency.exponent)
        return NSDecimalNumber(mantissa: 1, exponent: exp, isNegative: false)
    }
    
    // helper for allocation
    fileprivate func amount(from subunits: Int) -> NSDecimalNumber {
        let exp         = Int16(-self.currency.exponent)
        let mantissa    = UInt64(abs(subunits))
        let isNegative  = (subunits < 0)
        return NSDecimalNumber(mantissa: mantissa, exponent: exp, isNegative: isNegative)
    }
    
}

extension Money {
    
    //
    //MARK: -  Parse Input String Helper
    //
    
    fileprivate static func decimalNumber(from amount: String, for currency: T) -> NSDecimalNumber {
        // check if sting contains formatted value
        if let amountFromString = currency.number(from: amount) {
            return NSDecimalNumber(decimal: amountFromString.decimalValue)
        }
        
        // expects that string contains number value
        return NSDecimalNumber(string: amount)
    }
    
}

extension Money: CustomStringConvertible {
    
    //
    //MARK: - Implement Printable
    //
    
    public var description: String {
        let string = currency.string(from: self.amount)
        return string ?? ""
    }
    
}

extension Money: Hashable {
    
    //
    //MARK: - Implement Hashable
    //
    
    public var hashValue : Int {
        get {
            return self.amount.hashValue ^ self.currency.hashValue
        }
    }
    
}

// value objects are equal if all their fields are equal
extension Money {
    
    //
    //MARK: - Implement Equatable
    //

    public func equals(_ other: Money) -> Bool {
        return ((self.currency == other.currency) &&
            self.amount.compare(other.amount) == .orderedSame)
    }
    
    public static func ==(lhs: Money, rhs: Money) -> Bool {
        return lhs.equals(rhs)
    }

}

extension Money: Comparable {
    
    //
    //MARK: - Implement Comparable
    //
    
    public func compareTo(_ other: Money) -> ComparisonResult {
        self.assert(sameCurrencyAs: other)
        return self.amount.compare(other.amount)
    }
    
    public static func <(lhs: Money, rhs: Money) -> Bool {
        let result = lhs.compareTo(rhs)
        return (result == .orderedDescending)
    }
    
}

extension Money {
    
    //
    //MARK: - Arithmetic Operators
    //
    
    public func add(_ money: Money) -> Money {
        self.assert(sameCurrencyAs: money)
        return self.add(money.amount)
    }

    public func add(_ amount: MoneyRepresentable) -> Money {
        // if the left or the right side amount is nan result will be nan also
        let newAmount =
            self.amount.adding(amount.decimalNumber, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
    
    public func subtract(_ money: Money) -> Money {
        self.assert(sameCurrencyAs: money)
        return self.subtract(money.amount)
    }

    public func subtract(_ amount: MoneyRepresentable) -> Money {
         // if the left or the right side amount is nan result will be nan also
        let newAmount =
            self.amount.subtracting(amount.decimalNumber, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }

    public func multiply(_ multiplier: MoneyRepresentable) -> Money {
        // if the multiplier or the amount is nan result will be nan also
        let newAmount   =
            self.amount.multiplying(by: multiplier.decimalNumber, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
    
    // used when converting between currencies
    public func multiply(_ multiplier: MoneyRepresentable, currency: T) -> Money {
        // if the multiplier or the amount is nan result will be nan also
        let newAmount   =
            self.amount.multiplying(by: multiplier.decimalNumber, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: currency)
    }
    
    // used when allocating
    public func devide(_ divisor: MoneyRepresentable) -> Money {
        precondition(!amount.isZero, "Division by zero")

        let newAmount =
            self.amount.dividing(by: divisor.decimalNumber, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
}

extension Money {
    
    //
    //MARK: - Unary minus operator
    //
    
    public static prefix func -(value: Money) -> Money {
        return value.multiply(NSDecimalNumber.negativeOne)
    }
    
    //
    //MARK: - Add
    //
    
    public static func +<R : MoneyRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }

    public static func +<R : MoneyRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }
    
    //
    //MARK: - Subtract
    //
    
    public static func -<R : MoneyRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }
    
    public static func -<R : MoneyRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }
    
    //
    //MARK: - Multiply
    //
    
    public static func *<R : MoneyRepresentable>(lhs: Money, rhs: R) -> Money {
        return lhs.add(rhs)
    }
    
    public static func *<R : MoneyRepresentable>(lhs: R, rhs: Money) -> Money {
        return rhs.add(lhs)
    }
    
}

//
//MARK: - Converter Strategy pattern Helper
//

public protocol ConvertCurrenciesStrategy {
    // work only with one actual implementation of Currency
    func convertTo<T: Currency>(_ money: Money<T>, toCurrency currency: T, usingExchangeRate multiplier: NSDecimalNumber) -> Money<T>
}

public final class NormalConvertStrategy: ConvertCurrenciesStrategy {
    public func convertTo<T: Currency>(_ money: Money<T>, toCurrency currency: T, usingExchangeRate multiplier: NSDecimalNumber) -> Money<T> {
        precondition(money.currency != currency, "Cannot convert to the same currency")
        precondition(multiplier.isPositive, "Cannot convert using a negative conversion multiplier")
        
        // Uses target currency scale for rounding
        return money.multiply(multiplier, currency: currency)
    }
}

//
//MARK: - NSDecimalNumber Helper Extension
//

public extension NSDecimalNumber {
    public var isZero: Bool {
        return NSDecimalNumber.zero.compare(self) == .orderedSame
    }
    
    public var isNegative: Bool {
        return NSDecimalNumber.zero.compare(self) == .orderedDescending
    }
    
    public var isPositive: Bool {
        return NSDecimalNumber.zero.compare(self) == .orderedAscending
    }
    
    public var inverted: NSDecimalNumber {
        return self.multiplying(by: .negativeOne)
    }
    
    public class var negativeOne: NSDecimalNumber {
        return NSDecimalNumber(mantissa: 1, exponent: 0, isNegative: true)
    }
}

//
//MARK: - Money Representable Helpers
//

// !!! Float80 is not supported by NSDecimalNumber and NSNumber

public protocol MoneyRepresentable {
    var decimalNumber: NSDecimalNumber { get }
}

extension NSDecimalNumber: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return self
    }
}

extension Money: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return self.amount
    }
}

// Integers

extension Int: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension UInt: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension Int8: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension UInt8: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension Int16: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension UInt16: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension Int32: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension UInt32: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension Int64: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension UInt64: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension Float: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}

extension Double: MoneyRepresentable {
    public var decimalNumber: NSDecimalNumber {
        return NSDecimalNumber(value: self)
    }
}
