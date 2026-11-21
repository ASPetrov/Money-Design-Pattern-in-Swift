//
//  MoneyTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import Testing

struct MoneyTests {

    //
    // MARK: - Initialization
    //

    @Test func testCanCreateMoney() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        // Implicit Zero amount
        // When
        let money = Money(currency: currency)
        // Then
        #expect(money != nil, "Could not create money")
    }

    @Test func testCanCreateMoneyWithAmountAsDecimal() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = Decimal(1)
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money != nil, "Could not create money with decimal amount")
    }

    @Test func testCanCreateMoneyWithAmountAsString() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = "1"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money != nil, "Could not create money with string amount")
    }

    @Test func testCreatesMoneyFromFormattedAmount() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let amount = "$1"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money != nil, "Could not create money with formatted string amount")
    }

    @Test func testCanNotCreateMoneyWithBadDecimal() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = Decimal.nan
        // When
        let money = Money(amount: amount, currency: currency )
        // Then
        #expect(money == nil, "Could not create money with not a number")
    }

    @Test func testCanNotCreateMoneyWithBadString() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = "Random &^Ugjh2 string"
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money == nil, "Could not create money with random string")
    }

    //
    // MARK: - Test Public Read Only Properties
    //

    @Test func testCanReadCurrency() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "4.23"))
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money?.currency == currency, "Money currency should match")
    }

    @Test func testCanReadAmount() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "4.23"))
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money?.amount == amount, "Money amount should match")
    }

    //
    // MARK: - Test Decimal/amount Facade Methods
    //

    @Test func testIsZeroReturnsTrue() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        // When
        let money = Money(currency: currency)
        // Then
        #expect(money?.amount == .zero, "Money amount should be zero")
    }

    @Test func testIsZeroReturnsFalse() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "4.23"))
        // When
        let money = Money(amount: amount, currency: currency)
        // Then
        #expect(money?.amount != .zero, "Money amount should not be zero")
    }

    @Test func testIsNegativeReturnsTrue() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "-4.23"))
        // When
        let money = try #require(Money(amount: amount, currency: currency))
        // Then
        #expect(money.isNegative, "Money amount should be negative")
    }

    @Test func testIsNegativeReturnsFalse() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "4.23"))
        // When
        let money = try #require(Money(amount: amount, currency: currency))
        // Then
        #expect(!(money.isNegative), "Money amount should not be negative")
    }

    @Test func testIsPositiveReturnsTrue() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "4.23"))
        // When
        let money = try #require(Money(amount: amount, currency: currency))
        // Then
        #expect(money.isPositive, "Money amount should be positive")
    }

    @Test func testIsPositiveReturnsFalse() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "-4.23"))
        // When
        let money = try #require(Money(amount: amount, currency: currency))
        // Then
        #expect(!(money.isPositive), "Money amount should not be positive")
    }

    @Test(arguments: ["0", "0.001", "-0.001"])
    func testZeroIsNotPositive(_ input: String) throws {
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try Amount(decimalString: input)
        let money = try Money(validating: amount, currency: currency)

        #expect(money.isZero)
        #expect(!money.isPositive)
    }

    @Test func testAbsolute() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "-4.23"))
        // When
        let money = try #require(Money(amount: amount, currency: currency))
        // Then
        #expect(!(money.absoluteAmount.isSignMinus), "Money amount should not be positive")
    }

    //
    // MARK: - Test Minor Units Methods
    //

    @Test func testAmountInSubunits() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "4.23"))
        // When
        let money = try #require(Money(amount: amount, currency: currency))
        // Then
        #expect(money.amountInMinorUnits == 423, "Subunits amount should match")
    }

    @Test func testOneSubunit() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let oneMinorUnit = Decimal(string: "0.01")
        // When
        let money = try #require(Money(currency: currency))
        // Then
        #expect(money.oneMinorUnit == oneMinorUnit, "Smallest subunit should match")
    }

    //
    // MARK: - Convert
    //

    @Test func testConvertEurosToDollars() throws {
        // Given
        let EUR = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let USD = try #require(LocaleCurrency(isoCurrencyCode: "USD"))
        let amount = try #require(Decimal(string: "20"))
        let euros = try #require(Money(amount: amount, currency: EUR))
        let exchangeRate = try #require(Decimal(string: "1.1234"))
        // When
        let dollars = try euros.convertTo(USD, usingExchangeRate: exchangeRate)
        // Then
        #expect(dollars.amount == Decimal(string: "22.47"), "Dollars amount should be 22.47")
    }

    //
    // MARK: - Equal
    //

    // opertator == is using equals method (??? - no need to be tested)
    @Test func testEqualAmountsAndCurrenciesAreEqual() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "0.0", currency: currency))
        let moneyRHS = try #require(Money(amount: "0.0", currency: currency))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        #expect(result, "Money should match")
    }

    @Test func testUnequalAmountsInTheSameCurrency() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "0.0", currency: currency))
        let moneyRHS = try #require(Money(amount: "15.0", currency: currency))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        #expect(!(result), "Money should not match")
    }

    @Test func testEqualAmountsInDifferentCurrencies() throws {
        // Given
        let currencyLHS = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let currencyRHS = try #require(LocaleCurrency(localeIdentifier: "fr_TN"))
        let moneyLHS = try #require(Money(amount: "0.0", currency: currencyLHS))
        let moneyRHS = try #require(Money(amount: "0.0", currency: currencyRHS))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        #expect(!(result), "Money should not match")
    }

    @Test func testUnequalAmountsAndCurrencies() throws {
        // Given
        let currencyLHS = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let currencyRHS = try #require(LocaleCurrency(localeIdentifier: "fr_TN"))
        let moneyLHS = try #require(Money(amount: "0.0", currency: currencyLHS))
        let moneyRHS = try #require(Money(amount: "13.33", currency: currencyRHS))
        // When
        let result = moneyLHS.equals(moneyRHS)
        // Then
        #expect(!(result), "Money should not match")
    }

    //
    // MARK: - Comparable
    //

    @Test func testGreaterAmountSortsAfterSmallerAmount() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "15.0", currency: currency))
        let moneyRHS = try #require(Money(amount: "2.0", currency: currency))
        // When
        let result = moneyLHS > moneyRHS
        #expect([moneyLHS, moneyRHS].sorted() == [moneyRHS, moneyLHS])
        // Then
        #expect(result, "Money on the left side should have greater amount than  money on the right side")
    }

    @Test func testSmallerAmountSortsFirst() throws {
        // Given
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let moneyLHS = try #require(Money(amount: "2.0", currency: currency))
        let moneyRHS = try #require(Money(amount: "15.0", currency: currency))
        // When
        let result = moneyLHS < moneyRHS
        // Then
        #expect(result, "Money on the left side should have less amount than  money on the right side")
    }

    @Test func testConversionRoundsAtTargetPrecision() throws {
        let usd = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let jpy = try #require(LocaleCurrency(localeIdentifier: "ja_JP"))
        let money = try #require(Money(amount: Decimal(1), currency: usd, roundingMode: .plain))
        let rate = try #require(Decimal(string: "2.5"))

        let converted = try money.convertTo(jpy, usingExchangeRate: rate, roundingMode: .plain)

        #expect(converted.currency == jpy)
        #expect(converted.amount == Decimal(3))
        #expect(try money.convertTo(jpy, usingExchangeRate: rate).amount == Decimal(2))
    }

    @Test func testExposesRoundedAmountAsDecimal() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let value = try Amount(decimalString: "1.025")
        let money = try #require(Money(value: value, currency: currency, roundingMode: .plain))
        let amount: Decimal = money.amount

        #expect(amount == Decimal(string: "1.03"))
        #expect(money.value.decimalValue == amount)
        #expect(Money(amount: .zero, currency: currency)?.amount == .zero)
        #expect(Money(amount: "1.25", currency: currency)?.amount == Decimal(string: "1.25"))
        #expect(Money(currency: currency)?.amount == .zero)
    }
}
