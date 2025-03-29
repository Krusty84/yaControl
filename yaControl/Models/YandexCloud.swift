//
//  YandexCloud.swift - Yandex Cloud API Data Structure
//  yaControl
//
//  Created by Sedoykin Alexey on 20/02/2025.
//

import Foundation

// Model for Cloud
struct Cloud: Decodable {
    let id: String
    let createdAt: String
    let name: String
    let organizationId: String
}

// Model for Folder
struct Folder: Decodable {
    let id: String
    let cloudId: String
    let createdAt: String
    let name: String
    let status: String
}

// Model for VM Instance
struct VMInstance: Decodable {
    struct Resources: Decodable {
        let memory: String
        let cores: String
        let coreFraction: String
    }
    
    struct NetworkInterface: Decodable {
        struct PrimaryV4Address: Decodable {
            let address: String
            let oneToOneNat: OneToOneNat?
        }
        
        struct OneToOneNat: Decodable {
            let address: String? // Make this optional
            let ipVersion: String?
        }
        
        let primaryV4Address: PrimaryV4Address
        let index: String
        let macAddress: String
        let subnetId: String
    }
    
    struct SchedulingPolicy: Decodable {
        let preemptible: Bool
    }
    
    let resources: Resources
    let networkInterfaces: [NetworkInterface]
    let schedulingPolicy: SchedulingPolicy
    let id: String
    let folderId: String
    let createdAt: String
    let name: String
    let status: String
}

// Model for Final VM Table Data
struct VMTableData:Decodable,Identifiable,Equatable {
    let id: String
    let name: String
    let status: String
    let createdAt: String
    let cores: String
    let memoryGB: String
    let preemptible: Bool
    let addresses: [String]
    let folderName: String
    let folderUrl: URL?
    let vmUrl: URL?
    var isAutoStarted: Bool
}

// Model for Functions
struct ServerLessFunction: Decodable {
    let id: String
    let folderId: String
    let createdAt: String
    let name: String
    let httpInvokeUrl: String
    let status: String
}

// Model for Final Functions Table Data
struct ServerLessFunctionTableData:Decodable,Identifiable,Equatable {
    let id: String
    let name: String
    let status: String
    let createdAt: String
    let folderName: String
    let folderUrl: URL?
    let httpInvokeUrl: String
    let slfUrl: URL?
}

// Model for Buckets
struct Bucket: Decodable {
   // let id: Int
    let folderId: String
    let createdAt: String
    let name: String
    let maxSize: String
}

struct BucketInfo: Decodable {
    let storageClassUsedSizes: [StorageClassUsedSize]
    let storageClassCounters: [StorageClassCounter]
    let anonymousAccessFlags: AnonymousAccessFlags
    let name: String
    let maxSize: String
    let usedSize: String
    let defaultStorageClass: String
    let createdAt: String
    let updatedAt: String
    
    // Computed property to get the total object count
    var totalObjectCount: Int {
        storageClassCounters.reduce(0) { result, counter in
            let simpleCount = Int(counter.counters.simpleObjectCount) ?? 0
            let multipartCount = Int(counter.counters.multipartObjectsCount ?? "0") ?? 0 // Handle optional multipartObjectsCount
            return result + simpleCount + multipartCount
        }
    }
}

struct StorageClassUsedSize: Decodable {
    let storageClass: String
    let classSize: String? // Make classSize optional
    
    // Provide a default value if classSize is missing
    enum CodingKeys: String, CodingKey {
        case storageClass
        case classSize
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.storageClass = try container.decode(String.self, forKey: .storageClass)
        self.classSize = try container.decodeIfPresent(String.self, forKey: .classSize) ?? "0" // Default to "0" if missing
    }
}

struct StorageClassCounter: Decodable {
    let counters: Counters
    let storageClass: String
}

struct Counters: Decodable {
    let simpleObjectSize: String?
    let simpleObjectCount: String
    let multipartObjectsSize: String?
    let multipartObjectsCount: String? // Make multipartObjectsCount optional
    
    // Provide default values if fields are missing
    enum CodingKeys: String, CodingKey {
        case simpleObjectSize
        case simpleObjectCount
        case multipartObjectsSize
        case multipartObjectsCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.simpleObjectSize = try container.decodeIfPresent(String.self, forKey: .simpleObjectSize) ?? "0" // Default to "0"
        self.simpleObjectCount = try container.decode(String.self, forKey: .simpleObjectCount)
        self.multipartObjectsSize = try container.decodeIfPresent(String.self, forKey: .multipartObjectsSize) ?? "0" // Default to "0"
        self.multipartObjectsCount = try container.decodeIfPresent(String.self, forKey: .multipartObjectsCount) ?? "0" // Default to "0"
    }
}

struct AnonymousAccessFlags: Decodable {
    let read: Bool
    let list: Bool
    let configRead: Bool
}

// Model for Final Buckets Table Data
struct BucketTableData:Decodable,Identifiable,Equatable {
    let id: UUID
    let name: String
    let maxSize: String
    let usedSize: String
    let totalObjectCount: Int
    let createdAt: String
    let updatedAt: String
    let folderName: String
    let folderUrl: URL?
    let bucketUrl: URL?
    // Computed property to convert totalObjectCount to String
    var totalObjectCountString: String {
            String(totalObjectCount)
    }
}


// Model for VM Instance
struct Billing: Decodable {
    let id: String
    let currency: String
    let balance: String
}

struct BillingTableData: Decodable,Identifiable,Equatable {
    let id: UUID
    let currency: String
    let balance: String
    let billingUrl: URL?
}

/*
 "id": "d4e38851c0ofsnkki9f7",
 "folderId": "b1gqcrohfu85p2fc6fkc",
 "createdAt": "2022-04-21T19:56:18.176Z",
 "name": "teamcenter-alice",
 "httpInvokeUrl": "https://functions.yandexcloud.net/d4e38851c0ofsnkki9f7",
 "status": "ACTIVE"
 */

//https://console.yandex.cloud/folders/b1gqcrohfu85p2fc6fkc/compute/instance/epddn33ae5rr4ep7to3i/overview
