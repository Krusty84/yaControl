//
//  VMTableData.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct VMTableData: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    var status: VMStatus
    let createdAt: String
    let cores: String
    let memoryGB: String
    let preemptible: Bool
    let addresses: [String]
    let folderId: String
    let folderName: String
    let folderUrl: URL?
    let vmUrl: URL?
    var isAutoStarted: Bool

    var statusText: String {
        status.rawValue
    }
}
