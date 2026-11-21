import Foundation
import MoneyFramework
import Testing

struct MoneySendableTests {

    @Test func testMoneyCrossesActorsWithBuiltInUnits() async throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let token = try #require(CustomCurrency(
            identifier: .asset(network: "example", reference: "native"),
            code: "TOK",
            name: "Token",
            minorUnits: 8
        ))
        let euros = try Money(validating: Amount(integer: 12), currency: currency)
        let tokens = try Money(validating: Amount(minorUnits: 1, scale: 8), currency: token)
        let euroStore = MoneyStore(euros)
        let tokenStore = MoneyStore(tokens)

        #expect(await euroStore.read() == euros)
        #expect(await tokenStore.read() == tokens)
    }
}

private actor MoneyStore<Value: Sendable> {
    private let value: Value

    init(_ value: Value) {
        self.value = value
    }

    func read() -> Value { value }
}
