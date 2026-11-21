import Foundation
import MoneyFramework
import XCTest

final class CurrencyPerformanceTests: XCTestCase {

    func testLookupByLocalePerformance() {
        self.measure() {
            _ = LocaleCurrency(localeIdentifier: "en_US")
        }
    }

    func testLookupByISOCodePerformance() {
        self.measure() {
            _ = LocaleCurrency(isoCurrencyCode: "EUR")
        }
    }
}
