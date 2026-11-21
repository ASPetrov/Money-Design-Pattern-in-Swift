import SwiftUI

struct ConversionView: View {

    @ObservedObject private var model: ConversionModel
    @FocusState private var isAmountFocused: Bool

    init(model: ConversionModel) {
        self.model = model
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Amount", text: $model.amountText)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .accessibilityIdentifier("conversion-amount")
                    currencyPicker("From", selection: $model.source)
                    currencyPicker("To", selection: $model.destination)
                    Button("Convert") {
                        isAmountFocused = false
                        model.convert()
                    }
                    .disabled(model.state == .loading)
                    .accessibilityIdentifier("convert")
                } header: {
                    Text("Conversion")
                } footer: {
                    Text("Uses sample rates. No network connection is needed.")
                }

                if model.state != .idle {
                    Section("Result") {
                        result
                    }
                }
            }
            .navigationTitle("Currency Converter")
        }
        .navigationViewStyle(.stack)
        .onDisappear { model.cancelConversion() }
    }

    @ViewBuilder
    private var result: some View {
        switch model.state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView("Converting…")
        case let .converted(money):
            if let text = money.formatted(locale: model.locale) {
                Text(text)
                    .font(.title2)
                    .accessibilityIdentifier("conversion-result")
            } else {
                Text("Could not format the converted amount.")
            }
        case .failed(.invalidAmount):
            Text("Enter a valid amount.")
        case .failed(.rateUnavailable):
            Text("Conversion is unavailable for this currency pair.")
        }
    }

    private func currencyPicker(_ title: LocalizedStringKey, selection: Binding<DemoCurrency>) -> some View {
        Picker(title, selection: selection) {
            ForEach(DemoCurrency.allCases, id: \.self) { currency in
                Text(currency.rawValue).tag(currency)
            }
        }
    }
}
