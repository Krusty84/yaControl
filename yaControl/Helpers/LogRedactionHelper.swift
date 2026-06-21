//
//  LogRedactionHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 21/06/2026.
//

import Foundation

enum LogRedactionHelper {
    static let hiddenValue = "<HIDDEN>"

    private static let sensitiveKeys: Set<String> = [
        "yandexpassportoauthtoken",
        "iamtoken",
        "accesstoken",
        "refreshtoken",
        "token",
        "authorization"
    ]

    private static let sensitiveKeyPattern =
        #"(?i)(["']?(?:yandexPassportOauthToken|iamToken|accessToken|"#
        + #"refreshToken|token|authorization)["']?\s*[:=]\s*)"#
        + #"(?:"[^"]*"|'[^']*'|Bearer\s+[^\s,;&}\]]+|[^\s,;&}\]]+)"#

    static func redact(_ message: String) -> String {
        replaceSensitiveMatches(in: message)
    }

    static func redactedJSONObject(_ object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, element in
                if isSensitiveKey(element.key) {
                    result[element.key] = hiddenValue
                } else {
                    result[element.key] = redactedJSONObject(element.value)
                }
            }
        }

        if let array = object as? [Any] {
            return array.map(redactedJSONObject)
        }

        return object
    }

    private static func isSensitiveKey(_ key: String) -> Bool {
        sensitiveKeys.contains(key.lowercased())
    }

    private static func replaceSensitiveMatches(in message: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: sensitiveKeyPattern) else {
            return message
        }

        let range = NSRange(message.startIndex..<message.endIndex, in: message)
        return regex.stringByReplacingMatches(
            in: message,
            options: [],
            range: range,
            withTemplate: "$1\(hiddenValue)"
        )
    }
}
