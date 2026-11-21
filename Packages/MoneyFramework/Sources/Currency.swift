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
        guard let currencyLocale = isoFormattingLocale() else {
            return customString(from: number, locale: locale ?? .current)
        }
        return formattingCurrency(
            locale: locale,
            currencyLocale: currencyLocale
        ).string(from: number)
    }

    /// Returns nil if the input cannot be parsed as an exact monetary amount.
    /// Leading and trailing whitespace and newlines are ignored.
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

    private func customString(from number: NSNumber, locale: Locale) -> String? {
        var value = number.decimalValue
        guard !value.isNaN else {
            return nil
        }

        let formatter = decimalFormatter(locale: locale)
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

    func parseAmount(_ string: String, locale: Locale?) throws -> Amount {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let currencyLocale = isoFormattingLocale() else {
            return try parseCustomAmount(string, locale: locale ?? .current)
        }

        let selectedLocale = locale ?? currencyLocale
        let formatter = formattingCurrency(
            locale: locale,
            currencyLocale: currencyLocale
        )
        return
            try parseCurrencyAffixes(
                string,
                formatter: formatter,
                locale: selectedLocale
            )
            ?? parseNumericAmount(
                string,
                locale: locale,
                fallback: selectedLocale
            )
    }

    private func parseNumericAmount(
        _ string: String,
        locale: Locale?,
        fallback: Locale
    ) throws -> Amount {
        if locale == nil {
            do {
                return try Amount(decimalString: string)
            } catch Amount.ValidationError.invalidFormat {
                return try Amount(
                    localizedString: string,
                    locale: fallback
                )
            }
        }
        return try Amount(localizedString: string, locale: fallback)
    }

    private func parseCurrencyAffixes(
        _ string: String,
        formatter: NumberFormatter,
        locale: Locale
    ) throws -> Amount? {
        let numbers = decimalFormatter(locale: locale)
        numbers.decimalSeparator = formatter.currencyDecimalSeparator
        numbers.groupingSeparator = formatter.currencyGroupingSeparator
        for (prefix, suffix, negative) in [
            (formatter.negativePrefix ?? "", formatter.negativeSuffix ?? "", true),
            (formatter.positivePrefix ?? "", formatter.positiveSuffix ?? "", false),
        ] where !prefix.isEmpty || !suffix.isEmpty {
            guard
                let digits = currencyDigits(in: string, prefix: prefix, suffix: suffix),
                let amount = try parseAffixedDigits(digits, formatter: numbers, negative: negative)
            else {
                continue
            }
            return amount
        }
        return nil
    }

    private func parseAffixedDigits(
        _ digits: String,
        formatter: NumberFormatter,
        negative: Bool
    ) throws -> Amount? {
        do {
            let amount = try Amount(
                localizedString: digits,
                formatter: formatter,
                allowsSign: false
            )
            return negative ? try Amount(decimal: -amount.decimalValue) : amount
        } catch Amount.ValidationError.invalidFormat {
            return nil
        }
    }

    private func currencyDigits(
        in string: String,
        prefix: String,
        suffix: String
    ) -> String? {
        guard
            string.hasPrefix(prefix),
            string.hasSuffix(suffix),
            string.count > prefix.count + suffix.count
        else {
            return nil
        }
        var digits = string.dropFirst(prefix.count).dropLast(suffix.count)
        // The formatter can insert a nonbreaking space next to a currency code.
        if prefix.last?.isLetter == true, isCurrencySpace(digits.first) {
            digits = digits.dropFirst()
        }
        if suffix.first?.isLetter == true, isCurrencySpace(digits.last) {
            digits = digits.dropLast()
        }
        return String(digits)
    }

    private func isCurrencySpace(_ character: Character?) -> Bool {
        character == "\u{00A0}" || character == "\u{202F}"
    }

    private func parseCustomAmount(
        _ string: String,
        locale: Locale
    ) throws -> Amount {
        let suffix = " " + (symbol ?? code)
        let codeSuffix = " " + code
        var digits = string
        if digits.hasSuffix(suffix) {
            digits.removeLast(suffix.count)
        } else if digits.hasSuffix(codeSuffix) {
            digits.removeLast(codeSuffix.count)
        }
        return try Amount(localizedString: digits, locale: locale)
    }

    private func formattingCurrency(
        locale: Locale?,
        currencyLocale: Locale
    ) -> NumberFormatter {
        guard let locale else {
            return currencyFormatter(with: currencyLocale)
        }
        let formatter = NumberFormatter(currencyLocale: locale)
        formatter.currencyCode = code
        formatter.maximumFractionDigits = minorUnits
        return formatter
    }

    private func isoFormattingLocale() -> Locale? {
        identifier.usesCustomFormatting ? nil : Locale.locale(for: code)
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

// MARK: - Helpers

extension NumberFormatter {

    convenience init(currencyLocale: Locale) {
        self.init()
        numberStyle = .currency
        locale = currencyLocale
    }
}
