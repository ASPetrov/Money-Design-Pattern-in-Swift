//
//  Decimal+Helpers.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 18.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

extension Decimal {
    ///Parse Input String Helper
    static func decimal<T: Currency>(from amount: String, for currency: T) -> Decimal? {
        // check if sting contains formatted value
        if let numberValue = currency.number(from: amount) {
            return numberValue.decimalValue
        }

        // check if string contains number value
        guard let decimalValue = Decimal(string: amount) else {
            return nil
        }

        return decimalValue
    }
}

extension Decimal {
    func rounded(_ scale: Int, _ roundingMode: Decimal.RoundingMode) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }
}

extension Decimal {
    var intValue: Int {
        return NSDecimalNumber(decimal: self).intValue
    }

    var numberValue: NSNumber {
        return self as NSDecimalNumber
    }
}

extension Decimal {
    static func create(mantissa: UInt64, exponent: Int16, isNegative flag: Bool) -> Decimal {
        return NSDecimalNumber(mantissa: mantissa, exponent: exponent, isNegative: flag) as Decimal
    }
}

extension Decimal {
    static var negativeOne: Decimal {
        return Decimal(-1)
    }
}
