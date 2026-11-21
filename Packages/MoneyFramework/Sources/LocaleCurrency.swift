import Foundation

/// LocaleCurrency a refinement of Currency so we can get it from Locale.
public struct LocaleCurrency: Currency, Sendable {

    // MARK: - Currency

    /// The currency code is stored in uppercase.
    public var code: String {
        didSet {
            code = code.uppercased()
        }
    }

    public var identifier: CurrencyIdentifier { .iso(code) }
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
        self.code = code.uppercased()
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

        let canonicalIdentifier = Locale.canonicalIdentifier(
            from: localeIdentifier
        )
        let locale = Locale(identifier: canonicalIdentifier)

        self.init(locale: locale)
    }

    public init?(locale: Locale = Locale.current) {
        guard let currencyCode = locale.currencyCode else {
            return nil
        }

        let formatter = NumberFormatter(currencyLocale: locale)
        let currencyName =
            locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
        self.init(
            code: currencyCode,
            name: currencyName,
            minorUnits: formatter.maximumFractionDigits,
            symbol: formatter.currencySymbol,
            separator: formatter.currencyDecimalSeparator,
            delimiter: formatter.currencyGroupingSeparator
        )
    }
}

/// LocaleCurrency factory methods
extension LocaleCurrency {

    @available(*, deprecated, message: "Use LocaleCurrency() instead.")
    public static func current() -> LocaleCurrency? {
        Self(locale: Locale.current)
    }

    @available(*, deprecated, message: "Use LocaleCurrency(locale:) instead.")
    public static func currency(for locale: Locale) -> LocaleCurrency? {
        Self(locale: locale)
    }
}
