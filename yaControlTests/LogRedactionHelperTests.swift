//
//  LogRedactionHelperTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import XCTest
@testable import yaControl

final class LogRedactionHelperTests: XCTestCase {
    func testFreeFormRedactsYandexPassportOauthToken() {
        assertFreeFormRedacts(key: "yandexPassportOauthToken", secret: "fake-yandex-oauth-token")
    }

    func testFreeFormRedactsIamToken() {
        assertFreeFormRedacts(key: "iamToken", secret: "fake-iam-token")
    }

    func testFreeFormRedactsAccessToken() {
        assertFreeFormRedacts(key: "accessToken", secret: "fake-access-token")
    }

    func testFreeFormRedactsRefreshToken() {
        assertFreeFormRedacts(key: "refreshToken", secret: "fake-refresh-token")
    }

    func testFreeFormRedactsGenericTokenField() {
        assertFreeFormRedacts(key: "token", secret: "fake-generic-token")
    }

    func testFreeFormRedactsAuthorizationBearerToken() {
        let secret = "fake-authorization-token"
        let redacted = LogRedactionHelper.redact("Authorization: Bearer \(secret)")

        XCTAssertFalse(redacted.contains(secret))
        XCTAssertTrue(redacted.contains(LogRedactionHelper.hiddenValue))
    }

    func testFreeFormPreservesOrdinaryFields() {
        let message = "name=vm-1 status=RUNNING folderId=folder-1"

        XCTAssertEqual(LogRedactionHelper.redact(message), message)
    }

    func testJSONRedactsSensitiveFieldsInsideNestedDictionaries() throws {
        let secret = "fake-nested-refresh-token"
        let object: [String: Any] = [
            "metadata": [
                "refreshToken": secret,
                "folderName": "production"
            ]
        ]

        let redacted = try XCTUnwrap(LogRedactionHelper.redactedJSONObject(object) as? [String: Any])
        let metadata = try XCTUnwrap(redacted["metadata"] as? [String: Any])

        XCTAssertEqual(metadata["refreshToken"] as? String, LogRedactionHelper.hiddenValue)
        XCTAssertFalse(try jsonString(from: redacted).contains(secret))
    }

    func testJSONRedactsSensitiveFieldsInsideArraysContainingDictionaries() throws {
        let secret = "fake-array-iam-token"
        let object: [String: Any] = [
            "items": [
                [
                    "iamToken": secret,
                    "name": "vm-1"
                ]
            ]
        ]

        let redacted = try XCTUnwrap(LogRedactionHelper.redactedJSONObject(object) as? [String: Any])
        let items = try XCTUnwrap(redacted["items"] as? [[String: Any]])
        let firstItem = try XCTUnwrap(items.first)

        XCTAssertEqual(firstItem["iamToken"] as? String, LogRedactionHelper.hiddenValue)
        XCTAssertFalse(try jsonString(from: redacted).contains(secret))
    }

    func testJSONPreservesOrdinaryFields() throws {
        let object: [String: Any] = [
            "name": "vm-1",
            "status": "RUNNING",
            "nested": [
                "folderId": "folder-1"
            ]
        ]

        let redacted = try XCTUnwrap(LogRedactionHelper.redactedJSONObject(object) as? [String: Any])
        let nested = try XCTUnwrap(redacted["nested"] as? [String: Any])

        XCTAssertEqual(redacted["name"] as? String, "vm-1")
        XCTAssertEqual(redacted["status"] as? String, "RUNNING")
        XCTAssertEqual(nested["folderId"] as? String, "folder-1")
    }

    func testJSONResultDoesNotContainOriginalSecretValue() throws {
        let secret = "fake-deep-access-token"
        let object: [String: Any] = [
            "accessToken": secret,
            "child": [
                "token": secret
            ],
            "items": [
                [
                    "yandexPassportOauthToken": secret
                ]
            ]
        ]

        let redacted = LogRedactionHelper.redactedJSONObject(object)

        XCTAssertFalse(try jsonString(from: redacted).contains(secret))
    }

    private func assertFreeFormRedacts(key: String, secret: String) {
        let redacted = LogRedactionHelper.redact("\(key)=\(secret)")

        XCTAssertFalse(redacted.contains(secret))
        XCTAssertTrue(redacted.contains(LogRedactionHelper.hiddenValue))
    }

    private func jsonString(from object: Any) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }
}
