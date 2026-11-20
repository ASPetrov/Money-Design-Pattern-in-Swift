//
//  Locale+IsoCurrencyCode.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 19.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

extension Locale {
    public static func locale(for isoCurrencyCode: String) -> Locale? {
        guard Locale.isoCurrencyCodes.contains(isoCurrencyCode) else {
            return nil
        }

        if isoCurrencyCode == "USD" {
            return Locale(identifier: "en_US")
        }

        guard
            let availableLocale = Locale.availableLocales(for: isoCurrencyCode).first
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

    private static func availableLocales(for currencyCode: String) -> [Locale] {
        Locale.availableIdentifiers
            .sorted()
            .map { Locale(identifier: $0) }
            .filter { $0.currencyCode == currencyCode }
    }

}
