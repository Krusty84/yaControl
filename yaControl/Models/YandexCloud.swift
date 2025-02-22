//
//  YandexCloud.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 20/02/2025.
//

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
struct VMTableData:Decodable {
    let name: String
    let status: String
    let createdAt: String
    let cores: String
    let memoryGB: String
    let preemptible: Bool
    let addresses: [String]
    let folderName: String
}
