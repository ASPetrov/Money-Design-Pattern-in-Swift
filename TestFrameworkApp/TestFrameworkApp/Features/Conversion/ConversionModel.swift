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
        didSet {
            if amountText != oldValue {
                cancelConversion()
            }
        }
    }

    @Published var source: DemoCurrency = .usd {
        didSet {
            if source != oldValue {
                cancelConversion()
            }
        }
    }

    @Published var destination: DemoCurrency = .eur {
        didSet {
            if destination != oldValue {
                cancelConversion()
            }
        }
    }

    @Published private(set) var state: State = .idle

    let locale: Locale
    private let rateProvider: any ExchangeRateProviding
    private var activeRequest: UUID?
    private var conversionTask: Task<Void, Never>?

    init(rateProvider: any ExchangeRateProviding, locale: Locale = .current) {
        self.rateProvider = rateProvider
        self.locale = locale
    }

    deinit {
        conversionTask?.cancel()
    }

    @discardableResult
    func convert() -> Task<Void, Never>? {
        cancelConversion()
        let source = source
        let destination = destination
        guard
            let sourceCurrency = source.definition,
            let destinationCurrency = destination.definition
        else {
            state = .failed(.rateUnavailable)
            return nil
        }

        let money: Money<LocaleCurrency>
        do {
            let amount = try Amount(localizedString: amountText, locale: locale)
            money = try Money(validating: amount, currency: sourceCurrency)
        } catch {
            state = .failed(.invalidAmount)
            return nil
        }

        if source == destination {
            state = .converted(money)
            return nil
        }

        let request = UUID()
        activeRequest = request
        state = .loading
        let task = Task { [weak self, rateProvider] in
            do {
                try Task.checkCancellation()
                let rate = try await rateProvider.rate(
                    from: source,
                    to: destination
                )
                try Task.checkCancellation()
                let result = try money.convertTo(
                    destinationCurrency,
                    usingExchangeRate: rate
                )
                self?.finish(request, with: .converted(result))
            } catch is CancellationError {
                self?.finish(request, with: .idle)
            } catch {
                self?.finish(
                    request,
                    with: Task.isCancelled ? .idle : .failed(.rateUnavailable)
                )
            }
        }
        conversionTask = task
        return task
    }

    func cancelConversion() {
        activeRequest = nil
        conversionTask?.cancel()
        conversionTask = nil
        state = .idle
    }

    private func finish(_ request: UUID, with result: State) {
        guard activeRequest == request else {
            return
        }
        activeRequest = nil
        conversionTask = nil
        state = result
    }
}
