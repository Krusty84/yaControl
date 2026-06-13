//
//  BucketTableData.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct BucketTableData: Decodable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let maxSize: String
    let usedSize: String
    let totalObjectCount: Int
    let createdAt: String
    let updatedAt: String
    let folderId: String
    let folderName: String
    let folderUrl: URL?
    let bucketUrl: URL?

    var totalObjectCountString: String {
        String(totalObjectCount)
    }
}
