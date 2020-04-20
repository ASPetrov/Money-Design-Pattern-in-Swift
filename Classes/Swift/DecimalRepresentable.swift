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
}

extension Decimal: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return self
    }
}

extension Money: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return amount
    }
}

// Integers

extension Int: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension UInt: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension Int8: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension UInt8: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension Int16: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension UInt16: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension Int32: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension UInt32: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension Int64: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

extension UInt64: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

//extension Float: MoneyRepresentable {
//    public var decimalNumber: Decimal {
//        return Decimal(self)
//    }
//}

extension Double: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(self)
    }
}

//extension Float80: MoneyRepresentable {
//    public var decimalNumber: Decimal {
//        return Decimal(self)
//    }
//}

extension String: DecimalRepresentable {
    public var decimalNumber: Decimal {
        return Decimal(string: self) ?? .nan
    }
}
