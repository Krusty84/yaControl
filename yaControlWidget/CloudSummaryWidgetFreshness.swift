//
//  CloudSummaryWidgetFreshness.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 20/06/2026.
//

import Foundation

enum CloudSummaryWidgetFreshness {
    static let staleInterval: TimeInterval = 60 * 60

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
