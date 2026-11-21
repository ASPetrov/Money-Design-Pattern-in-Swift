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
