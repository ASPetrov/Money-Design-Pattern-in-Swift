//
//  Currency.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

/// Currency protocol defines the minimum interface needed to represent it
public protocol Currency: Equatable {
    /// The Currency code
    var code: String { get }
    /// The name of the currency
    var name: String { get }
    // The number of decimal places used to express any minor units for the currency
    var minorUnits: Int { get }
    /// The Currency symbol/sign
    var symbol: String? { get }
    // The Currency decimal separator
    var separator: String? { get }
    // The Currency grouping separator
    var delimiter: String? { get }

    /// Default constructor
    init(code: String, name: String, minorUnits: Int, symbol: String?, separator: String?, delimiter: String?)
}

/// Currency Convenience  constructor
public extension Currency {
    init?(isoCurrencyCode: String) {
        guard let locale = Locale.locale(for: isoCurrencyCode) else {
            return nil
        }

        let formatter = NumberFormatter.currencyFormatter
        formatter.locale = locale

        self.init(code: isoCurrencyCode,
                  name: Locale.current.localizedString(forCurrencyCode: isoCurrencyCode) ?? isoCurrencyCode,
                  minorUnits: formatter.maximumFractionDigits,
                  symbol: formatter.currencySymbol,
                  separator: formatter.currencyDecimalSeparator,
                  delimiter: formatter.currencyGroupingSeparator)
    }
}

public extension Currency {

    // MARK: - Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.code == rhs.code
    }

}

/// Format helpers
public extension Currency {
    /// Returns a String containing the formatted ammount
    func string(from number: NSNumber, locale: Locale? = nil) -> String? {
        guard let locale = locale ?? Locale.locale(for: self.code) else {
            return nil
        }

        return currencyFormatter(with: locale).string(from: number)
    }

    /// Returns a NSNumber containing the formatted ammount
    func number(from string: String, locale: Locale? = nil) -> NSNumber? {
        guard let locale = locale ?? Locale.locale(for: self.code) else {
            return nil
        }

        return currencyFormatter(with: locale).number(from: string)
    }

    /// The currency formatter  factory
    func currencyFormatter(with locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter.currencyFormatter
        formatter.locale = locale
        formatter.maximumFractionDigits = minorUnits
        formatter.currencySymbol = symbol
        formatter.currencyDecimalSeparator = separator
        formatter.currencyGroupingSeparator = delimiter

        return formatter
    }
}

/// Crypto currency types (Bitcoin etc) should refine CryptoCurrency.
public protocol CryptoCurrency: Currency { }

/// LocaleCurrency a refinement of Currency so we can get it from Locale.
public struct LocaleCurrency: Currency {

    // MARK: - Currency

    public var code: String
    public var name: String
    public var minorUnits: Int
    public var symbol: String?
    public var separator: String?
    public var delimiter: String?

    public init(code: String, name: String, minorUnits: Int, symbol: String?, separator: String?, delimiter: String?) {
        self.code = code
        self.name = name
        self.minorUnits = minorUnits
        self.symbol = symbol
        self.separator = separator
        self.delimiter = delimiter
    }

}

/// LocaleCurrency Convenience  constructors
public extension LocaleCurrency {
    init?(localeIdentifier: String) {
        // Check for valid identifier
        if !Locale.availableIdentifiers.contains(localeIdentifier) {
            return nil
        }

        let localeCanonicalIdentifier = Locale.canonicalIdentifier(from: localeIdentifier)
        let locale = Locale(identifier: localeCanonicalIdentifier)

        self.init(locale: locale)
    }

    init?(locale: Locale = Locale.current) {
        guard let currencyCode = locale.currencyCode else {
            return nil
        }

        let formatter = NumberFormatter.currencyFormatter
        formatter.locale = locale

        self.init(code: currencyCode,
                  name: locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode,
                  minorUnits: formatter.maximumFractionDigits,
                  symbol: formatter.currencySymbol,
                  separator: formatter.currencyDecimalSeparator,
                  delimiter: formatter.currencyGroupingSeparator)
    }
}

/// LocaleCurrency factory methods
public extension LocaleCurrency {
    static func current() -> LocaleCurrency? {
        return Self(locale: Locale.current)
    }

    static func currency(for locale: Locale) -> LocaleCurrency? {
        return Self(locale: locale)
    }
}

// MARK: - Helpers

private extension NumberFormatter {
    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
}
