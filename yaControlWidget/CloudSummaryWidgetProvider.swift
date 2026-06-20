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

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<CloudSummaryWidgetEntry>) -> Void
    ) {
        let now = Date.now
        let currentEntry = loadEntry(date: now)

        var entries = [currentEntry]
        var nextUpdate = now.addingTimeInterval(45 * 60)

        if let snapshot = currentEntry.snapshot,
           snapshot.errorMessage == nil {

            let staleDate = CloudSummaryWidgetFreshness.staleDate(
                for: snapshot
            )

            if staleDate > now {
                let staleEntry = CloudSummaryWidgetEntry(
                    date: staleDate,
                    snapshot: snapshot,
                    isPlaceholder: false
                )

                entries.append(staleEntry)
                nextUpdate = max(nextUpdate, staleDate)
            }
        }

        completion(
            Timeline(
                entries: entries,
                policy: .after(nextUpdate)
            )
        )
    }

    private func loadEntry(
        date: Date = .now
    ) -> CloudSummaryWidgetEntry {
        do {
            guard let snapshot = try CloudSummarySnapshotStore.shared.load() else {
                return .noData(date: date)
            }

            return CloudSummaryWidgetEntry(
                date: date,
                snapshot: snapshot,
                isPlaceholder: false
            )
        } catch {
            let snapshot = CloudSummarySnapshot(
                currentBalance: "—",
                currency: "",
                totalVMsCount: 0,
                runningVMsCount: 0,
                totalFunctionsCount: 0,
                activeFunctionsCount: 0,
                totalBucketsCount: 0,
                lastUpdated: date,
                errorMessage: error.localizedDescription
            )

            return CloudSummaryWidgetEntry(
                date: date,
                snapshot: snapshot,
                isPlaceholder: false
            )
        }
    }
}
