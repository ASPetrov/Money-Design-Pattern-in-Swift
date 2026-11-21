//
//  DecimalRepresentable.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 18.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

public protocol DecimalRepresentable {

    var decimalNumber: Decimal { get }

    /// Returns the converted scalar or the reason it cannot be converted.
    var decimalConversion: Result<Decimal, any Error> { get }
}

extension DecimalRepresentable {

    public var decimalConversion: Result<Decimal, any Error> {
        let decimal = decimalNumber
        return decimal.isNaN
            ? .failure(Amount.ValidationError.unrepresentableValue)
            : .success(decimal)
    }
}

extension Decimal: DecimalRepresentable {

    public var decimalNumber: Decimal {
        self
    }
}

extension Amount: DecimalRepresentable {

    public var decimalNumber: Decimal {
        decimalValue
    }
}

extension Money {

    public var decimalNumber: Decimal {
        amount
    }
}

// Integers

extension Int: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension UInt: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension Int8: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension UInt8: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension Int16: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension UInt16: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension Int32: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension UInt32: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension Int64: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension UInt64: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }
}

extension Float: DecimalRepresentable {

    /// Widens the stored binary value to Double before conversion. Nonfinite values return Decimal.nan.
    public var decimalNumber: Decimal {
        isFinite ? Double(self).decimalNumber : .nan
    }

    public var decimalConversion: Result<Decimal, any Error> {
        Double(self).decimalConversion
    }
}

extension Double: DecimalRepresentable {

    public var decimalNumber: Decimal {
        Decimal(self)
    }

    public var decimalConversion: Result<Decimal, any Error> {
        guard isFinite else {
            return .failure(Amount.ValidationError.unrepresentableValue)
        }
        return decimalNumber.decimalConversion
    }
}

extension String: DecimalRepresentable {

    /// Requires an exact, locale-independent decimal string. Use decimalConversion to inspect a failure.
    public var decimalNumber: Decimal {
        MoneyOperation.require("decimal string conversion") {
            decimalConversion
        }
    }

    public var decimalConversion: Result<Decimal, any Error> {
        Result { try Amount(decimalString: self).decimalValue }
    }
}
