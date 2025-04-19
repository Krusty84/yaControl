//
//  YandexCloud.swift - Yandex Cloud API Data Structure
//  yaControl
//
//  Created by Sedoykin Alexey on 20/02/2025.
//

import Foundation

//MARK: OAuth
struct AuthResponse {
    let code: Int
    let iamToken: String
    let expiresAt: String
}
enum AuthError: Error {
    case invalidURL
    case invalidPayload
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case invalidResponseFormat
}

//MARK: Cloud
enum CloudError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case invalidResponseFormat
}
struct Cloud: Decodable {
    let id: String
    let createdAt: String
    let name: String
    let organizationId: String
}
struct CloudsResponse {
    let code: Int
    let clouds: [Cloud]
}

//MARK: Folder
enum FolderError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case decodingError
}
struct Folder: Decodable {
    let id: String
    let cloudId: String
    let createdAt: String
    let name: String
    let status: String
}

//MARK: VM
enum VMInstanceError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case apiError(code: Int, message: String)
    case decodingError
    case noInstancesFound
}
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
            let address: String?
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

//Final VM Table Data
enum VMError: Error {
    case cloudFetchFailed
    case folderFetchFailed
    case instanceFetchFailed
    case invalidURL
}
struct VMTableData:Decodable,Identifiable,Equatable {
    let id: String
    let name: String
    var status: String
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

//MARK: Serverless Function
enum ServerlessFunctionError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case apiError(code: Int, message: String)
    case decodingError
}
struct ServerLessFunction: Decodable {
    let id: String
    let folderId: String
    let createdAt: String
    let name: String
    let httpInvokeUrl: String
    let status: String
}
//Final SLF Table Data
enum finalServerlessFunctionError: Error {
    case cloudFetchFailed
    case folderFetchFailed
    case functionFetchFailed
    case invalidURL
}
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

//MARK: Bucket
enum BucketError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case apiError(code: Int, message: String)
    case decodingError
}
struct Bucket: Decodable {
    let folderId: String
    let createdAt: String
    let name: String
    let maxSize: String
}
//BucketInfo
enum BucketInfoError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case decodingError(Error)
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
    
    var totalObjectCount: Int {
        storageClassCounters.reduce(0) { result, counter in
            let simpleCount = Int(counter.counters.simpleObjectCount) ?? 0
            let multipartCount = Int(counter.counters.multipartObjectsCount ?? "0") ?? 0
            return result + simpleCount + multipartCount
        }
    }
}
//Final Bucket Table Data
enum finalBucketError: Error {
    case cloudFetchFailed
    case folderFetchFailed
    case bucketFetchFailed
    case bucketInfoFetchFailed
    case invalidURL
}
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

//MARK: Billing
enum BillingError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noDataReceived
    case apiError(code: Int, message: String)
    case decodingError
}
struct Billing: Decodable {
    let id: String
    let currency: String
    let balance: String
}
//Final Billing Table Data
struct BillingTableData: Decodable,Identifiable,Equatable {
    let id: UUID
    let currency: String
    let balance: String
    let billingUrl: URL?
}

//MARK: VM Start/Stop/Get
enum VMOperationError: Error {
    case invalidURL
    case apiError(statusCode: Int)
    case operationFailed
}

