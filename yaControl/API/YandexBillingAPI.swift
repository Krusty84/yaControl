//
//  YandexBillingAPI.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexBillingAPI: @unchecked Sendable {
    private let client: YandexAPIClient

    init(client: YandexAPIClient = .shared) {
        self.client = client
    }

    func getBillingAccounts(iamToken: String) async throws -> [BillingAccountDTO] {
        guard let url = URL(string: APIConfig.yaBillingEndpoint) else {
            throw YandexRequestError.invalidURL
        }

        let (data, _) = try await client.request(
            url: url,
            method: "GET",
            iamToken: iamToken,
            endpoint: "billing"
        )

        do {
            try client.throwYandexAPIErrorIfPresent(in: data)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let billingsArray = json["billingAccounts"] as? [[String: Any]]
            else {
                return []
            }

            let billingsData = try JSONSerialization.data(withJSONObject: billingsArray)
            return try JSONDecoder().decode([BillingAccountDTO].self, from: billingsData)
        } catch let error as YandexRequestError {
            throw error
        } catch {
            if let decodingError = error as? DecodingError {
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud billing response.")
        }
    }
}
