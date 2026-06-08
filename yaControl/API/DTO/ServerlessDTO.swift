//
//  ServerlessDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct ServerlessFunctionDTO: Decodable {
    let id: String
    let folderId: String
    let createdAt: String
    let name: String
    let httpInvokeUrl: String
    let status: String
}
