//
//  VMPowerOperationRegistryTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import XCTest
@testable import yaControl

final class VMPowerOperationRegistryTests: XCTestCase {
    func testBeginReturnsTrueForFirstOperation() async {
        let registry = VMPowerOperationRegistry()

        let didBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        await registry.finish(vmId: "vm-1")

        XCTAssertTrue(didBegin)
    }

    func testBeginReturnsFalseWhenOperationIsAlreadyActive() async {
        let registry = VMPowerOperationRegistry()

        let firstBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        let secondBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        await registry.finish(vmId: "vm-1")

        XCTAssertTrue(firstBegin)
        XCTAssertFalse(secondBegin)
    }

    func testDifferentVMIdsCanBeActiveAtTheSameTime() async {
        let registry = VMPowerOperationRegistry()

        let firstBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        let secondBegin = await registry.begin(vmId: "vm-2", source: .manualUI)
        await registry.finish(vmId: "vm-1")
        await registry.finish(vmId: "vm-2")

        XCTAssertTrue(firstBegin)
        XCTAssertTrue(secondBegin)
    }

    func testAfterFinishSameVMCanBeginAnotherOperation() async {
        let registry = VMPowerOperationRegistry()

        let firstBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        await registry.finish(vmId: "vm-1")
        let secondBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        await registry.finish(vmId: "vm-1")

        XCTAssertTrue(firstBegin)
        XCTAssertTrue(secondBegin)
    }

    func testFinishForInactiveVMDoesNotCorruptRegistryState() async {
        let registry = VMPowerOperationRegistry()

        await registry.finish(vmId: "inactive-vm")
        let didBegin = await registry.begin(vmId: "vm-1", source: .manualUI)
        await registry.finish(vmId: "vm-1")

        XCTAssertTrue(didBegin)
    }
}
