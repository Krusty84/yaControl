//
//  YandexAPIClient.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class YandexAPIClient: @unchecked Sendable {
    static let shared = YandexAPIClient()

    private init() {}

    func request(
        url: URL,
        method: String,
        iamToken: String? = nil,
        body: Data? = nil,
        endpoint: String
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let iamToken {
            request.setValue("Bearer \(iamToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try validateHTTPResponse(response, data: data, endpoint: endpoint)
        return (data, httpResponse)
    }

    func throwYandexAPIErrorIfPresent(in data: Data) throws {
        do {
            let response = try JSONDecoder().decode(YandexAPIErrorResponse.self, from: data)
            if let message = response.error?.message,
               let sanitizedMessage = sanitizedAPIMessage(message) {
                throw YandexRequestError.apiError(code: response.error?.code, message: sanitizedMessage)
            }
            if let message = response.message,
               let sanitizedMessage = sanitizedAPIMessage(message) {
                throw YandexRequestError.apiError(code: nil, message: sanitizedMessage)
            }
        } catch let error as YandexRequestError {
            throw error
        } catch {
            LoggerHelper.debug("Response did not match Yandex API error DTO: \(error.localizedDescription)")
        }

        let json: [String: Any]
        do {
            guard let parsedJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            json = parsedJSON
        } catch {
            LoggerHelper.debug("Response did not match Yandex API error JSON: \(error.localizedDescription)")
            return
        }

        guard let error = json["error"] as? [String: Any],
              let message = error["message"] as? String,
              let sanitizedMessage = sanitizedAPIMessage(message) else {
            return
        }

        throw YandexRequestError.apiError(code: error["code"] as? Int, message: sanitizedMessage)
    }

    @discardableResult
    private func validateHTTPResponse(
        _ response: URLResponse,
        data: Data,
        endpoint: String
    ) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw YandexRequestError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = yandexAPIErrorMessage(from: data)
            if let message {
                LoggerHelper.error("Yandex API \(endpoint) failed: HTTP \(httpResponse.statusCode), \(message)")
            } else {
                LoggerHelper.error("Yandex API \(endpoint) failed: HTTP \(httpResponse.statusCode)")
            }
            throw YandexRequestError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        return httpResponse
    }

    private func yandexAPIErrorMessage(from data: Data) -> String? {
        do {
            let response = try JSONDecoder().decode(YandexAPIErrorResponse.self, from: data)
            if let message = response.error?.message {
                return sanitizedAPIMessage(message)
            }
            if let message = response.message {
                return sanitizedAPIMessage(message)
            }
        } catch {
            LoggerHelper.debug("HTTP error body did not match Yandex API error DTO: \(error.localizedDescription)")
        }

        let json: [String: Any]
        do {
            guard let parsedJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            json = parsedJSON
        } catch {
            LoggerHelper.debug("HTTP error body did not match Yandex API error JSON: \(error.localizedDescription)")
            return nil
        }

        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return sanitizedAPIMessage(message)
        }

        if let message = json["message"] as? String {
            return sanitizedAPIMessage(message)
        }

        return nil
    }

    private func sanitizedAPIMessage(_ message: String) -> String? {
        let sanitized = message
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else { return nil }

        return String(sanitized.prefix(300))
    }
}
