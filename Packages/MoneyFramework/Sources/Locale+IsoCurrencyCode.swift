//
//  Locale+IsoCurrencyCode.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 19.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

extension Locale {

    private static let sortedIdentifiers = Locale.availableIdentifiers.sorted()

    public static func locale(for isoCurrencyCode: String) -> Locale? {
        guard Locale.isoCurrencyCodes.contains(isoCurrencyCode) else {
            return nil
        }

        if isoCurrencyCode == "USD" {
            return Locale(identifier: "en_US")
        }

        guard
            let availableLocale = Locale.firstLocale(for: isoCurrencyCode)
        else {
            let localeComponents = [
                NSLocale.Key.currencyCode.rawValue: isoCurrencyCode,
            ]
            let localeIdentifier = Locale.identifier(
                fromComponents: localeComponents
            )
            let canonical = Locale.canonicalIdentifier(from: localeIdentifier)
            return Locale(identifier: canonical)
        }

        let canonical = Locale.canonicalIdentifier(from: availableLocale.identifier)
        return Locale(identifier: canonical)
    }

    private static func firstLocale(for currencyCode: String) -> Locale? {
        sortedIdentifiers.lazy
            .map { Locale(identifier: $0) }
            .first { $0.currencyCode == currencyCode }
    }
}
