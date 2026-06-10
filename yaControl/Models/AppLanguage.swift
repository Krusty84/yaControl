//
//  AppLanguage.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 10/06/2026.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case russian = "ru"
    case kazakh = "kk"

    var id: String { rawValue }

    var displayName: String {
        LocalizedStringHelper.string(displayNameKey, language: SettingsManager.shared.appLanguage)
    }

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

    private var displayNameKey: String {
        switch self {
        case .system:
            L10n.Settings.languageSystem
        case .english:
            L10n.Settings.languageEnglish
        case .russian:
            L10n.Settings.languageRussian
        case .kazakh:
            L10n.Settings.languageKazakh
        }
    }
}
