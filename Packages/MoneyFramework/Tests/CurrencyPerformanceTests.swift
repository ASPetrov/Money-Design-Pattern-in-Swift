import Foundation
import MoneyFramework
import XCTest

final class CurrencyPerformanceTests: XCTestCase {
    func testCreateCurrencyWithLocaleIdentifierPerformance() {
        self.measure() {
            _ = LocaleCurrency(localeIdentifier: "en_US")
        }
    }

    func testCreateCurrencyWithCurrencyCodePerformance() {
        self.measure() {
            _ = LocaleCurrency(isoCurrencyCode: "EUR")
        }
    }
}
