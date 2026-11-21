import Foundation
import MoneyFramework
import Testing

struct AmountTests {
    @Test func testScalarBoundsPreserveSignedness() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        let cases: [(any DecimalRepresentable, String)] = [
            (Int64.min, "-9223372036854775808"),
            (UInt64.max, "18446744073709551615"),
        ]

        for (scalar, text) in cases {
            let expected = try #require(Decimal(string: text, locale: locale))
            #expect(scalar.decimalNumber == expected)
        }
    }

    @Test(arguments: [Double.nan, .infinity, -.infinity, .greatestFiniteMagnitude, .leastNonzeroMagnitude])
    func testDoubleOutsideDecimalRange(_ value: Double) throws {
        let scalar: any DecimalRepresentable = value
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let money = try #require(Money(amount: Decimal(5), currency: currency))

        #expect(money.addingChecked(scalar) == .failure(.invalidScalar))
        #expect(money.subtractingChecked(scalar) == .failure(.invalidScalar))
        #expect(money.multiplyingChecked(by: scalar) == .failure(.invalidScalar))
        #expect(money.dividingChecked(by: scalar) == .failure(.invalidDivisor))
    }

    @Test func testFiniteDoubleKeepsRounding() throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let money = try #require(Money(amount: Decimal(5), currency: currency))
        let rounded = try #require(Money(amount: "0.62", currency: currency))

        #expect(money.multiplyingChecked(by: 0.125) == .success(rounded))
    }

    @Test func testDivisionUsesExactScalarsAndFlagsText() throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let money = try #require(Money(amount: Decimal(1), currency: currency))
        let divisor = try Amount(decimalString: "0.125")

        #expect(divisor.decimalNumber == Decimal(125) / 1000)
        #expect(try money.divide(by: divisor).amount == 8)
        #expect(try money.divide(by: "0.125").amount == 8)
        let invalidScalar: any DecimalRepresentable = "0.125 extra"
        if case let .failure(error) = invalidScalar.decimalConversion {
            #expect(error as? Amount.ValidationError == .invalidFormat)
        } else {
            Issue.record("Expected a scalar conversion error")
        }
        #expect(throws: Money<LocaleCurrency>.ArithmeticError.invalidDivisor) {
            _ = try money.divide(by: "invalid")
        }
    }

    @Test func testExactConstructionAndMinorUnits() throws {
        #expect(Amount.zero.decimalValue == .zero)
        #expect(try Amount(integer: Int.min).minorUnits(scale: 0) == Int.min)
        #expect(try Amount(minorUnits: Int.min, scale: 3).minorUnits(scale: 3) == Int.min)
        #expect(try Amount(minorUnits: -5, scale: 2).decimalValue == Decimal(string: "-0.05"))
        #expect(try Amount(decimalString: "+0001.2300").decimalValue == Decimal(string: "1.23"))
        #expect(try Amount(decimalString: "0.000000000000000001").minorUnits(scale: 18) == 1)
    }

    @Test func testRejectsInvalidAndInexactInputs() throws {
        #expect(throws: (any Error).self) {
            _ = try Amount(decimal: .nan)
        }
        #expect(throws: (any Error).self) {
            _ = try Amount(decimalString: "1.23oops")
        }
        #expect(throws: (any Error).self) {
            _ = try Amount(decimalString: "1.1234567890123456789012345678901234567890123456789")
        }
        #expect(throws: (any Error).self) {
            _ = try Amount(minorUnits: 1, scale: -1)
        }
        #expect(throws: (any Error).self) {
            _ = try Amount(minorUnits: 1, scale: Int.max)
        }
    }

    @Test func testRejectsUnrepresentableMinorUnits() throws {
        #expect(throws: (any Error).self) {
            _ = try Amount(decimalString: "0.001").minorUnits(scale: 2)
        }
        #expect(throws: (any Error).self) {
            _ = try Amount(decimalString: "10").minorUnits(scale: 18)
        }
    }

    @Test func testLocalizedParsingConsumesExactInput() throws {
        let locale = Locale(identifier: "de_DE")
        #expect(try Amount(localizedString: "1.234,567890123456789", locale: locale)
            .decimalValue == Decimal(string: "1234.567890123456789"))
        #expect(throws: (any Error).self) {
            _ = try Amount(localizedString: "1,25 USD", locale: locale)
        }
        #expect(throws: (any Error).self) {
            _ = try Amount(localizedString: "12.34,5", locale: locale)
        }
    }
}
