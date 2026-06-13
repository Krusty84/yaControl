//
//  CloudSummarySnapshotRefreshScheduler.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 14/06/2026.
//

import Foundation

@MainActor
final class CloudSummarySnapshotRefreshScheduler {
    static let shared = CloudSummarySnapshotRefreshScheduler()

    private var refreshTask: Task<Void, Never>?

    private init() {}

    func start() {
        stop()

        guard SettingsManager.shared.widgetAutoRefreshEnabled else {
            return
        }

        let intervalMinutes = max(SettingsManager.shared.widgetRefreshIntervalMinutes, 5)
        let intervalSeconds = intervalMinutes * 60

        refreshTask = Task {
            while !Task.isCancelled {
                await CloudSummarySnapshotUpdater.shared.refreshSnapshot()

                do {
                    try await Task.sleep(for: .seconds(intervalSeconds))
                } catch {
                    return
                }
            }
        }
    }

    func restart() {
        start()
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
