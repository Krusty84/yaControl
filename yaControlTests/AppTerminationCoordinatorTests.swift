//
//  AppTerminationCoordinatorTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 28/06/2026.
//

import XCTest
@testable import yaControl

@MainActor
final class AppTerminationCoordinatorTests: XCTestCase {
    func testPowerOffThenTerminateReusesSingleShutdownWorkflow() async {
        let recorder = TerminationRecorder()
        let coordinator = AppTerminationCoordinator(
            terminationTimeout: .seconds(1),
            isShutdownConfigured: { $0 == .beforeMacOSLogout },
            runShutdown: { reason in
                await recorder.record(reason: reason)
                return true
            }
        )

        coordinator.handleMacOSPowerOffNotification()
        coordinator.beginTermination(reason: .macOSLogoutOrShutdown)
        let result = await coordinator.waitForPendingTermination()
        let count = await recorder.count()
        let reasons = await recorder.reasons()

        XCTAssertEqual(result, .completed)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(reasons, [.macOSLogoutOrShutdown])
    }

    func testRepeatedTerminationCallsReuseSingleShutdownWorkflow() async {
        let recorder = TerminationRecorder()
        let coordinator = AppTerminationCoordinator(
            terminationTimeout: .seconds(1),
            isShutdownConfigured: { $0 == .afterAppExit },
            runShutdown: { reason in
                await recorder.record(reason: reason)
                return true
            }
        )

        coordinator.beginTermination(reason: .userQuit)
        coordinator.beginTermination(reason: .userQuit)
        let result = await coordinator.waitForPendingTermination()
        let count = await recorder.count()

        XCTAssertEqual(result, .completed)
        XCTAssertEqual(count, 1)
    }

    func testHangingShutdownTimesOutAndDoesNotStartSecondWorkflow() async {
        let recorder = TerminationRecorder()
        let coordinator = AppTerminationCoordinator(
            terminationTimeout: .milliseconds(10),
            isShutdownConfigured: { $0 == .afterAppExit },
            runShutdown: { reason in
                await recorder.record(reason: reason)
                while !Task.isCancelled {
                    await Task.yield()
                }
                return false
            }
        )

        coordinator.beginTermination(reason: .userQuit)
        let result = await coordinator.waitForPendingTermination()
        coordinator.beginTermination(reason: .userQuit)
        let count = await recorder.count()

        XCTAssertEqual(result, .timedOut)
        XCTAssertEqual(coordinator.stateSnapshot.lastResult, .timedOut)
        XCTAssertEqual(count, 1)
    }

    func testDisabledOptionSkipsWithoutStartingShutdownWorkflow() async {
        let recorder = TerminationRecorder()
        let coordinator = AppTerminationCoordinator(
            terminationTimeout: .seconds(1),
            isShutdownConfigured: { _ in false },
            runShutdown: { reason in
                await recorder.record(reason: reason)
                return true
            }
        )

        let didBegin = coordinator.beginTermination(reason: .userQuit)
        let count = await recorder.count()

        XCTAssertFalse(didBegin)
        XCTAssertEqual(coordinator.stateSnapshot.lastResult, .skipped)
        XCTAssertEqual(count, 0)
    }
}

private actor TerminationRecorder {
    private var recordedReasons: [AppTerminationReason] = []

    func record(reason: AppTerminationReason) {
        recordedReasons.append(reason)
    }

    func count() -> Int {
        recordedReasons.count
    }

    func reasons() -> [AppTerminationReason] {
        recordedReasons
    }
}
