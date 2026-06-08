//
//  AuthDTO.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct AuthResponse {
    let code: Int
    let iamToken: String
    let expiresAt: String
}

struct YandexAPIErrorResponse: Decodable {
    let error: YandexAPIErrorBody?
    let message: String?
}

struct YandexAPIErrorBody: Decodable {
    let code: Int?
    let message: String?
}
