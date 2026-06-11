//
//  LocalizedStringHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum LocalizedStringHelper {
    static func string(_ key: String, locale: Locale) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .main,
            locale: locale
        )
    }

    static func string(_ key: String, language: AppLanguage) -> String {
        string(key, locale: language.locale)
    }

    static func formatted(
        _ key: String,
        locale: Locale,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key, locale: locale),
            locale: locale,
            arguments: arguments
        )
    }

    static func formatted(
        _ key: String,
        language: AppLanguage,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key, language: language),
            locale: language.locale,
            arguments: arguments
        )
    }
}
