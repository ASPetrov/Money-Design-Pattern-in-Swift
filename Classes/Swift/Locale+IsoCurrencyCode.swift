//
//  Locale+IsoCurrencyCode.swift
//  MoneyFramework
//
//  Created by Aleksandar Sergeev Petrov on 19.04.20.
//  Copyright © 2020 Aleksandar Petrov. All rights reserved.
//

import Foundation

public extension Locale {
    static func locale(for isoCurrencyCode: String) -> Locale? {
        guard Locale.isoCurrencyCodes.contains(isoCurrencyCode) else {
            return nil
        }

        guard let availableLocale = Locale.availableLocales(for: isoCurrencyCode).first else {
            let localeComponents = [NSLocale.Key.currencyCode.rawValue: isoCurrencyCode]
            let localeIdentifier = Locale.identifier(fromComponents: localeComponents)
            let canonical = Locale.canonicalIdentifier(from: localeIdentifier)
            return Locale(identifier: canonical)
        }

        let canonical = Locale.canonicalIdentifier(from: availableLocale.identifier)
        return Locale(identifier: canonical)
    }

    private static func availableLocales(for currencyCode: String) -> [Locale] {
        return Locale.availableIdentifiers
            .map { Locale(identifier:$0) }
            .filter { $0.currencyCode == currencyCode }
    }

//    private static func preferredLocaleIdentifier() -> String {
//        guard let preferredIdentifier = Locale.preferredLanguages.first else {
//            return Locale.current.identifier
//        }
//        return preferredIdentifier
//    }
}
