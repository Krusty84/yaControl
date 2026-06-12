//
//  YandexComputeAPI.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexComputeAPI: @unchecked Sendable {
    private let client: YandexAPIClient

    init(client: YandexAPIClient = .shared) {
        self.client = client
    }

    func getVMInstances(iamToken: String, folderId: String) async throws -> [VMInstanceDTO] {
        guard var urlComponents = URLComponents(string: APIConfig.yaVMInstancesEndpoint) else {
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
            endpoint: "vm instances"
        )

        do {
            try client.throwYandexAPIErrorIfPresent(in: data)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let instancesArray = json["instances"] as? [[String: Any]]
            else {
                return []
            }

            let instancesData = try JSONSerialization.data(withJSONObject: instancesArray)
            return try JSONDecoder().decode([VMInstanceDTO].self, from: instancesData)
        } catch let error as YandexRequestError {
            throw error
        } catch {
            if let decodingError = error as? DecodingError {
                LoggerHelper.error("Decoding Error: \(decodingError)")
            }
            throw YandexRequestError.decodingError("Could not decode Yandex Cloud VM instances response.")
        }
    }

    func startVM(iamToken: String, vmId: String) async throws {
        try await performVMOperation(iamToken: iamToken, vmId: vmId, operation: "start")
    }

    func stopVM(iamToken: String, vmId: String) async throws {
        try await performVMOperation(iamToken: iamToken, vmId: vmId, operation: "stop")
    }

    private func performVMOperation(iamToken: String, vmId: String, operation: String) async throws {
        guard let url = URL(string: "\(APIConfig.yaVMInstancesEndpoint)/\(vmId):\(operation)") else {
            throw YandexRequestError.invalidURL
        }

        _ = try await client.request(
            url: url,
            method: "POST",
            iamToken: iamToken,
            endpoint: "\(operation) vm"
        )
    }
}
