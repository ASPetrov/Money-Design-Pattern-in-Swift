//
//  Money.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

// Swift implementation of Martin Fowler Money Design Pattern
// Example of typical calculations with monetary values, implemented with NSDecimalNumber.

struct Money {
    
    //
    // MARK: Public
    //
    
    // !!! value objects should be entirely immutable
    
    private(set) var currency: Currency
    private(set) var amount: NSDecimalNumber
    
    // default rounding handler
    private(set) var roundingHandler: NSDecimalNumberHandler
    
    func isZero() -> Bool {
        return self.amount.isZero()
    }

    func isNegative() -> Bool {
        return self.amount.isNegative()
    }

    func isPositive() -> Bool {
        return self.amount.isPositive()
    }
    
    func absoluteAmount() -> NSDecimalNumber {
        return self.isPositive() ? self.amount : self.amount.inverted()
    }
    
    // Subunits is a fraction of the base (ex. cents, stotinka, etc.)

    func amountInSubunits() -> Int {
        let power = Int16(self.currency.maximumFractionDigits)
        return self.amount.decimalNumberByMultiplyingByPowerOf10(power).integerValue
    }

    func oneSubunit() -> NSDecimalNumber {
        let exp = Int16(-self.currency.maximumFractionDigits)
        return NSDecimalNumber(mantissa: 1, exponent: exp, isNegative: false)
    }
    
    //
    // Allocate
    //
    
    // !!! Works with currencies with decimal subunits
    
    func allocate(n: Int) -> [Money] {
        precondition(n > 0,
            "Recepients count should be presented as positive number, greater than zero.")

        let low         = self.devide(NSDecimalNumber(integer: n))
        let high        = low.add(self.oneSubunit())
        
        // create array for all results and init it with nil
        var results     = [Money?](count: n, repeatedValue: nil)        
        let reminder    = self.amountInSubunits() % n
        
        for (index, _) in results.enumerate() {
            if index < reminder {
                results[index] = high
            } else {
                results[index] = low
            }
        }

        return results.map { $0! }
    }
    
    func allocate(ratios: [Int]) -> [Money] {
        let total       = ratios.reduce(0, combine: +)
        var reminder    = self.amountInSubunits()
        var results     = [Money?](count: ratios.count, repeatedValue: nil)
        
        precondition(total > 0,
            "Ratios total should be presented as positive number, greater than zero.")
        
        for (index, item) in ratios.enumerate() {
            let cents: Int  = self.amountInSubunits() * item / total
            results[index]  =
                Money(amount: self.amountFromSubunits(cents), currency: self.currency)
            reminder        -= cents
        }

        for var index = 0; index < reminder; index++ {
            results[index]!.add(self.oneSubunit())
        }

        return results.map { $0! }
    }
    
    //
    // Convert
    //
    
    func convertTo(currency: Currency, usingExchangeRate multiplier: NSDecimalNumber) -> Money {
        return self.convertTo(currency, usingExchangeRate: multiplier, strategy: NormalConvertStrategy())
    }

    // Don't forget to add unit test with your custom strategy
    func convertTo(currency: Currency, usingExchangeRate multiplier: NSDecimalNumber, strategy: ConvertCurrenciesStrategy) -> Money {
        return strategy.convertTo(self, toCurrency: currency, usingExchangeRate: multiplier)
    }
    
    //
    // MARK: Initialization
    //
    
    init(amount: NSDecimalNumber = NSDecimalNumber.zero(), currency: Currency = Money.defaultCurrency()) {
        self.currency           = currency
        
        // Since there is no error handling in Swift 1.0 all NSDecimalNumber exceptions are suppressed
        // instead in case of error operations will return NaN
        self.roundingHandler    = NSDecimalNumberHandler(roundingMode: .RoundBankers,
            scale: Int16(self.currency.maximumFractionDigits), raiseOnExactness: false,
            raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        
        // set amount - insure valid value is stored
        let actualAmount        =
            (amount != NSDecimalNumber.notANumber()) ? amount : NSDecimalNumber.zero()
        self.amount             =
            actualAmount.decimalNumberByRoundingAccordingToBehavior(self.roundingHandler)
    }
    
    init(amount: String, currency: Currency = Money.defaultCurrency()) {
        let actualAmount = Money.decimalNumberFromAmountString(amount, currency: currency)
        self.init(amount: actualAmount, currency: currency)
    }
    
    //
    // MARK: Private
    //
    
    private func assertSameCurrencyAs(other: Money) {
        precondition(self.currency == other.currency, "Both Money Objects must be of same currency")
    }

    private func amountFromSubunits(cents: Int) -> NSDecimalNumber {
        let exp         = Int16(-self.currency.maximumFractionDigits)
        let mantissa    = UInt64(abs(cents))
        let isNegative  = (cents < 0)
        return NSDecimalNumber(mantissa: mantissa, exponent: exp, isNegative: isNegative)
    }
}

//
// MARK: Class functions extension
//

extension Money {
    
    //
    // MARK: Public
    //
    
    // Default Currency is US Dollars(USD)
    static func defaultCurrency() -> Currency {
        return Currency.currencyForLocaleIdentifier(localeIdentifier: "en_US")!
    }
    
    //
    // MARK: Private
    //
    
    // Parse Input String Helper
    private static func decimalNumberFromAmountString(amount: String, currency: Currency) -> NSDecimalNumber {
        // asume that sting contains formatted value
        if let amountFromString = currency.formatter.numberFromString(amount) {
            return NSDecimalNumber(decimal: amountFromString.decimalValue)
        }
        
        // expect that string contains number value
        return NSDecimalNumber(string: amount)
    }
}

//
// MARK: Implement Printable
//

extension Money: CustomStringConvertible {
    var description: String {
        let formatter   = currency.formatter
        let string      = formatter.stringFromNumber(self.amount)
        return string ?? ""
    }
}

//
// MARK: Implement Hashable
//

extension Money: Hashable {
    var hashValue : Int {
        get {
            return self.amount.hashValue ^ self.currency.hashValue
        }
    }
}

//
// MARK: Implement Equatable
//

extension Money {
    // value objects are equal if all their fields are equal
    func equals(other: Money) -> Bool {
        return ((self.currency == other.currency) &&
            self.amount.compare(other.amount) == .OrderedSame)
    }
}

func ==(lhs: Money, rhs: Money) -> Bool {
    return lhs.equals(rhs)
}

//
// MARK: Implement Comparable
//

extension Money: Comparable {
    func compareTo(other: Money) -> NSComparisonResult {
        self.assertSameCurrencyAs(other)
        return self.amount.compare(other.amount)
    }
}

func <=(lhs: Money, rhs: Money) -> Bool {
    let result = lhs.compareTo(rhs)
    return (result == .OrderedDescending || result == .OrderedSame)
}

func >=(lhs: Money, rhs: Money) -> Bool {
    let result = lhs.compareTo(rhs)
    return (result == .OrderedAscending || result == .OrderedSame)
}

func >(lhs: Money, rhs: Money) -> Bool {
    let result = lhs.compareTo(rhs)
    return (result == .OrderedAscending)
}

func <(lhs: Money, rhs: Money) -> Bool {
    let result = lhs.compareTo(rhs)
    return (result == .OrderedDescending)
}

//
// MARK: Arithmetic Operators
//

extension Money {
    
    //
    // MARK: DRY Helpers
    //
    
    //
    // Add Amount
    //
    
    func add(money: Money) -> Money {
        self.assertSameCurrencyAs(money)
        return self.add(money.amount)
    }

    func add(amount: NSDecimalNumber) -> Money {
        // if the left or the right side amount is nan result will be nan also
        let newAmount =
            self.amount.decimalNumberByAdding(amount, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
    
    //
    // Subtract Amount
    //

    func subtract(money: Money) -> Money {
        self.assertSameCurrencyAs(money)
        return self.subtract(money.amount)
    }

    func subtract(amount: NSDecimalNumber) -> Money {
         // if the left or the right side amount is nan result will be nan also
        let newAmount =
            self.amount.decimalNumberBySubtracting(amount, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
    
    //
    // Multiply Amount
    //

    func multiply(multiplier: NSDecimalNumber) -> Money {
        // if the multiplier or the amount is nan result will be nan also
        let newAmount   =
            self.amount.decimalNumberByMultiplyingBy(multiplier, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
    
    private func multiply(multiplier: NSDecimalNumber, currency: Currency) -> Money {
        // if the multiplier or the amount is nan result will be nan also
        let newAmount   =
            self.amount.decimalNumberByMultiplyingBy(multiplier, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: currency)
    }
    
    //
    // Devide Amount
    //
    
    private func devide(divisor: NSDecimalNumber) -> Money {
        precondition(!amount.isZero(), "Division by zero")

        let newAmount =
            self.amount.decimalNumberByDividingBy(divisor, withBehavior: self.roundingHandler)
        
        return Money(amount: newAmount, currency: self.currency)
    }
}

// !!! Float80 is not supported by NSDecimalNumber and NSNumber
// ??? Use Generics like <T: IntegerType, FloatingPointType> to reduce functions

//
// Unary minus operator
//

prefix func -(value: Money) -> Money {
    return value.multiply(NSDecimalNumber.negativeOne())
}

//
// Add
//

func +(lhs: Money, rhs: Money) -> Money {
    return lhs.add(rhs)
}

func +(lhs: Money, rhs: Int) -> Money {
    return lhs.add(NSDecimalNumber(integer: rhs))
}

func +(lhs: Int, rhs: Money) -> Money {
    return rhs.add(NSDecimalNumber(integer: lhs))
}

func +(lhs: Money, rhs: Float) -> Money {
    return lhs.add(NSDecimalNumber(float: rhs))
}

func +(lhs: Float, rhs: Money) -> Money {
    return rhs.add(NSDecimalNumber(float: lhs))
}

func +(lhs: Money, rhs: Double) -> Money {
    return lhs.add(NSDecimalNumber(double: rhs))
}

func +(lhs: Double, rhs: Money) -> Money {
    return rhs.add(NSDecimalNumber(double: lhs))
}

func +(lhs: Money, rhs: NSDecimalNumber) -> Money {
    return lhs.add(rhs)
}

func +(lhs: NSDecimalNumber, rhs: Money) -> Money {
    return rhs.add(lhs)
}

func +(lhs: Money, rhs: NSDecimal) -> Money {
    return lhs.add(NSDecimalNumber(decimal: rhs))
}

func +(lhs: NSDecimal, rhs: Money) -> Money {
    return rhs.add(NSDecimalNumber(decimal: lhs))
}

//
// Subtract
//

func -(lhs: Money, rhs: Money) -> Money {
    return lhs.subtract(rhs)
}

func -(lhs: Money, rhs: Int) -> Money {
    return lhs.subtract(NSDecimalNumber(integer: rhs))
}

func -(lhs: Int, rhs: Money) -> Money {
    return rhs.subtract(NSDecimalNumber(integer: lhs))
}

func -(lhs: Money, rhs: Float) -> Money {
    return lhs.subtract(NSDecimalNumber(float: rhs))
}

func -(lhs: Float, rhs: Money) -> Money {
    return rhs.subtract(NSDecimalNumber(float: lhs))
}

func -(lhs: Money, rhs: Double) -> Money {
    return lhs.subtract(NSDecimalNumber(double: rhs))
}

func -(lhs: Double, rhs: Money) -> Money {
    return rhs.subtract(NSDecimalNumber(double: lhs))
}

func -(lhs: Money, rhs: NSDecimalNumber) -> Money {
    return lhs.subtract(rhs)
}

func -(lhs: NSDecimalNumber, rhs: Money) -> Money {
    return rhs.subtract(lhs)
}

func -(lhs: Money, rhs: NSDecimal) -> Money {
    return lhs.subtract(NSDecimalNumber(decimal: rhs))
}

func -(lhs: NSDecimal, rhs: Money) -> Money {
    return rhs.subtract(NSDecimalNumber(decimal: lhs))
}

//
// Multiply
//

func *(lhs: Money, rhs: Int) -> Money {
    return lhs.multiply(NSDecimalNumber(integer: rhs))
}

func *(lhs: Int, rhs: Money) -> Money {
    return rhs.multiply(NSDecimalNumber(integer: lhs))
}

func *(lhs: Money, rhs: Float) -> Money {
    return lhs.multiply(NSDecimalNumber(float: rhs))
}

func *(lhs: Float, rhs: Money) -> Money {
    return rhs.multiply(NSDecimalNumber(float: lhs))
}

func *(lhs: Money, rhs: Double) -> Money {
    return lhs.multiply(NSDecimalNumber(double: rhs))
}

func *(lhs: Double, rhs: Money) -> Money {
    return rhs.multiply(NSDecimalNumber(double: lhs))
}

func *(lhs: Money, rhs: NSDecimalNumber) -> Money {
    return lhs.multiply(rhs)
}

func *(lhs: NSDecimalNumber, rhs: Money) -> Money {
    return rhs.multiply(lhs)
}

func *(lhs: Money, rhs: NSDecimal) -> Money {
    return lhs.multiply(NSDecimalNumber(decimal: rhs))
}

func *(lhs: NSDecimal, rhs: Money) -> Money {
    return rhs.multiply(NSDecimalNumber(decimal: lhs))
}

//
// MARK: Converter Strategy pattern Helper
//

protocol ConvertCurrenciesStrategy {
    func convertTo(money: Money, toCurrency currency: Currency, usingExchangeRate multiplier: NSDecimalNumber) -> Money
}

class NormalConvertStrategy: ConvertCurrenciesStrategy {
    func convertTo(money: Money, toCurrency currency: Currency, usingExchangeRate multiplier: NSDecimalNumber) -> Money {
        precondition(money.currency != currency, "Cannot convert to the same currency")
        precondition(multiplier.isPositive(), "Cannot convert using a negative conversion multiplier")
        
        // Uses target currency scale for rounding
        return money.multiply(multiplier, currency: currency)
    }
}

//
// MARK: NSDecimalNumber Helper Extension
//

extension NSDecimalNumber {
    func isZero() -> Bool {
        return NSDecimalNumber.zero().compare(self) == .OrderedSame
    }
    
    func isNegative() -> Bool {
        return NSDecimalNumber.zero().compare(self) == .OrderedDescending
    }
    
    func isPositive() -> Bool {
        return NSDecimalNumber.zero().compare(self) == .OrderedAscending
    }
    
    func inverted() -> NSDecimalNumber {
        return self.decimalNumberByMultiplyingBy(NSDecimalNumber.negativeOne())
    }
    
    class func negativeOne() -> NSDecimalNumber {
        return NSDecimalNumber(mantissa: 1, exponent: 0, isNegative: true)
    }
}