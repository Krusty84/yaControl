//
//  StorageDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct BucketDTO: Decodable {
    let folderId: String
    let createdAt: String
    let name: String
    let maxSize: String
}

struct BucketInfoDTO: Decodable {
    let storageClassUsedSizes: [StorageClassUsedSizeDTO]
    let storageClassCounters: [StorageClassCounterDTO]
    let anonymousAccessFlags: AnonymousAccessFlagsDTO
    let name: String
    let maxSize: String
    let usedSize: String
    let defaultStorageClass: String
    let createdAt: String
    let updatedAt: String

    var totalObjectCount: Int {
        storageClassCounters.reduce(0) { result, counter in
            let simpleCount = Int(counter.counters.simpleObjectCount) ?? 0
            let multipartCount = Int(counter.counters.multipartObjectsCount ?? "0") ?? 0
            return result + simpleCount + multipartCount
        }
    }
}

struct StorageClassUsedSizeDTO: Decodable {
    let storageClass: String
    let classSize: String?

    enum CodingKeys: String, CodingKey {
        case storageClass
        case classSize
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        storageClass = try container.decode(String.self, forKey: .storageClass)
        classSize = try container.decodeIfPresent(String.self, forKey: .classSize) ?? "0"
    }
}

struct StorageClassCounterDTO: Decodable {
    let counters: CountersDTO
    let storageClass: String
}

struct CountersDTO: Decodable {
    let simpleObjectSize: String?
    let simpleObjectCount: String
    let multipartObjectsSize: String?
    let multipartObjectsCount: String?

    enum CodingKeys: String, CodingKey {
        case simpleObjectSize
        case simpleObjectCount
        case multipartObjectsSize
        case multipartObjectsCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        simpleObjectSize = try container.decodeIfPresent(String.self, forKey: .simpleObjectSize) ?? "0"
        simpleObjectCount = try container.decode(String.self, forKey: .simpleObjectCount)
        multipartObjectsSize = try container.decodeIfPresent(String.self, forKey: .multipartObjectsSize) ?? "0"
        multipartObjectsCount = try container.decodeIfPresent(String.self, forKey: .multipartObjectsCount) ?? "0"
    }
}

struct AnonymousAccessFlagsDTO: Decodable {
    let read: Bool
    let list: Bool
    let configRead: Bool
}
