//
//  LocalizedStringHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum LocalizedStringHelper {

    static func string(_ key: String, locale: Locale) -> String {
        let bundle = bundle(for: locale)
        return bundle.localizedString(
            forKey: key,
            value: key,
            table: "Localizable"
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

    private static func bundle(for locale: Locale) -> Bundle {
        let languageCode = locale.language.languageCode?.identifier ?? locale.identifier
        guard
            let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }
}
