//
//  KeychainTokenStore.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation
import Security

protocol OAuthTokenStore {
    func readOAuthToken() throws -> String?
    func saveOAuthToken(_ token: String) throws
    func deleteOAuthToken() throws
}

enum KeychainTokenStoreError: LocalizedError {
    case unexpectedStatus(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            return "Keychain operation failed with status \(status)."
        case .invalidData:
            return "Stored OAuth token data is invalid."
        }
    }
}

final class KeychainTokenStore: OAuthTokenStore {
    static let shared = KeychainTokenStore()

    private let service = "com.krusty84.yaControl"
    private let account = "yandexOAuthToken"

    private init() {}

    func readOAuthToken() throws -> String? {
        var query = baseQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }

        guard
            let data = item as? Data,
            let token = String(data: data, encoding: .utf8)
        else {
            throw KeychainTokenStoreError.invalidData
        }

        return token
    }

    func saveOAuthToken(_ token: String) throws {
        guard !token.isEmpty else {
            try deleteOAuthToken()
            return
        }

        let data = Data(token.utf8)
        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData] = data

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainTokenStoreError.unexpectedStatus(addStatus)
            }
            return
        }

        throw KeychainTokenStoreError.unexpectedStatus(updateStatus)
    }

    func deleteOAuthToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainTokenStoreError.unexpectedStatus(status)
        }
    }

    private var baseQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }
}
