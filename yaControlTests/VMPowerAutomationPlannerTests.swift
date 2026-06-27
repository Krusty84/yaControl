//
//  VMPowerAutomationPlannerTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import XCTest
@testable import yaControl

final class VMPowerAutomationPlannerTests: XCTestCase {
    func testAutoStartSelectsStoppedSelectedVM() {
        let vm = makeVM(id: "vm-1", status: .stopped)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1"],
            inventory: [vm]
        )

        XCTAssertEqual(plan.vmsToStart.map(\.id), ["vm-1"])
    }

    func testAutoStartDoesNotSelectRunningSelectedVM() {
        let vm = makeVM(id: "vm-1", status: .running)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1"],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.alreadyRunningVMs.map(\.id), ["vm-1"])
    }

    func testAutoStartDoesNotSelectUnselectedStoppedVM() {
        let vm = makeVM(id: "vm-1", status: .stopped)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: [],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
    }

    func testAutoStartDoesNotSelectSelectedTransitioningVMs() {
        let statuses: [VMStatus] = [.starting, .stopping, .provisioning, .restarting, .updating]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: inventory.map(\.id),
            inventory: inventory
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.skippedVMs.map(\.id), inventory.map(\.id))
    }

    func testAutoStartDoesNotSelectFailureDeletingOrUnknownVMs() {
        let statuses: [VMStatus] = [.error, .crashed, .deleting, .unknown]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: inventory.map(\.id),
            inventory: inventory
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.skippedVMs.map(\.id), inventory.map(\.id))
    }

    func testAutoStartMissingSelectedIDDoesNotProduceOperation() {
        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["missing-vm"],
            inventory: []
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.missingVMIds, ["missing-vm"])
    }

    func testAutoStartDuplicateSelectedIDsDoNotProduceDuplicateOperations() {
        let vm = makeVM(id: "vm-1", status: .stopped)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1", "vm-1"],
            inventory: [vm]
        )

        XCTAssertEqual(plan.vmsToStart.map(\.id), ["vm-1"])
    }

    func testShutdownSelectsRunningVM() {
        let vm = makeVM(id: "vm-1", status: .running)

        let selectedVMs = VMPowerAutomationPlanner.shutdownVMs(in: [vm])

        XCTAssertEqual(selectedVMs.map(\.id), ["vm-1"])
    }

    func testShutdownDoesNotSelectStoppedVM() {
        let vm = makeVM(id: "vm-1", status: .stopped)

        let selectedVMs = VMPowerAutomationPlanner.shutdownVMs(in: [vm])

        XCTAssertTrue(selectedVMs.isEmpty)
    }

    func testShutdownDoesNotSelectTransitioningVMs() {
        let statuses: [VMStatus] = [.starting, .stopping, .provisioning, .restarting, .updating]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let selectedVMs = VMPowerAutomationPlanner.shutdownVMs(in: inventory)

        XCTAssertTrue(selectedVMs.isEmpty)
    }

    func testShutdownDoesNotSelectFailureDeletingOrUnknownVMs() {
        let statuses: [VMStatus] = [.error, .crashed, .deleting, .unknown]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let selectedVMs = VMPowerAutomationPlanner.shutdownVMs(in: inventory)

        XCTAssertTrue(selectedVMs.isEmpty)
    }

    func testShutdownOutputDoesNotContainDuplicateVMIDs() {
        let firstVM = makeVM(id: "vm-1", status: .running)
        let duplicateVM = makeVM(id: "vm-1", status: .running)

        let selectedVMs = VMPowerAutomationPlanner.shutdownVMs(in: [firstVM, duplicateVM])

        XCTAssertEqual(selectedVMs.map(\.id), ["vm-1"])
    }

    private func makeVM(id: String, status: VMStatus) -> VMTableData {
        VMTableData(
            id: id,
            name: "VM \(id)",
            status: status,
            createdAt: "2026-06-27T00:00:00Z",
            cores: "2",
            memoryGB: "4",
            preemptible: false,
            addresses: [],
            folderId: "folder-1",
            folderName: "Default",
            folderUrl: nil,
            vmUrl: nil,
            isAutoStarted: false
        )
    }
}
