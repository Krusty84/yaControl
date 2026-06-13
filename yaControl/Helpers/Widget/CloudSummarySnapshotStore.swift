//
//  CloudSummarySnapshotStore.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation

struct CloudSummarySnapshotStore: Sendable {
    static let shared = CloudSummarySnapshotStore()

    private let snapshotKey = "com.krusty84.yaControl.widget.cloudSummarySnapshot"

    func save(_ snapshot: CloudSummarySnapshot) throws {
        guard let defaults = UserDefaults(suiteName: AppGroupConfig.identifier) else {
            throw CloudSummarySnapshotStoreError.missingAppGroupDefaults
        }

        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: snapshotKey)

        // Useful for widget handoff after immediate refresh.
        defaults.synchronize()
    }

    func load() throws -> CloudSummarySnapshot? {
        guard let defaults = UserDefaults(suiteName: AppGroupConfig.identifier) else {
            throw CloudSummarySnapshotStoreError.missingAppGroupDefaults
        }

        guard let data = defaults.data(forKey: snapshotKey) else {
            return nil
        }

        return try JSONDecoder().decode(CloudSummarySnapshot.self, from: data)
    }

    func clear() throws {
        guard let defaults = UserDefaults(suiteName: AppGroupConfig.identifier) else {
            throw CloudSummarySnapshotStoreError.missingAppGroupDefaults
        }

        defaults.removeObject(forKey: snapshotKey)
        defaults.synchronize()
    }
}

enum CloudSummarySnapshotStoreError: LocalizedError {
    case missingAppGroupDefaults

    var errorDescription: String? {
        switch self {
        case .missingAppGroupDefaults:
            "App Group UserDefaults is unavailable."
        }
    }
}
