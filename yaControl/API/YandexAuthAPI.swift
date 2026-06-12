//
//  YandexAuthAPI.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexAuthAPI: @unchecked Sendable {
    private let client: YandexAPIClient

    init(client: YandexAPIClient = .shared) {
        self.client = client
    }

    func checkOAuthToken(_ token: String) async throws -> AuthResponse {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw YandexRequestError.emptyOAuthToken
        }

        guard let url = URL(string: APIConfig.yaAuthEndpoint) else {
            throw YandexRequestError.invalidURL
        }

        let payload = ["yandexPassportOauthToken": token]
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        let (data, httpResponse) = try await client.request(
            url: url,
            method: "POST",
            body: jsonData,
            endpoint: "auth"
        )

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let iamToken = json["iamToken"] as? String,
            let expiresAt = json["expiresAt"] as? String
        else {
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud authentication response.")
        }

        return AuthResponse(code: httpResponse.statusCode, iamToken: iamToken, expiresAt: expiresAt)
    }
}
