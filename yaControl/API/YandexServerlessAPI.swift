//
//  YandexServerlessAPI.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexServerlessAPI: @unchecked Sendable {
    private let client: YandexAPIClient

    init(client: YandexAPIClient = .shared) {
        self.client = client
    }

    func getFunctions(iamToken: String, folderId: String) async throws -> [ServerlessFunctionDTO] {
        guard var urlComponents = URLComponents(string: APIConfig.yaFunctionsEndpoint) else {
            throw YandexRequestError.invalidURL
        }

        urlComponents.queryItems = [URLQueryItem(name: "folderId", value: folderId)]

        guard let url = urlComponents.url else {
            throw YandexRequestError.invalidURL
        }

        let (data, _) = try await client.request(
            url: url,
            method: "GET",
            iamToken: iamToken,
            endpoint: "serverless functions"
        )

        do {
            try client.throwYandexAPIErrorIfPresent(in: data)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let functionsArray = json["functions"] as? [[String: Any]]
            else {
                return []
            }

            let functionsData = try JSONSerialization.data(withJSONObject: functionsArray)
            return try JSONDecoder().decode([ServerlessFunctionDTO].self, from: functionsData)
        } catch let error as YandexRequestError {
            throw error
        } catch {
            if let decodingError = error as? DecodingError {
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud serverless functions response.")
        }
    }
}
