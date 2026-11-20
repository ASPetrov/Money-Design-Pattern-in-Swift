//
//  MoneyAllocationTests.swift
//  iTestMoneyDesignPatternSwift
//
//  Created by Aleksandar Petrov on 7/27/15.
//  Copyright (c) 2015 Aleksandar Petrov. All rights reserved.
//

import Foundation
import MoneyFramework
import XCTest

final class MoneyAllocationTests: XCTestCase {
    func testAllocateToRecepients() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "0.05")!
        let money = Money(amount: amount, currency: currency)!
        // When
        let array = money.allocate(2)
        // Then
        XCTAssertEqual(
            array[0].amount,
            Decimal(string: "0.03"),
            "First recepient should have 0.03"
        )
        XCTAssertEqual(
            array[1].amount,
            Decimal(string: "0.02"),
            "Second recepient should have 0.02"
        )
    }

    // TODO: Test Allocate to Zero Recepients (throws "Division by zero")

    func testAllocateToRecepientsUsingRatios() {
        // Given
        let currency = LocaleCurrency(isoCurrencyCode: "EUR")!
        let amount = Decimal(string: "1")!
        let money = Money(amount: amount, currency: currency)!
        // When
        let array = money.allocate([70, 30])
        // Then
        XCTAssertEqual(
            array[0].amount,
            Decimal(string: "0.70"),
            "First recepient should have 0.70"
        )
        XCTAssertEqual(
            array[1].amount,
            Decimal(string: "0.30"),
            "Second recepient should have 0.30"
        )
    }

    func testCheckedEqualAllocationConservesPositiveNegativeAndZeroAmounts() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        for units in [3, -3, 0] {
            let value = try Amount(minorUnits: units, scale: 2)
            let money = try XCTUnwrap(Money(value: value, currency: currency, roundingMode: .plain))
            let shares = try money.allocate(recipientCount: 2)
            let expected = [units / 2 + units % 2, units / 2]
            XCTAssertEqual(try shares.map { try $0.checkedMinorUnits() }, expected)
            XCTAssertTrue(shares.allSatisfy { $0.currency == currency })
        }
    }

    func testCheckedWeightedAllocationSkipsZeroWeightsAndHandlesIntMin() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let value = try Amount(minorUnits: Int.min, scale: 2)
        let money = try XCTUnwrap(Money(value: value, currency: currency))
        let shares = try money.allocate(ratios: [0, Int.max, Int.max])

        XCTAssertEqual(try shares.map { try $0.checkedMinorUnits() }, [0, Int.min / 2, Int.min / 2])
        let small = try XCTUnwrap(Money(amount: "0.03", currency: currency))
        let weighted = try small.allocate(ratios: [0, 1, 1])
        XCTAssertEqual(try weighted.map { try $0.checkedMinorUnits() }, [0, 2, 1])
        XCTAssertEqual(money.amount(from: Int.min), value.decimalValue)
    }

    func testCheckedAllocationRejectsInvalidInputsAndUnrepresentableMinorUnits() throws {
        let currency = try XCTUnwrap(LocaleCurrency(localeIdentifier: "en_US"))
        let money = try XCTUnwrap(Money(amount: Decimal(1), currency: currency))

        for count in [0, Int.max] {
            XCTAssertThrowsError(try money.allocate(recipientCount: count)) {
                XCTAssertEqual($0 as? Money<LocaleCurrency>.ArithmeticError, .invalidRecipientCount)
            }
        }
        let invalidRatios: [([Int], Money<LocaleCurrency>.ArithmeticError)] = [
            ([], .invalidRecipientCount),
            ([0, 0], .invalidRatios),
            ([-1, 2], .invalidRatios),
            ([Int.max, Int.max, Int.max], .totalWeightOutOfRange),
        ]
        for (ratios, expected) in invalidRatios {
            XCTAssertThrowsError(try money.allocate(ratios: ratios), "Ratios: \(ratios)") {
                XCTAssertEqual($0 as? Money<LocaleCurrency>.ArithmeticError, expected)
            }
        }
        let large = try XCTUnwrap(Money(amount: Decimal(Int.max), currency: currency))
        XCTAssertThrowsError(try large.checkedMinorUnits()) {
            XCTAssertEqual($0 as? Amount.ValidationError, .minorUnitsOutOfRange)
        }
        XCTAssertThrowsError(try large.allocate(recipientCount: 2)) {
            XCTAssertEqual($0 as? Amount.ValidationError, .minorUnitsOutOfRange)
        }
    }
}
