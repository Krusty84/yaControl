//
//  VMStatusTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import XCTest
@testable import yaControl

final class VMStatusTests: XCTestCase {
    private let knownStatuses: [VMStatus] = [
        .provisioning,
        .running,
        .stopping,
        .stopped,
        .starting,
        .restarting,
        .updating,
        .error,
        .crashed,
        .deleting
    ]

    func testDecodesKnownAPIStatuses() throws {
        for status in knownStatuses {
            let decodedStatus = try decodeStatus(from: status.rawValue)
            XCTAssertEqual(decodedStatus, status)
        }
    }

    func testUnsupportedAPIStatusDecodesAsUnknown() throws {
        let decodedStatus = try decodeStatus(from: "SUSPENDED")

        XCTAssertEqual(decodedStatus, .unknown)
    }

    func testOnlyRunningReturnsIsRunning() {
        for status in allStatuses {
            XCTAssertEqual(status.isRunning, status == .running)
        }
    }

    func testOnlyStoppedReturnsIsStopped() {
        for status in allStatuses {
            XCTAssertEqual(status.isStopped, status == .stopped)
        }
    }

    func testOnlyErrorAndCrashedReturnIsFailure() {
        for status in allStatuses {
            XCTAssertEqual(status.isFailure, status == .error || status == .crashed)
        }
    }

    func testOnlyRunningAndStoppedAreActionable() {
        for status in allStatuses {
            XCTAssertEqual(status.isActionable, status == .running || status == .stopped)
        }
    }

    func testTransitioningStatesAreRecognized() {
        let transitioningStatuses: Set<VMStatus> = [
            .starting,
            .stopping,
            .provisioning,
            .restarting,
            .updating
        ]

        for status in allStatuses {
            XCTAssertEqual(status.isTransitioning, transitioningStatuses.contains(status))
        }
    }

    private var allStatuses: [VMStatus] {
        knownStatuses + [.unknown]
    }

    private func decodeStatus(from rawValue: String) throws -> VMStatus {
        let data = Data("\"\(rawValue)\"".utf8)
        return try JSONDecoder().decode(VMStatus.self, from: data)
    }
}
