//
//  Currency.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation

public enum CurrencyIdentifier: Hashable, Sendable {
    case iso(String)
    case asset(network: String, reference: String)
    case custom(namespace: String, code: String)
    case legacy(String)

    fileprivate var usesCustomFormatting: Bool {
        switch self {
        case .asset, .custom:
            return true
        case .iso, .legacy:
            return false
        }
    }
}

/// A currency definition. Its identifier and minor-unit scale must remain stable while used by Money.
public protocol Currency: Equatable {
    var identifier: CurrencyIdentifier { get }
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
    init?(
        code: String,
        name: String,
        minorUnits: Int,
        symbol: String?,
        separator: String?,
        delimiter: String?
    )
}

/// Currency Convenience  constructor
extension Currency {
    public init?(isoCurrencyCode: String) {
        let code = isoCurrencyCode.uppercased()
        guard let locale = Locale.locale(for: code) else {
            return nil
        }

        let formatter = NumberFormatter(currencyLocale: locale)

        formatter.currencyCode = code
        self.init(
            code: code,
            name: Locale.current.localizedString(forCurrencyCode: code) ?? code,
            minorUnits: formatter.maximumFractionDigits,
            symbol: formatter.currencySymbol,
            separator: formatter.currencyDecimalSeparator,
            delimiter: formatter.currencyGroupingSeparator
        )
    }
}

extension Currency {
    public var identifier: CurrencyIdentifier { .legacy(code) }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier && lhs.minorUnits == rhs.minorUnits
    }
}

extension Currency {
    public func string(
        from number: NSNumber,
        locale: Locale? = nil
    ) -> String? {
        if usesCustomFormatting {
            var value = number.decimalValue
            guard !value.isNaN else {
                return nil
            }

            let formatter = decimalFormatter(locale: locale ?? .current)
            var digits = NSDecimalString(
                &value,
                Locale(identifier: "en_US_POSIX")
            )
            if digits.hasPrefix("-") {
                digits.removeFirst()
                digits = (formatter.minusSign ?? "-") + digits
            }
            digits = digits.replacingOccurrences(
                of: ".",
                with: formatter.decimalSeparator ?? "."
            )
            return digits + " " + (symbol ?? code)
        }

        return formattingCurrency(locale: locale).string(from: number)
    }

    /// Returns nil if the input cannot be parsed as an exact monetary amount.
    public func number(
        from string: String,
        locale: Locale? = nil
    ) -> NSNumber? {
        do {
            let amount = try parseAmount(string, locale: locale)
            return NSDecimalNumber(decimal: amount.decimalValue)
        } catch {
            return nil
        }
    }

    public func currencyFormatter(with locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter(currencyLocale: locale)
        formatter.currencyCode = code
        formatter.maximumFractionDigits = minorUnits
        if let symbol {
            formatter.currencySymbol = symbol
        }
        if let separator {
            formatter.currencyDecimalSeparator = separator
        }
        if let delimiter {
            formatter.currencyGroupingSeparator = delimiter
        }
        return formatter
    }
}

extension Currency {
    func parseAmount(_ string: String, locale: Locale?) throws -> Amount {
        if usesCustomFormatting {
            let suffix = " " + (symbol ?? code)
            let codeSuffix = " " + code
            var digits = string
            if digits.hasSuffix(suffix) {
                digits.removeLast(suffix.count)
            } else if digits.hasSuffix(codeSuffix) {
                digits.removeLast(codeSuffix.count)
            }
            return try Amount(
                localizedString: digits,
                locale: locale ?? .current
            )
        }

        let selectedLocale = locale ?? Locale.locale(for: code) ?? .current
        let currencyFormatter = formattingCurrency(
            locale: locale,
            fallback: selectedLocale
        )
        let numbers = decimalFormatter(locale: selectedLocale)
        // Try full currency affixes before parsing the numeric portion.
        for (prefix, suffix, negative) in [
            (currencyFormatter.negativePrefix ?? "", currencyFormatter.negativeSuffix ?? "", true),
            (currencyFormatter.positivePrefix ?? "", currencyFormatter.positiveSuffix ?? "", false),
        ] where !prefix.isEmpty || !suffix.isEmpty {
            guard
                string.hasPrefix(prefix),
                string.hasSuffix(suffix),
                string.count > prefix.count + suffix.count
            else {
                continue
            }

            let digits = String(string.dropFirst(prefix.count).dropLast(suffix.count))
            numbers.decimalSeparator = currencyFormatter.currencyDecimalSeparator
            numbers.groupingSeparator = currencyFormatter.currencyGroupingSeparator
            do {
                let value = try Amount(localizedString: digits, formatter: numbers, allowsSign: false)
                return negative ? try Amount(decimal: -value.decimalValue) : value
            } catch Amount.ValidationError.invalidFormat {
                continue
            }
        }

        if locale == nil {
            do {
                return try Amount(decimalString: string)
            } catch Amount.ValidationError.invalidFormat {
                return try Amount(
                    localizedString: string,
                    locale: selectedLocale
                )
            }
        }
        return try Amount(localizedString: string, locale: selectedLocale)
    }

    private func formattingCurrency(
        locale: Locale?,
        fallback: Locale? = nil
    ) -> NumberFormatter {
        guard let locale else {
            return currencyFormatter(
                with: fallback ?? Locale.locale(for: code) ?? .current
            )
        }
        let formatter = NumberFormatter(currencyLocale: locale)
        formatter.currencyCode = code
        formatter.maximumFractionDigits = minorUnits
        return formatter
    }

    private var usesCustomFormatting: Bool {
        identifier.usesCustomFormatting || Locale.locale(for: code) == nil
    }

    private func decimalFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        return formatter
    }
}

/// Crypto currency types (Bitcoin etc) should refine CryptoCurrency.
public protocol CryptoCurrency: Currency { }

/// LocaleCurrency a refinement of Currency so we can get it from Locale.
public struct LocaleCurrency: Currency, Sendable {

    // MARK: - Currency

    public var code: String
    public var identifier: CurrencyIdentifier { .iso(code.uppercased()) }
    public var name: String
    public var minorUnits: Int
    public var symbol: String?
    public var separator: String?
    public var delimiter: String?

    public init(
        code: String,
        name: String,
        minorUnits: Int,
        symbol: String?,
        separator: String?,
        delimiter: String?
    ) {
        self.code = code
        self.name = name
        self.minorUnits = minorUnits
        self.symbol = symbol
        self.separator = separator
        self.delimiter = delimiter
    }

}

/// LocaleCurrency Convenience  constructors
extension LocaleCurrency {
    public init?(localeIdentifier: String) {
        // Check for valid identifier
        if !Locale.availableIdentifiers.contains(localeIdentifier) {
            return nil
        }

        let localeCanonicalIdentifier = Locale.canonicalIdentifier(
            from: localeIdentifier
        )
        let locale = Locale(identifier: localeCanonicalIdentifier)

        self.init(locale: locale)
    }

    public init?(locale: Locale = Locale.current) {
        guard let currencyCode = locale.currencyCode else {
            return nil
        }

        let formatter = NumberFormatter(currencyLocale: locale)

        self.init(
            code: currencyCode,
            name: locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode,
            minorUnits: formatter.maximumFractionDigits,
            symbol: formatter.currencySymbol,
            separator: formatter.currencyDecimalSeparator,
            delimiter: formatter.currencyGroupingSeparator
        )
    }
}

/// LocaleCurrency factory methods
extension LocaleCurrency {
    public static func current() -> LocaleCurrency? {
        Self(locale: Locale.current)
    }

    public static func currency(for locale: Locale) -> LocaleCurrency? {
        Self(locale: locale)
    }
}

/// A currency whose identity and scale are supplied by the caller.
public struct CustomCurrency: CryptoCurrency, Sendable {
    public let identifier: CurrencyIdentifier
    public let code: String
    public let name: String
    public let minorUnits: Int
    public let symbol: String?
    public var separator: String? { nil }
    public var delimiter: String? { nil }

    public init?(
        identifier: CurrencyIdentifier,
        code: String,
        name: String,
        minorUnits: Int,
        symbol: String? = nil
    ) {
        guard
            Self.hasValidIdentity(identifier),
            !code.isEmpty,
            (0 ... 127).contains(minorUnits),
            symbol != ""
        else {
            return nil
        }
        self.identifier = identifier
        self.code = code
        self.name = name
        self.minorUnits = minorUnits
        self.symbol = symbol
    }

    public init?(
        code: String,
        name: String,
        minorUnits: Int,
        symbol: String?,
        separator: String?,
        delimiter: String?
    ) {
        guard separator == nil, delimiter == nil else {
            return nil
        }
        self.init(
            identifier: .custom(namespace: "local", code: code),
            code: code,
            name: name,
            minorUnits: minorUnits,
            symbol: symbol
        )
    }

    private static func hasValidIdentity(
        _ identifier: CurrencyIdentifier
    ) -> Bool {
        switch identifier {
        case let .asset(namespace, code), let .custom(namespace, code):
            return !namespace.isEmpty && !code.isEmpty
        case .iso, .legacy:
            return false
        }
    }
}

// MARK: - Helpers

extension NumberFormatter {

    fileprivate convenience init(currencyLocale: Locale) {
        self.init()
        numberStyle = .currency
        locale = currencyLocale
    }
}
