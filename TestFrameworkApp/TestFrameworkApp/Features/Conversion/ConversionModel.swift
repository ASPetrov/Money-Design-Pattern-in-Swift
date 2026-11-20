import Combine
import Foundation
import MoneyFramework

enum DemoCurrency: String, CaseIterable, Sendable {
    case usd = "USD"
    case eur = "EUR"
    case bgn = "BGN"

    fileprivate var definition: LocaleCurrency? {
        if self == .bgn {
            return LocaleCurrency(
                code: rawValue,
                name: "Bulgarian Lev",
                minorUnits: 2,
                symbol: "лв.",
                separator: nil,
                delimiter: nil
            )
        }
        return LocaleCurrency(isoCurrencyCode: rawValue)
    }
}

protocol ExchangeRateProviding: Sendable {
    func rate(from source: DemoCurrency, to destination: DemoCurrency) async throws -> Decimal
}

struct SampleRateProvider: ExchangeRateProviding {
    func rate(from source: DemoCurrency, to destination: DemoCurrency) async throws -> Decimal {
        unitsPerSampleDollar(destination) / unitsPerSampleDollar(source)
    }

    private func unitsPerSampleDollar(_ currency: DemoCurrency) -> Decimal {
        switch currency {
        case .usd: 1
        case .eur: Decimal(80) / 100
        case .bgn: Decimal(160) / 100
        }
    }
}

@MainActor
final class ConversionModel: ObservableObject {
    enum Failure: Equatable {
        case invalidAmount
        case rateUnavailable
    }

    enum State: Equatable {
        case idle
        case loading
        case converted(Money<LocaleCurrency>)
        case failed(Failure)
    }

    @Published var amountText = "" {
        didSet { invalidateResult() }
    }

    @Published var source: DemoCurrency = .usd {
        didSet { invalidateResult() }
    }

    @Published var destination: DemoCurrency = .eur {
        didSet { invalidateResult() }
    }

    @Published private(set) var state: State = .idle

    let locale: Locale
    private let rateProvider: any ExchangeRateProviding
    private var activeRequest: UUID?

    init(rateProvider: any ExchangeRateProviding, locale: Locale = .current) {
        self.rateProvider = rateProvider
        self.locale = locale
    }

    func convert() async {
        let source = source
        let destination = destination
        guard
            let sourceCurrency = source.definition,
            let destinationCurrency = destination.definition
        else {
            state = .failed(.rateUnavailable)
            return
        }

        guard
            let amount = try? Amount(localizedString: amountText, locale: locale),
            let money = Money(value: amount, currency: sourceCurrency)
        else {
            state = .failed(.invalidAmount)
            return
        }

        if source == destination {
            state = .converted(money)
            return
        }

        let request = UUID()
        activeRequest = request
        state = .loading
        do {
            let rate = try await rateProvider.rate(from: source, to: destination)
            try Task.checkCancellation()
            let result = try money.convertTo(destinationCurrency, usingExchangeRate: rate)
            finish(request, with: .converted(result))
        } catch is CancellationError {
            finish(request, with: .idle)
        } catch {
            finish(request, with: .failed(.rateUnavailable))
        }
    }

    private func invalidateResult() {
        activeRequest = nil
        state = .idle
    }

    private func finish(_ request: UUID, with result: State) {
        guard activeRequest == request else {
            return
        }
        activeRequest = nil
        state = result
    }
}
