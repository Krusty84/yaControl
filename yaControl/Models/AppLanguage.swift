//
//  AppLanguage.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english = "en"
    case russian = "ru"
    case kazakh = "kk"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            .autoupdatingCurrent
        case .english:
            Locale(identifier: "en")
        case .russian:
            Locale(identifier: "ru")
        case .kazakh:
            Locale(identifier: "kk")
        }
    }

    var localeIdentifier: String? {
        switch self {
        case .system:
            nil
        case .english:
            "en"
        case .russian:
            "ru"
        case .kazakh:
            "kk"
        }
    }

    func displayName(locale: Locale) -> String {
        switch self {
        case .system:
            LocalizedStringHelper.string(L10n.Settings.languageSystem, locale: locale)
        case .english:
            "English"
        case .russian:
            "Русский"
        case .kazakh:
            "Қазақша"
        }
    }
}
