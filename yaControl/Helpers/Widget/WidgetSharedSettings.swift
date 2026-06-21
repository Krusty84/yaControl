//
//  WidgetSharedSettings.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 21/06/2026.
//

import Foundation

enum WidgetSharedSettings {
    static let minimumRefreshIntervalMinutes = 5
    static let defaultRefreshIntervalMinutes = 30

    private static let refreshIntervalMinutesKey =
        "com.krusty84.yaControl.settings.widgetRefreshIntervalMinutes"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.identifier)
    }

    static var refreshIntervalMinutes: Int {
        get {
            guard let defaults,
                  defaults.object(forKey: refreshIntervalMinutesKey) != nil else {
                return defaultRefreshIntervalMinutes
            }

            return max(
                defaults.integer(forKey: refreshIntervalMinutesKey),
                minimumRefreshIntervalMinutes
            )
        }

        set {
            let validatedValue = max(
                newValue,
                minimumRefreshIntervalMinutes
            )

            defaults?.set(
                validatedValue,
                forKey: refreshIntervalMinutesKey
            )
        }
    }
}
