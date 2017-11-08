//
//  Currency.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

public protocol Currency: CurrencyFormatter, CustomStringConvertible, Hashable {
    // Currency code
    var code: String { get }
    // Currency symbol
    var symbol: String { get }
    // Currency fraction digits
    var exponent: Int { get }
    // Currency Decimal Separator - character between the whole and fraction amounts
    var separator: String { get }
    // Currency Grouping Separator - character between each thousands place
    var delimiter: String? { get }
}

extension Currency {
    
    //
    //MARK: - CustomStringConvertible
    //
    
    public var description: String {
        return "[code = \(self.code), symbol = \(self.symbol), " +
            "exponent: \(self.exponent), " +
            "decimal separator = \(self.separator), " +
        "grouping separator = \(self.delimiter ?? "N/A")]"
    }
    
}

extension Currency {
    
    //
    //MARK: - Hashable
    //
    
    public var hashValue : Int {
        get {
            return self.code.hashValue
        }
    }
    
}

extension Currency {
    
    //
    //MARK: - Equatable
    //
    
    public func equals(_ other: Self) -> Bool {
        // ??? Should we check something else
        return self.code == other.code
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.equals(rhs)
    }
    
}

//

public protocol CurrencyFormatter {
    // Returns a string containing the formatted value of the provided number object.
    func string(from number: NSNumber) -> String?
    // Returns an NSNumber object created by parsing a given string.
    func number(from string: String) -> NSNumber?
}

//
// This class is simple NSNumberFormatter wrapper
//

public final class LocaleCurrency: Currency {
    
    //
    //MARK: - Initialization
    //
    
    // Set locale as constructor DI
    public init?(_ locale: Locale = Locale.current) {
        // fail if we can't get currency code from locale
        if locale.currencyCode == nil {
            return nil
        }

        formatter               = NumberFormatter()
        formatter.numberStyle   = .currency
        formatter.locale        = locale
    }
    
    //
    //MARK: - Properties
    //
    
    // Currency formatter
    private(set) var formatter: NumberFormatter
    
}

extension LocaleCurrency {
    
    //
    //MARK: - Currency
    //
    
    public var code: String {
        get {
            return self.formatter.currencyCode
        }
    }
    
    public var symbol: String {
        get {
            return self.formatter.currencySymbol ?? ""
        }
    }
    
    public var exponent: Int {
        get {
            return self.formatter.maximumFractionDigits
        }
    }
    
    public var separator: String {
        get {
            return self.formatter.currencyDecimalSeparator ?? ""
        }
    }

    public var delimiter: String? {
        get {
            return self.formatter.currencyGroupingSeparator
        }
    }
    
}

extension LocaleCurrency {
    
    //
    //MARK: - CurrencyFormatter
    //
    
    public func string(from number: NSNumber) -> String? {
        return formatter.string(from: number)
    }
    
    public func number(from string: String) -> NSNumber? {
        return formatter.number(from: string)
    }
    
}

extension LocaleCurrency {
    
    //
    //MARK: - Factory Methods
    //
    
    // Try to create currency object from locale identifier
    public class func create(from localeIdentifier: String) -> LocaleCurrency? {
        // Check for valid identifier
        if !Locale.availableIdentifiers.contains(localeIdentifier) {
            return nil
        }
        
        let localeCanonicalIdentifier = Locale.canonicalIdentifier(from: localeIdentifier)
        let locale = Locale(identifier: localeCanonicalIdentifier)
        let currency = LocaleCurrency(locale)
        return currency
    }

    // Try to create currency object from currency code
    public class func create(with currencyCode: String) -> LocaleCurrency? {
        // Check for valid code
        if !Locale.isoCurrencyCodes.contains(currencyCode) {
            return nil
        }
        
        let components = [NSLocale.Key.currencyCode.rawValue : currencyCode]
        let localeIdentifier = Locale.identifier(fromComponents: components)
        let localeCanonicalIdentifier = Locale.canonicalIdentifier(from: localeIdentifier)
        let locale = Locale(identifier: localeCanonicalIdentifier)
        let currency = LocaleCurrency(locale)
        return currency
    }

}

extension LocaleCurrency {
    
    //
    //MARK: - Default Currency 
    //
    
    // Default Currency is US Dollars(USD)
    public static var `default` = LocaleCurrency.create(with: "USD")!
    
}

// Currently not used

extension NumberFormatter {
    
    //
    //MARK: - NumberFormatter Helper Extension
    //
    
    static let availableDecimalSeparators  = Set<String>(["٫", ",", "."])
    static let availableGroupingSeparators = Set<String>([",", "٬", " ", "’", "\'", "."])
}
