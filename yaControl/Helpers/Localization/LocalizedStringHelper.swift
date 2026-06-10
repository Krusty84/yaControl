//
//  LocalizedStringHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum LocalizedStringHelper {
    static func string(_ key: String, language: AppLanguage) -> String {
        if let localeIdentifier = language.localeIdentifier {
            return String(
                localized: String.LocalizationValue(key),
                bundle: .main,
                locale: Locale(identifier: localeIdentifier)
            )
        }

        return String(localized: String.LocalizationValue(key), bundle: .main)
    }
}
