//
//  YandexStorageAPI.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexStorageAPI {
    private let client: YandexAPIClient

    init(client: YandexAPIClient = .shared) {
        self.client = client
    }

    func getBuckets(iamToken: String, folderId: String) async throws -> [BucketDTO] {
        guard var urlComponents = URLComponents(string: APIConfig.yaBucketsEndpoint) else {
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
            endpoint: "buckets"
        )

        do {
            try client.throwYandexAPIErrorIfPresent(in: data)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let bucketsArray = json["buckets"] as? [[String: Any]]
            else {
                return []
            }

            let bucketsData = try JSONSerialization.data(withJSONObject: bucketsArray)
            return try JSONDecoder().decode([BucketDTO].self, from: bucketsData)
        } catch let error as YandexRequestError {
            throw error
        } catch {
            if let decodingError = error as? DecodingError {
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud buckets response.")
        }
    }

    func getBucketInfo(iamToken: String, bucketName: String) async throws -> BucketInfoDTO {
        guard let url = URL(string: "\(APIConfig.yaBucketsEndpoint)/\(bucketName):getStats") else {
            throw YandexRequestError.invalidURL
        }

        let (data, _) = try await client.request(
            url: url,
            method: "GET",
            iamToken: iamToken,
            endpoint: "bucket info"
        )

        do {
            return try JSONDecoder().decode(BucketInfoDTO.self, from: data)
        } catch {
            LoggerHelper.error("Decoding Error: \(error)")
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud bucket details response.")
        }
    }
}
