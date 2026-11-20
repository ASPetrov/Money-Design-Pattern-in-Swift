import Foundation
@testable import TestFrameworkApp
import Testing

struct ConversionModelTests {
    @MainActor
    @Test func convertsSelectedCurrenciesUsingSampleRates() async {
        let model = ConversionModel(rateProvider: SampleRateProvider(), locale: Locale(identifier: "en_US"))
        model.amountText = "10.50"
        model.source = .usd
        model.destination = .eur

        await model.convert()

        guard case let .converted(result) = model.state else {
            Issue.record("Expected a conversion result")
            return
        }
        #expect(result.currency.code == "EUR")
        #expect(result.amount == Decimal(string: "8.40"))

        model.destination = .bgn
        #expect(model.state == .idle)
    }

    @MainActor
    @Test func rejectsInvalidAmountBeforeConversion() async {
        let provider = UnavailableRates()
        let model = ConversionModel(rateProvider: provider, locale: Locale(identifier: "en_US"))
        model.amountText = "10oops"

        await model.convert()

        #expect(model.state == .failed(.invalidAmount))
        let requestCount = await provider.requestCount
        #expect(requestCount == 0)
    }

    @MainActor
    @Test func sameCurrencyUsesTheOriginalAmount() async {
        let provider = UnavailableRates()
        let model = ConversionModel(rateProvider: provider, locale: Locale(identifier: "de_DE"))
        model.amountText = "1,25"
        model.destination = model.source

        await model.convert()

        let requestCount = await provider.requestCount
        #expect(requestCount == 0)
        guard case let .converted(result) = model.state else {
            Issue.record("Expected the amount in the original currency")
            return
        }
        #expect(result.amount == Decimal(string: "1.25"))
    }

    @MainActor
    @Test func reportsProviderFailure() async {
        let model = ConversionModel(rateProvider: UnavailableRates(), locale: Locale(identifier: "en_US"))
        model.amountText = "10"

        await model.convert()

        #expect(model.state == .failed(.rateUnavailable))
    }
}

private actor UnavailableRates: ExchangeRateProviding {
    private struct RateUnavailable: Error {}

    private(set) var requestCount = 0

    func rate(from source: DemoCurrency, to destination: DemoCurrency) async throws -> Decimal {
        requestCount += 1
        throw RateUnavailable()
    }
}
