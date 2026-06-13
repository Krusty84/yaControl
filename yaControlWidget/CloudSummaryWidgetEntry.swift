//
//  CloudSummaryWidgetEntry.swift
//  yaControlWidget
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation
import WidgetKit

struct CloudSummaryWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CloudSummarySnapshot?
    let isPlaceholder: Bool

    static let placeholder = CloudSummaryWidgetEntry(
        date: .now,
        snapshot: .placeholder,
        isPlaceholder: true
    )

    static func noData(date: Date = .now) -> CloudSummaryWidgetEntry {
        CloudSummaryWidgetEntry(
            date: date,
            snapshot: nil,
            isPlaceholder: false
        )
    }
}
