//
//  ServerlessFunctionTableData.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct ServerLessFunctionTableData: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let status: String
    let createdAt: String
    let folderName: String
    let folderUrl: URL?
    let httpInvokeUrl: String
    let slfUrl: URL?
}
