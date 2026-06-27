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

        let requestDebugMessage = formattedAPIRequest(request, endpoint: endpoint)

        #if DEBUG
        print(requestDebugMessage)
        #endif

        if SettingsManager.shared.apiDebugEnabled {
            Task { @MainActor in
                APIDebugStore.shared.append(requestDebugMessage)
            }
        }

        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)

        let responseDebugMessage = formattedAPIResponse(
            response,
            data: data,
            endpoint: endpoint,
            durationMs: durationMs
        )

        #if DEBUG
        print(responseDebugMessage)
        #endif

        if SettingsManager.shared.apiDebugEnabled {
            Task { @MainActor in
                APIDebugStore.shared.append(responseDebugMessage)
            }
        }

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
    
    private func formattedAPIRequest(_ request: URLRequest, endpoint: String) -> String {
        let method = request.httpMethod ?? "<unknown>"
        let url = request.url.map { LogRedactionHelper.redact($0.absoluteString) } ?? "<invalid url>"
        let headers = sanitizedHeaders(request.allHTTPHeaderFields)

        let requestBody: String
        if let body = request.httpBody, !body.isEmpty {
            requestBody = prettyPrintedBody(body)
        } else {
            requestBody = "<empty>"
        }

        return """
        
        ┌────────────────────────────────────────────
        │ Yandex API Request
        ├────────────────────────────────────────────
        │ endpoint: \(endpoint)
        │ method:   \(method)
        │ url:      \(url)
        │ headers:  \(headers)
        │ body:

          \(requestBody)
        
        ─────────────────────────────────────────────
        """
    }

    private func formattedAPIResponse(
        _ response: URLResponse,
        data: Data,
        endpoint: String,
        durationMs: Int
    ) -> String {
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let headers = sanitizedResponseHeaders(httpResponse?.allHeaderFields)

        let responseBody: String
        if data.isEmpty {
            responseBody = "<empty>"
        } else {
            responseBody = prettyPrintedBody(data)
        }

        return """
        
        ┌────────────────────────────────────────────
        │ Yandex API Response
        ├────────────────────────────────────────────
        | endpoint:   \(endpoint)
        │ statusCode: \(statusCode)
        │ duration:   \(durationMs) ms
        │ headers:    \(headers)
        │ body:
        
          \(responseBody)
        
        ─────────────────────────────────────────────
        """
    }

    private func sanitizedHeaders(_ headers: [String: String]?) -> [String: String] {
        guard var headers else { return [:] }

        for key in headers.keys {
            if key.lowercased() == "authorization" {
                headers[key] = "<HIDDEN>"
            }
        }

        return headers
    }

    private func sanitizedResponseHeaders(_ headers: [AnyHashable: Any]?) -> [String: String] {
        guard let headers else { return [:] }

        var result: [String: String] = [:]

        for (key, value) in headers {
            let keyString = String(describing: key)
            let valueString = String(describing: value)

            if keyString.lowercased() == "authorization" {
                result[keyString] = LogRedactionHelper.hiddenValue
            } else {
                result[keyString] = valueString
            }
        }

        return result
    }

    private func prettyPrintedBody(_ data: Data) -> String {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(
                withJSONObject: LogRedactionHelper.redactedJSONObject(jsonObject),
                options: [.prettyPrinted, .sortedKeys]
           ),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }

        if let body = String(data: data, encoding: .utf8) {
            return LogRedactionHelper.redact(body)
        }

        return "<non-utf8 body>"
    }
}
