//
//  YandexRequestError.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum YandexRequestError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case apiError(code: Int?, message: String)
    case decodingError(String)
    case emptyOAuthToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Yandex Cloud request URL is invalid."
        case .invalidResponse:
            return "Yandex Cloud returned an invalid response."
        case .httpError(let statusCode, let message):
            if let message, !message.isEmpty {
                return "Yandex Cloud request failed (HTTP \(statusCode)): \(message)"
            }
            return "Yandex Cloud request failed (HTTP \(statusCode))."
        case .apiError(let code, let message):
            if let code {
                return "Yandex Cloud API error \(code): \(message)"
            }
            return "Yandex Cloud API error: \(message)"
        case .decodingError(let message):
            return message
        case .emptyOAuthToken:
            return "OAuth token is empty."
        }
    }
}
