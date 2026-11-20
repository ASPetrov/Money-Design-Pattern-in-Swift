import Foundation
import MoneyFramework
import XCTest

final class AmountTests: XCTestCase {
    func testSignedAndUnsignedScalarsPreserveTheirBoundaryValues() throws {
        let locale = Locale(identifier: "en_US_POSIX")
        let cases: [(any DecimalRepresentable, String)] = [
            (Int64.min, "-9223372036854775808"),
            (UInt64.max, "18446744073709551615"),
        ]

        for (scalar, text) in cases {
            let expected = try XCTUnwrap(Decimal(string: text, locale: locale))
            XCTAssertEqual(scalar.decimalNumber, expected, text)
        }
    }

    func testCheckedDivisionUsesExactAmountScalarsAndRejectsInvalidStrings() throws {
        let currency = try XCTUnwrap(LocaleCurrency(isoCurrencyCode: "EUR"))
        let money = try XCTUnwrap(Money(amount: Decimal(1), currency: currency))
        let divisor = try Amount(decimalString: "0.125")

        XCTAssertEqual(divisor.decimalNumber, Decimal(125) / 1000)
        XCTAssertEqual(try money.divide(by: divisor).amount, 8)
        XCTAssertEqual(try money.divide(by: "0.125").amount, 8)
        let invalidScalar: any DecimalRepresentable = "0.125 extra"
        if case let .failure(error) = invalidScalar.decimalConversion {
            XCTAssertEqual(error as? Amount.ValidationError, .invalidFormat)
        } else {
            XCTFail("Expected a scalar conversion error")
        }
        XCTAssertThrowsError(try money.divide(by: "invalid")) {
            XCTAssertEqual($0 as? Money<LocaleCurrency>.ArithmeticError, .invalidDivisor)
        }
    }

    func testExactConstructionAndMinorUnits() throws {
        XCTAssertEqual(Amount.zero.decimalValue, .zero)
        XCTAssertEqual(try Amount(integer: Int.min).minorUnits(scale: 0), Int.min)
        XCTAssertEqual(try Amount(minorUnits: Int.min, scale: 3).minorUnits(scale: 3), Int.min)
        XCTAssertEqual(try Amount(minorUnits: -5, scale: 2).decimalValue, Decimal(string: "-0.05"))
        XCTAssertEqual(try Amount(decimalString: "+0001.2300").decimalValue, Decimal(string: "1.23"))
        XCTAssertEqual(try Amount(decimalString: "0.000000000000000001").minorUnits(scale: 18), 1)
    }

    func testRejectsInvalidAndInexactInputs() throws {
        XCTAssertThrowsError(try Amount(decimal: .nan))
        XCTAssertThrowsError(try Amount(decimalString: "1.23oops"))
        XCTAssertThrowsError(try Amount(decimalString: "1.1234567890123456789012345678901234567890123456789"))
        XCTAssertThrowsError(try Amount(minorUnits: 1, scale: -1))
        XCTAssertThrowsError(try Amount(minorUnits: 1, scale: Int.max))
        XCTAssertThrowsError(try Amount(decimalString: "0.001").minorUnits(scale: 2))
        XCTAssertThrowsError(try Amount(decimalString: "10").minorUnits(scale: 18))
    }

    func testLocalizedParsingIsExactAndConsumesTheWholeInput() throws {
        let locale = Locale(identifier: "de_DE")
        XCTAssertEqual(
            try Amount(localizedString: "1.234,567890123456789", locale: locale).decimalValue,
            Decimal(string: "1234.567890123456789")
        )
        XCTAssertThrowsError(try Amount(localizedString: "1,25 USD", locale: locale))
        XCTAssertThrowsError(try Amount(localizedString: "12.34,5", locale: locale))
    }
}
