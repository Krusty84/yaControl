//
//  FolderDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct FolderDTO: Decodable {
    let id: String
    let cloudId: String
    let createdAt: String
    let name: String
    let status: String
}
