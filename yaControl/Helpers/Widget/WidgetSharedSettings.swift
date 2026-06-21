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

    /// Moves the value stored by older versions of the application
    /// from the application-only UserDefaults container to the App Group.
    static func migrateFromStandardDefaults(
        _ standardDefaults: UserDefaults = .standard
    ) {
        guard let sharedDefaults = defaults else {
            return
        }

        // Do not overwrite an existing App Group value.
        guard sharedDefaults.object(
            forKey: refreshIntervalMinutesKey
        ) == nil else {
            return
        }

        // There is nothing to migrate for a new installation.
        guard standardDefaults.object(
            forKey: refreshIntervalMinutesKey
        ) != nil else {
            return
        }

        let legacyValue = max(
            standardDefaults.integer(
                forKey: refreshIntervalMinutesKey
            ),
            minimumRefreshIntervalMinutes
        )

        sharedDefaults.set(
            legacyValue,
            forKey: refreshIntervalMinutesKey
        )

        standardDefaults.removeObject(
            forKey: refreshIntervalMinutesKey
        )
    }
}
