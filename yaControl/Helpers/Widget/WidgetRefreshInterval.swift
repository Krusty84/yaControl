//
//  WidgetRefreshInterval.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 14/06/2026.
//

import Foundation

enum WidgetRefreshInterval: Int, CaseIterable, Identifiable {
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case threeHours = 180

    var id: Int { rawValue }

    func localizedTitle(locale: Locale) -> String {
        LocalizedStringHelper.string(localizationKey, locale: locale)
    }

    private var localizationKey: String {
        switch self {
        case .fiveMinutes:
            L10n.Settings.widgetIntervalFiveMinutes
        case .fifteenMinutes:
            L10n.Settings.widgetIntervalFifteenMinutes
        case .thirtyMinutes:
            L10n.Settings.widgetIntervalThirtyMinutes
        case .oneHour:
            L10n.Settings.widgetIntervalOneHour
        case .threeHours:
            L10n.Settings.widgetIntervalThreeHours
        }
    }
}
