//
//  MoneyAllocationTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import Testing

struct MoneyAllocationTests {
    @Test func testAllocateToRecepients() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "0.05"))
        let money = try #require(Money(amount: amount, currency: currency))
        // When
        let array = money.allocate(2)
        // Then
        #expect(array[0].amount == Decimal(string: "0.03"), "First recepient should have 0.03")
        #expect(array[1].amount == Decimal(string: "0.02"), "Second recepient should have 0.02")
    }

    // TODO: Test Allocate to Zero Recepients (throws "Division by zero")

    @Test func testAllocateToRecepientsUsingRatios() throws {
        // Given
        let currency = try #require(LocaleCurrency(isoCurrencyCode: "EUR"))
        let amount = try #require(Decimal(string: "1"))
        let money = try #require(Money(amount: amount, currency: currency))
        // When
        let array = money.allocate([70, 30])
        // Then
        #expect(array[0].amount == Decimal(string: "0.70"), "First recepient should have 0.70")
        #expect(array[1].amount == Decimal(string: "0.30"), "Second recepient should have 0.30")
    }

    @Test func testCheckedEqualAllocationConservesPositiveNegativeAndZeroAmounts() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        for units in [3, -3, 0] {
            let value = try Amount(minorUnits: units, scale: 2)
            let money = try #require(Money(value: value, currency: currency, roundingMode: .plain))
            let shares = try money.allocate(recipientCount: 2)
            let expected = [units / 2 + units % 2, units / 2]
            #expect(try shares.map { try $0.checkedMinorUnits() } == expected)
            #expect(shares.allSatisfy { $0.currency == currency })
        }
    }

    @Test func testCheckedWeightedAllocationSkipsZeroWeightsAndHandlesIntMin() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let value = try Amount(minorUnits: Int.min, scale: 2)
        let money = try #require(Money(value: value, currency: currency))
        let shares = try money.allocate(ratios: [0, Int.max, Int.max])

        #expect(try shares.map { try $0.checkedMinorUnits() } == [0, Int.min / 2, Int.min / 2])
        let small = try #require(Money(amount: "0.03", currency: currency))
        let weighted = try small.allocate(ratios: [0, 1, 1])
        #expect(try weighted.map { try $0.checkedMinorUnits() } == [0, 2, 1])
        #expect(money.amount(from: Int.min) == value.decimalValue)
    }

    @Test func testCheckedAllocationRejectsInvalidInputsAndUnrepresentableMinorUnits() throws {
        let currency = try #require(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try #require(Money(amount: Decimal(1), currency: currency))

        for count in [0, Int.max] {
            #expect(throws: Money<LocaleCurrency>.ArithmeticError.invalidRecipientCount) {
                _ = try money.allocate(recipientCount: count)
            }
        }
        let invalidRatios: [([Int], Money<LocaleCurrency>.ArithmeticError)] = [
            ([], .invalidRecipientCount),
            ([0, 0], .invalidRatios),
            ([-1, 2], .invalidRatios),
            ([Int.max, Int.max, Int.max], .totalWeightOutOfRange),
        ]
        for (ratios, expected) in invalidRatios {
            #expect(throws: expected) {
                _ = try money.allocate(ratios: ratios)
            }
        }
        let large = try #require(Money(amount: Decimal(Int.max), currency: currency))
        #expect(throws: Amount.ValidationError.minorUnitsOutOfRange) {
            _ = try large.checkedMinorUnits()
        }
        #expect(throws: Amount.ValidationError.minorUnitsOutOfRange) {
            _ = try large.allocate(recipientCount: 2)
        }
    }
}
