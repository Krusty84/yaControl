//
//  ComputeDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct VMInstanceDTO: Decodable {
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
    let status: VMStatus
}
