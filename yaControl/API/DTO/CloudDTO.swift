//
//  CloudDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct CloudDTO: Decodable {
    let id: String
    let createdAt: String
    let name: String
    let organizationId: String
}

struct CloudsResponse {
    let code: Int
    let clouds: [CloudDTO]
}
