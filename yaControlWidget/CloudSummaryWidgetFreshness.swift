//
//  CloudSummaryWidgetFreshness.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 20/06/2026.
//

import Foundation

enum CloudSummaryWidgetFreshness {
    private static let refreshGracePeriod: TimeInterval = 60

    static var staleInterval: TimeInterval {
        TimeInterval(
            WidgetSharedSettings.refreshIntervalMinutes
        ) * 60 + refreshGracePeriod
    }

    static func staleDate(
        for snapshot: CloudSummarySnapshot
    ) -> Date {
        snapshot.lastUpdated.addingTimeInterval(staleInterval)
    }

    static func isStale(
        _ snapshot: CloudSummarySnapshot,
        at date: Date
    ) -> Bool {
        date >= staleDate(for: snapshot)
    }
}
