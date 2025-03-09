//
//  YandexCloud.swift
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

// Model for Final VM Table Data
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

/*
 "id": "d4e38851c0ofsnkki9f7",
 "folderId": "b1gqcrohfu85p2fc6fkc",
 "createdAt": "2022-04-21T19:56:18.176Z",
 "name": "teamcenter-alice",
 "httpInvokeUrl": "https://functions.yandexcloud.net/d4e38851c0ofsnkki9f7",
 "status": "ACTIVE"
 */

//https://console.yandex.cloud/folders/b1gqcrohfu85p2fc6fkc/compute/instance/epddn33ae5rr4ep7to3i/overview
