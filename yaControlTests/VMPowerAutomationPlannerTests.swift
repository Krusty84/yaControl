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

    func testAutoStartDoesNotSelectUnselectedStoppedVM() {
        let vm = makeVM(id: "vm-1", status: .stopped)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: [],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
    }

    func testAutoStartTreatsRunningSelectedVMAsAlreadyRunning() {
        let vm = makeVM(id: "vm-1", status: .running)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1"],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.alreadyRunningVMs.map(\.id), ["vm-1"])
    }

    func testAutoStartDefersStoppingSelectedVM() {
        let vm = makeVM(id: "vm-1", status: .stopping)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1"],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.deferredVMs.map(\.id), ["vm-1"])
    }

    func testAutoStartDefersStartingSelectedVM() {
        let vm = makeVM(id: "vm-1", status: .starting)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1"],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.deferredVMs.map(\.id), ["vm-1"])
    }

    func testAutoStartDefersOtherTemporaryTransitionStates() {
        let statuses: [VMStatus] = [.provisioning, .restarting, .updating]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: inventory.map(\.id),
            inventory: inventory
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.deferredVMs.map(\.id), inventory.map(\.id))
        XCTAssertTrue(plan.skippedVMs.isEmpty)
    }

    func testAutoStartPermanentlySkipsFailureDeletingAndUnknownStates() {
        let statuses: [VMStatus] = [.error, .crashed, .deleting, .unknown]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: inventory.map(\.id),
            inventory: inventory
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertTrue(plan.deferredVMs.isEmpty)
        XCTAssertEqual(plan.skippedVMs.map(\.id), inventory.map(\.id))
    }

    func testAutoStartIgnoresMissingSelectedID() {
        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["missing-vm"],
            inventory: []
        )

        XCTAssertTrue(plan.vmsToStart.isEmpty)
        XCTAssertEqual(plan.missingVMIds, ["missing-vm"])
    }

    func testAutoStartDoesNotProduceDuplicateOperations() {
        let firstVM = makeVM(id: "vm-1", status: .stopped)
        let duplicateVM = makeVM(id: "vm-1", status: .stopped)

        let plan = VMPowerAutomationPlanner.autoStartPlan(
            selectedVMIds: ["vm-1", "vm-1"],
            inventory: [firstVM, duplicateVM]
        )

        XCTAssertEqual(plan.vmsToStart.map(\.id), ["vm-1"])
    }

    func testShutdownSelectsSelectedRunningVM() {
        let selectedVM = makeVM(id: "selected-vm", status: .running)
        let unselectedVM = makeVM(id: "unselected-vm", status: .running)

        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: ["selected-vm"],
            inventory: [selectedVM, unselectedVM]
        )

        XCTAssertEqual(plan.vmsToStop.map(\.id), ["selected-vm"])
    }

    func testShutdownDoesNotSelectUnselectedRunningVM() {
        let vm = makeVM(id: "vm-1", status: .running)

        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: [],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStop.isEmpty)
    }

    func testShutdownDoesNotSelectSelectedStoppedVM() {
        let vm = makeVM(id: "vm-1", status: .stopped)

        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: ["vm-1"],
            inventory: [vm]
        )

        XCTAssertTrue(plan.vmsToStop.isEmpty)
        XCTAssertEqual(plan.skippedVMs.map(\.id), ["vm-1"])
    }

    func testShutdownDoesNotSelectSelectedTransitioningVM() {
        let statuses: [VMStatus] = [.starting, .stopping, .provisioning, .restarting, .updating]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: inventory.map(\.id),
            inventory: inventory
        )

        XCTAssertTrue(plan.vmsToStop.isEmpty)
        XCTAssertEqual(plan.skippedVMs.map(\.id), inventory.map(\.id))
    }

    func testShutdownDoesNotSelectFailureDeletingOrUnknownVM() {
        let statuses: [VMStatus] = [.error, .crashed, .deleting, .unknown]
        let inventory = statuses.enumerated().map { index, status in
            makeVM(id: "vm-\(index)", status: status)
        }

        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: inventory.map(\.id),
            inventory: inventory
        )

        XCTAssertTrue(plan.vmsToStop.isEmpty)
        XCTAssertEqual(plan.skippedVMs.map(\.id), inventory.map(\.id))
    }

    func testShutdownIgnoresMissingSelectedVMID() {
        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: ["missing-vm"],
            inventory: []
        )

        XCTAssertTrue(plan.vmsToStop.isEmpty)
        XCTAssertEqual(plan.missingVMIds, ["missing-vm"])
    }

    func testShutdownDoesNotProduceDuplicateOperations() {
        let firstVM = makeVM(id: "vm-1", status: .running)
        let duplicateVM = makeVM(id: "vm-1", status: .running)

        let plan = VMPowerAutomationPlanner.shutdownPlan(
            selectedVMIds: ["vm-1", "vm-1"],
            inventory: [firstVM, duplicateVM]
        )

        XCTAssertEqual(plan.vmsToStop.map(\.id), ["vm-1"])
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
