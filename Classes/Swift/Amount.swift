import Foundation

/// An exact decimal quantity before currency-specific rounding.
public struct Amount: Equatable, Sendable {

    public enum ValidationError: Error, Equatable {
        case invalidFormat
        case unrepresentableValue
        case invalidScale
        case fractionalMinorUnits
        case minorUnitsOutOfRange
    }

    public static let zero = Amount(integer: 0)

    public let decimalValue: Decimal

    public init(decimal: Decimal) throws {
        guard !decimal.isNaN else {
            throw ValidationError.unrepresentableValue
        }
        self.decimalValue = decimal
    }

    public init(integer: Int) {
        decimalValue = Decimal(integer)
    }

    /// Parses ASCII digits with an optional sign and a dot as the decimal separator.
    public init(decimalString: String) throws {
        guard let canonical = Self.canonicalDecimalString(decimalString) else {
            throw ValidationError.invalidFormat
        }
        let locale = Locale(identifier: "en_US_POSIX")
        guard
            var parsed = Decimal(string: canonical, locale: locale),
            !parsed.isNaN,
            Self.canonicalDecimalString(NSDecimalString(&parsed, locale)) == canonical
        else {
            throw ValidationError.unrepresentableValue
        }
        decimalValue = parsed
    }

    /// Parses a localized decimal number with optional grouping and no currency symbol.
    public init(localizedString: String, locale: Locale) throws {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal

        var input = localizedString[...]
        var sign = ""
        if let minusSign = formatter.minusSign, !minusSign.isEmpty, input.hasPrefix(minusSign) {
            input.removeFirst(minusSign.count)
            sign = "-"
        } else if let plusSign = formatter.plusSign, !plusSign.isEmpty, input.hasPrefix(plusSign) {
            input.removeFirst(plusSign.count)
        }

        let parts = input.components(separatedBy: formatter.decimalSeparator ?? ".")
        guard parts.count <= 2 else {
            throw ValidationError.invalidFormat
        }

        let grouping = formatter.groupingSeparator ?? ""
        let groups = grouping.isEmpty ? [parts[0]] : parts[0].components(separatedBy: grouping)
        if groups.count > 1 {
            let primary = formatter.groupingSize
            let secondary = formatter.secondaryGroupingSize > 0 ? formatter.secondaryGroupingSize : primary
            guard
                groups.last?.count == primary,
                let first = groups.first,
                (1 ... max(1, secondary)).contains(first.count),
                groups.dropFirst().dropLast().allSatisfy({ $0.count == secondary })
            else {
                throw ValidationError.invalidFormat
            }
        }
        let whole = try Self.asciiDigits(groups.joined())
        let fraction = parts.count == 2 ? "." + (try Self.asciiDigits(parts[1])) : ""
        try self.init(decimalString: sign + whole + fraction)
    }

    /// Converts a signed count of minor units using a scale between 0 and 127.
    public init(minorUnits: Int, scale: Int) throws {
        try Self.validateScale(scale)
        var units = Decimal(minorUnits)
        var result = Decimal()
        guard
            NSDecimalMultiplyByPowerOf10(&result, &units, -Int16(scale), .plain) == .noError
        else {
            throw ValidationError.unrepresentableValue
        }
        try self.init(decimal: result)
    }

    /// Returns the exact signed minor-unit count, or throws if it is fractional or outside Int.
    public func minorUnits(scale: Int) throws -> Int {
        try Self.validateScale(scale)
        var value = decimalValue
        var scaled = Decimal()
        guard
            NSDecimalMultiplyByPowerOf10(&scaled, &value, Int16(scale), .plain) == .noError,
            !scaled.isNaN
        else {
            throw ValidationError.minorUnitsOutOfRange
        }
        var integral = Decimal()
        NSDecimalRound(&integral, &scaled, 0, .down)
        guard integral == scaled else {
            throw ValidationError.fractionalMinorUnits
        }
        guard
            scaled >= Decimal(Int.min),
            scaled <= Decimal(Int.max)
        else {
            throw ValidationError.minorUnitsOutOfRange
        }
        return NSDecimalNumber(decimal: scaled).intValue
    }

    func rounded(scale: Int, mode: Decimal.RoundingMode) throws -> Amount {
        try Self.validateScale(scale)
        var value = decimalValue
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return try Amount(decimal: result)
    }

    private static func validateScale(_ scale: Int) throws {
        guard (0 ... 127).contains(scale) else {
            throw ValidationError.invalidScale
        }
    }

    private static func asciiDigits(_ string: String) throws -> String {
        var digits = ""
        for scalar in string.unicodeScalars {
            guard
                scalar.properties.numericType == .decimal,
                let value = scalar.properties.numericValue
            else {
                throw ValidationError.invalidFormat
            }
            digits.append(String(Int(value)))
        }
        return digits
    }

    // Normalize both the validated input and Foundation's rendering before comparing them.
    private static func canonicalDecimalString(_ string: String) -> String? {
        var unsigned = string[...]
        let negative = unsigned.first == "-"
        if negative || unsigned.first == "+" {
            unsigned.removeFirst()
        }
        let parts = unsigned.split(separator: ".", omittingEmptySubsequences: false)
        guard
            let whole = parts.first,
            parts.count <= 2,
            !whole.isEmpty,
            parts.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { (48 ... 57).contains($0) } })
        else {
            return nil
        }
        let integral = whole.drop(while: { $0 == "0" })
        var fraction = parts.count == 2 ? parts[1] : ""
        while fraction.last == "0" {
            fraction.removeLast()
        }
        let sign = negative && (!integral.isEmpty || !fraction.isEmpty) ? "-" : ""
        return sign + (integral.isEmpty ? "0" : String(integral)) + (fraction.isEmpty ? "" : "." + fraction)
    }
}
