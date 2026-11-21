import Foundation
@testable import TestFrameworkApp
import Testing

struct ConversionModelTests {

    @MainActor
    @Test func testConvertsSelectedPairAtSampleRate() async {
        let model = ConversionModel(
            rateProvider: SampleRateProvider(),
            locale: Locale(identifier: "en_US")
        )
        model.amountText = "10.50"
        model.source = .usd
        model.destination = .eur

        await model.convert()?.value

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
    @Test func testRejectsInvalidAmountBeforeConversion() async {
        let provider = UnavailableRates()
        let model = ConversionModel(
            rateProvider: provider,
            locale: Locale(identifier: "en_US")
        )
        model.amountText = "10oops"

        await model.convert()?.value

        #expect(model.state == .failed(.invalidAmount))
        let requestCount = await provider.requestCount
        #expect(requestCount == 0)
    }

    @MainActor
    @Test func testSameCurrencyUsesTheOriginalAmount() async {
        let provider = UnavailableRates()
        let model = ConversionModel(
            rateProvider: provider,
            locale: Locale(identifier: "de_DE")
        )
        model.amountText = "1,25"
        model.destination = model.source

        await model.convert()?.value

        let requestCount = await provider.requestCount
        #expect(requestCount == 0)
        guard case let .converted(result) = model.state else {
            Issue.record("Expected the amount in the original currency")
            return
        }
        #expect(result.amount == Decimal(string: "1.25"))
    }

    @MainActor
    @Test(.timeLimit(.minutes(1)))
    func testEditingAmountCancelsRequest() async throws {
        let provider = ControlledRates()
        let model = ConversionModel(
            rateProvider: provider,
            locale: Locale(identifier: "en_US")
        )
        model.amountText = "10"
        var requests = provider.requests.makeAsyncIterator()
        let conversion = try #require(model.convert())
        let request = try #require(await requests.next())

        #expect(model.state == .loading)
        model.amountText = "20"
        await provider.complete(request, with: .success(1))
        await conversion.value

        #expect(await provider.wasCancelled(request))
        #expect(model.state == .idle)
    }

    @MainActor
    @Test(.timeLimit(.minutes(1)))
    func testLeavingScreenCancelsRequest() async throws {
        let provider = ControlledRates()
        let model = ConversionModel(
            rateProvider: provider,
            locale: Locale(identifier: "en_US")
        )
        model.amountText = "10"
        var requests = provider.requests.makeAsyncIterator()
        let conversion = try #require(model.convert())
        let request = try #require(await requests.next())

        model.cancelConversion()
        await provider.complete(request, with: .failure(.unavailable))
        await conversion.value

        #expect(await provider.wasCancelled(request))
        #expect(model.state == .idle)
    }

    @MainActor
    @Test(.timeLimit(.minutes(1)), arguments: [false, true])
    func testSupersededRequestKeepsNewerResult(fails: Bool) async throws {
        let provider = ControlledRates()
        let model = ConversionModel(
            rateProvider: provider,
            locale: Locale(identifier: "en_US")
        )
        model.amountText = "10"
        var requests = provider.requests.makeAsyncIterator()
        let olderConversion = try #require(model.convert())
        let older = try #require(await requests.next())
        let newerConversion = try #require(model.convert())
        let newer = try #require(await requests.next())

        await provider.complete(newer, with: .success(2))
        await newerConversion.value
        let expected = model.state
        let lateRate: Result<Decimal, ControlledRates.Failure> =
            fails ? .failure(.unavailable) : .success(1)
        await provider.complete(older, with: lateRate)
        await olderConversion.value

        #expect(await provider.wasCancelled(older))
        #expect(model.state == expected)
        expectNewerAmount(expected)
    }

    private func expectNewerAmount(_ state: ConversionModel.State) {
        guard case let .converted(result) = state else {
            Issue.record("Expected the newer conversion to succeed")
            return
        }
        #expect(result.amount == Decimal(20))
    }

    @MainActor
    @Test func testReportsProviderFailure() async {
        let model = ConversionModel(
            rateProvider: UnavailableRates(),
            locale: Locale(identifier: "en_US")
        )
        model.amountText = "10"

        await model.convert()?.value

        #expect(model.state == .failed(.rateUnavailable))
    }
}

private actor UnavailableRates: ExchangeRateProviding {

    private struct RateUnavailable: Error {}

    private(set) var requestCount = 0

    func rate(
        from source: DemoCurrency,
        to destination: DemoCurrency
    ) async throws -> Decimal {
        requestCount += 1
        throw RateUnavailable()
    }
}

private actor ControlledRates: ExchangeRateProviding {

    enum Failure: Error {

        case unavailable
    }

    nonisolated var requests: AsyncStream<Int> { arrivals.stream }
    private let arrivals = AsyncStream<Int>.makeStream()
    private var nextRequest = 0
    private var pending: [Int: CheckedContinuation<Result<Decimal, Failure>, Never>] = [:]
    private var cancelled: Set<Int> = []

    func rate(
        from source: DemoCurrency,
        to destination: DemoCurrency
    ) async throws -> Decimal {
        let request = nextRequest
        nextRequest += 1
        let result = await withCheckedContinuation { continuation in
            pending[request] = continuation
            arrivals.continuation.yield(request)
        }
        if Task.isCancelled {
            cancelled.insert(request)
        }
        switch result {
        case let .success(rate):
            return rate
        case let .failure(error):
            throw error
        }
    }

    func complete(_ request: Int, with result: Result<Decimal, Failure>) {
        pending.removeValue(forKey: request)?.resume(returning: result)
    }

    func wasCancelled(_ request: Int) -> Bool {
        cancelled.contains(request)
    }
}
