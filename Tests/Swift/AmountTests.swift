import Foundation
import MoneyFramework
import XCTest

final class AmountTests: XCTestCase {
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
