//
//  YandexResourceManagerAPI.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexResourceManagerAPI: @unchecked Sendable {
    private let client: YandexAPIClient

    init(client: YandexAPIClient = .shared) {
        self.client = client
    }

    func getClouds(iamToken: String) async throws -> CloudsResponse {
        guard let url = URL(string: APIConfig.yaCloudsEndpoint) else {
            throw YandexRequestError.invalidURL
        }

        let (data, httpResponse) = try await client.request(
            url: url,
            method: "GET",
            iamToken: iamToken,
            endpoint: "clouds"
        )

        do {
            let response = try JSONDecoder().decode([String: [CloudDTO]].self, from: data)
            guard let clouds = response["clouds"] else {
                throw YandexRequestError.decodingError("Could not decode Yandex Cloud clouds response.")
            }
            return CloudsResponse(code: httpResponse.statusCode, clouds: clouds)
        } catch let error as YandexRequestError {
            throw error
        } catch {
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud clouds response.")
        }
    }

    func getFolders(iamToken: String, cloudId: String) async throws -> [FolderDTO] {
        guard var urlComponents = URLComponents(string: APIConfig.yaFoldersEndpoint) else {
            throw YandexRequestError.invalidURL
        }

        urlComponents.queryItems = [URLQueryItem(name: "cloudId", value: cloudId)]

        guard let url = urlComponents.url else {
            throw YandexRequestError.invalidURL
        }

        let (data, _) = try await client.request(
            url: url,
            method: "GET",
            iamToken: iamToken,
            endpoint: "folders"
        )

        do {
            let response = try JSONDecoder().decode([String: [FolderDTO]].self, from: data)
            return response["folders"] ?? []
        } catch {
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud folders response.")
        }
    }
}
