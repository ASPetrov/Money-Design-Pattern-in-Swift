import Foundation
@testable import TestFrameworkApp
import XCTest

final class ConversionModelTests: XCTestCase {
    @MainActor
    func testConvertsSelectedCurrenciesUsingSampleRates() async throws {
        let model = ConversionModel(rateProvider: SampleRateProvider(), locale: Locale(identifier: "en_US"))
        model.amountText = "10.50"
        model.source = .usd
        model.destination = .eur

        await model.convert()

        guard case let .converted(result) = model.state else {
            return XCTFail("Expected a conversion result")
        }
        XCTAssertEqual(result.currency.code, "EUR")
        XCTAssertEqual(result.amount, Decimal(string: "8.40"))

        model.destination = .bgn
        XCTAssertEqual(model.state, .idle)
    }

    @MainActor
    func testRejectsInvalidAmountBeforeConversion() async {
        let model = ConversionModel(rateProvider: SampleRateProvider(), locale: Locale(identifier: "en_US"))
        model.amountText = "10oops"

        await model.convert()

        XCTAssertEqual(model.state, .failed(.invalidAmount))
    }

    @MainActor
    func testSameCurrencyUsesTheOriginalAmount() async throws {
        let model = ConversionModel(rateProvider: UnavailableRates(), locale: Locale(identifier: "de_DE"))
        model.amountText = "1,25"
        model.destination = model.source

        await model.convert()

        guard case let .converted(result) = model.state else {
            return XCTFail("Expected the amount in the original currency")
        }
        XCTAssertEqual(result.amount, Decimal(string: "1.25"))
    }

    @MainActor
    func testReportsProviderFailure() async {
        let model = ConversionModel(rateProvider: UnavailableRates(), locale: Locale(identifier: "en_US"))
        model.amountText = "10"

        await model.convert()

        XCTAssertEqual(model.state, .failed(.rateUnavailable))
    }
}

private struct UnavailableRates: ExchangeRateProviding {
    struct RateUnavailable: Error {}

    func rate(from source: DemoCurrency, to destination: DemoCurrency) async throws -> Decimal {
        throw RateUnavailable()
    }
}
