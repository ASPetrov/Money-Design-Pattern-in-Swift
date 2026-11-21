import Foundation

enum MonetaryRounding {

    enum Operation {

        case add
        case subtract
        case multiply
        case divide
    }

    static func calculate(
        _ lhs: Decimal,
        _ rhs: Decimal,
        operation: Operation,
        scale: Int,
        mode: Decimal.RoundingMode
    ) throws -> Decimal {
        guard (0 ... 127).contains(scale) else {
            throw Amount.ValidationError.invalidScale
        }
        guard !lhs.isNaN, !rhs.isNaN, operation != .divide || !rhs.isZero else {
            throw Amount.ValidationError.unrepresentableValue
        }
        let left = ExactDecimal(lhs)
        let right = ExactDecimal(rhs)
        let fraction = left.operating(operation, with: right)
        return try fraction.rounded(scale: scale, mode: mode)
    }
}

private struct ExactDecimal {

    let magnitude: DecimalDigits
    let exponent: Int
    let isNegative: Bool

    init(_ decimal: Decimal) {
        var decimal = decimal
        let text = NSDecimalString(&decimal, Locale(identifier: "en_US_POSIX"))
        isNegative = text.hasPrefix("-")
        let unsigned = isNegative ? text.dropFirst() : text[...]
        let fraction = unsigned.firstIndex(of: ".")
            .map {
                unsigned.distance(from: $0, to: unsigned.endIndex) - 1
            }
        var power = -(fraction ?? 0)
        var digits = unsigned.utf8.filter { $0 != 46 }.map { Int($0) - 48 }
        while digits.last == 0 {
            digits.removeLast()
            power += 1
        }
        exponent = power
        magnitude = DecimalDigits(digits)
    }

    func operating(
        _ operation: MonetaryRounding.Operation,
        with rhs: Self
    ) -> DecimalFraction {
        switch operation {
        case .add, .subtract:
            return adding(rhs, subtract: operation == .subtract)
        case .multiply:
            return DecimalFraction(
                numerator: magnitude.multiplied(by: rhs.magnitude),
                exponent: exponent + rhs.exponent,
                isNegative: isNegative != rhs.isNegative
            )
        case .divide:
            return DecimalFraction(
                numerator: magnitude,
                denominator: rhs.magnitude,
                exponent: exponent - rhs.exponent,
                isNegative: isNegative != rhs.isNegative
            )
        }
    }

    private func adding(_ rhs: Self, subtract: Bool) -> DecimalFraction {
        let sharedExponent = min(exponent, rhs.exponent)
        let left = magnitude.shifted(by: exponent - sharedExponent)
        let right = rhs.magnitude.shifted(by: rhs.exponent - sharedExponent)
        let rightNegative = rhs.isNegative != subtract
        if isNegative == rightNegative {
            return DecimalFraction(
                numerator: left.adding(right),
                exponent: sharedExponent,
                isNegative: isNegative
            )
        }
        let leftIsSmaller = left.isLess(than: right)
        return DecimalFraction(
            numerator: leftIsSmaller ? right.subtracting(left) : left.subtracting(right),
            exponent: sharedExponent,
            isNegative: leftIsSmaller ? rightNegative : isNegative
        )
    }
}

private struct DecimalFraction {

    let numerator: DecimalDigits
    let denominator: DecimalDigits
    let exponent: Int
    let isNegative: Bool

    init(
        numerator: DecimalDigits,
        denominator: DecimalDigits = DecimalDigits([1]),
        exponent: Int,
        isNegative: Bool
    ) {
        self.numerator = numerator
        self.denominator = denominator
        self.exponent = exponent
        self.isNegative = isNegative
    }

    func rounded(scale: Int, mode: Decimal.RoundingMode) throws -> Decimal {
        let shift = exponent + scale
        let dividend = numerator.shifted(by: max(0, shift))
        let divisor = denominator.shifted(by: max(0, -shift))
        let (units, remainder) = dividend.quotientAndRemainder(dividingBy: divisor)
        let increment = try shouldIncrement(units, remainder: remainder, divisor: divisor, mode: mode)
        let rounded = increment ? units.adding(DecimalDigits([1])) : units
        return try Amount(
            decimalString: rounded.decimalText(
                scale: scale,
                negative: isNegative
            )
        ).decimalValue
    }

    // The exact remainder determines which side of a rounding boundary the value is on.
    private func shouldIncrement(
        _ units: DecimalDigits,
        remainder: DecimalDigits,
        divisor: DecimalDigits,
        mode: Decimal.RoundingMode
    ) throws -> Bool {
        guard !remainder.isZero else {
            return false
        }
        switch mode {
        case .down:
            return isNegative
        case .up:
            return !isNegative
        case .plain, .bankers:
            let doubled = remainder.adding(remainder)
            return divisor.isLess(than: doubled)
                || (divisor == doubled && (mode == .plain || units.isOdd))
        @unknown default:
            throw Amount.ValidationError.unrepresentableValue
        }
    }
}

private struct DecimalDigits: Equatable {

    private let digits: [Int]

    init(_ digits: [Int]) {
        self.digits = Array(digits.drop(while: { $0 == 0 }))
    }

    var isZero: Bool { digits.isEmpty }
    var isOdd: Bool { (digits.last ?? 0) % 2 != 0 }

    func shifted(by places: Int) -> Self {
        isZero || places == 0
            ? self
            : Self(digits + Array(repeating: 0, count: places))
    }

    func isLess(than other: Self) -> Bool {
        digits.count == other.digits.count
            ? digits.lexicographicallyPrecedes(other.digits)
            : digits.count < other.digits.count
    }

    func adding(_ other: Self) -> Self {
        let count = max(digits.count, other.digits.count)
        var result = Array(repeating: 0, count: count + 1)
        for offset in 0 ..< count {
            let position = count - offset
            let sum =
                digit(fromEnd: offset)
                    + other.digit(fromEnd: offset)
                    + result[position]
            result[position] = sum % 10
            result[position - 1] = sum / 10
        }
        return Self(result)
    }

    private func digit(fromEnd offset: Int) -> Int {
        offset < digits.count ? digits[digits.count - 1 - offset] : 0
    }

    func subtracting(_ other: Self) -> Self {
        var result = digits
        var borrow = 0
        for offset in digits.indices {
            let position = digits.count - 1 - offset
            let difference =
                digits[position] - other.digit(fromEnd: offset) - borrow
            borrow = difference < 0 ? 1 : 0
            result[position] = difference + borrow * 10
        }
        return Self(result)
    }

    func multiplied(by other: Self) -> Self {
        var result = Array(repeating: 0, count: digits.count + other.digits.count)
        for left in digits.indices.reversed() {
            for right in other.digits.indices.reversed() {
                let position = left + right + 1
                let product = digits[left] * other.digits[right] + result[position]
                result[position] = product % 10
                result[position - 1] += product / 10
            }
        }
        return Self(result)
    }

    func quotientAndRemainder(dividingBy divisor: Self) -> (Self, Self) {
        if divisor.digits == [1] {
            return (self, Self([]))
        }
        var remainder = Self([])
        var quotient: [Int] = []
        for digit in digits {
            remainder = Self(remainder.digits + [digit])
            var quotientDigit = 0
            while !remainder.isLess(than: divisor) {
                remainder = remainder.subtracting(divisor)
                quotientDigit += 1
            }
            quotient.append(quotientDigit)
        }
        return (Self(quotient), remainder)
    }

    func decimalText(scale: Int, negative: Bool) -> String {
        guard !isZero else {
            return "0"
        }
        let sign = negative ? "-" : ""
        let text = String(decoding: digits.map { UInt8($0 + 48) }, as: UTF8.self)
        guard scale > 0 else {
            return sign + text
        }
        let padding = String(repeating: "0", count: max(0, scale + 1 - text.count))
        let padded = padding + text
        return sign + padded.dropLast(scale) + "." + padded.suffix(scale)
    }
}
