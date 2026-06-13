//
//  CloudSummarySnapshotStore.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation

struct CloudSummarySnapshotStore: Sendable {
    static let shared = CloudSummarySnapshotStore()

    func save(_ snapshot: CloudSummarySnapshot) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        let fileURL = try snapshotURL()
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> CloudSummarySnapshot? {
        let fileManager = FileManager.default
        let fileURL = try snapshotURL()
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let decoder = JSONDecoder()
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(CloudSummarySnapshot.self, from: data)
    }

    private func snapshotURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroupConfig.identifier
        ) else {
            throw CloudSummarySnapshotStoreError.missingAppGroupContainer
        }

        return containerURL.appending(path: "cloud-summary-snapshot.json")
    }
}

enum CloudSummarySnapshotStoreError: LocalizedError {
    case missingAppGroupContainer

    var errorDescription: String? {
        switch self {
        case .missingAppGroupContainer:
            "App Group container is unavailable."
        }
    }
}
