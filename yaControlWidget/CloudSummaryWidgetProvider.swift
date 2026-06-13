//
//  CloudSummaryWidgetProvider.swift
//  yaControlWidget
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation
import WidgetKit

struct CloudSummaryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CloudSummaryWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CloudSummaryWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }

        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CloudSummaryWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 45, to: .now) ?? .now.addingTimeInterval(2700)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> CloudSummaryWidgetEntry {
        do {
            guard let snapshot = try CloudSummarySnapshotStore.shared.load() else {
                return .noData()
            }

            return CloudSummaryWidgetEntry(
                date: .now,
                snapshot: snapshot,
                isPlaceholder: false
            )
        } catch {
            return .noData()
        }
    }
}
