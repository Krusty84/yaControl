//
//  VMPowerWakeAutoStartWorkflowTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import XCTest
@testable import yaControl

final class VMPowerWakeAutoStartWorkflowTests: XCTestCase {
    func testWakeRetriesWhenFirstNetworkOrInventoryAttemptFails() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["vm-1"],
            inventoryResults: [
                .failure(URLError(.timedOut)),
                .success([Self.makeVM(id: "vm-1", status: .stopped)])
            ]
        )

        let result = await makeWorkflow(harness: harness).run()
        let inventoryLoadCount = await harness.inventoryLoadCount()
        let startRequests = await harness.startRequests()

        XCTAssertEqual(result, VMAutoStartAttemptResult.completed)
        XCTAssertEqual(inventoryLoadCount, 2)
        XCTAssertEqual(startRequests, [["vm-1"]])
    }

    func testWakeStartsSelectedVMAfterStatusChangesFromStoppingToStopped() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["vm-1"],
            inventoryResults: [
                .success([Self.makeVM(id: "vm-1", status: .stopping)]),
                .success([Self.makeVM(id: "vm-1", status: .stopped)])
            ]
        )

        let result = await makeWorkflow(harness: harness).run()
        let inventoryLoadCount = await harness.inventoryLoadCount()
        let startRequests = await harness.startRequests()

        XCTAssertEqual(result, VMAutoStartAttemptResult.completed)
        XCTAssertEqual(inventoryLoadCount, 2)
        XCTAssertEqual(startRequests, [["vm-1"]])
    }

    func testWakeDoesNotStartUnselectedVM() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["selected-vm"],
            inventoryResults: [
                .success([
                    Self.makeVM(id: "selected-vm", status: .running),
                    Self.makeVM(id: "unselected-vm", status: .stopped)
                ])
            ]
        )

        let result = await makeWorkflow(harness: harness).run()
        let startRequests = await harness.startRequests()

        XCTAssertEqual(result, VMAutoStartAttemptResult.completed)
        XCTAssertTrue(startRequests.isEmpty)
    }

    func testWakeDoesNotSendDuplicateStartWhenVMChangesToStarting() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["vm-1"],
            inventoryResults: [
                .success([Self.makeVM(id: "vm-1", status: .stopped)]),
                .success([Self.makeVM(id: "vm-1", status: .starting)])
            ],
            startCompletions: [false]
        )

        let result = await makeWorkflow(harness: harness, delays: [.seconds(1), .seconds(2)]).run()
        let inventoryLoadCount = await harness.inventoryLoadCount()
        let startRequests = await harness.startRequests()

        XCTAssertEqual(result, VMAutoStartAttemptResult.retryRequired(reason: "vm_transition"))
        XCTAssertEqual(inventoryLoadCount, 2)
        XCTAssertEqual(startRequests, [["vm-1"]])
    }

    func testWakeStopsRetryingWhenVMBecomesRunning() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["vm-1"],
            inventoryResults: [
                .success([Self.makeVM(id: "vm-1", status: .starting)]),
                .success([Self.makeVM(id: "vm-1", status: .running)])
            ]
        )

        let result = await makeWorkflow(harness: harness).run()
        let inventoryLoadCount = await harness.inventoryLoadCount()
        let startRequests = await harness.startRequests()

        XCTAssertEqual(result, VMAutoStartAttemptResult.completed)
        XCTAssertEqual(inventoryLoadCount, 2)
        XCTAssertTrue(startRequests.isEmpty)
    }

    func testWakeDoesNotRetryWhenAfterWakeupIsDisabled() async {
        let harness = WakeWorkflowHarness(
            startOptions: [],
            selectedVMIds: ["vm-1"],
            inventoryResults: [.success([Self.makeVM(id: "vm-1", status: .stopped)])]
        )

        let result = await makeWorkflow(harness: harness).run()
        let settingsLoadCount = await harness.settingsLoadCount()
        let inventoryLoadCount = await harness.inventoryLoadCount()

        XCTAssertEqual(result, VMAutoStartAttemptResult.disabled)
        XCTAssertEqual(settingsLoadCount, 1)
        XCTAssertEqual(inventoryLoadCount, 0)
    }

    func testWakeDoesNotRetryWhenPowerManagementIsDisabled() async {
        let harness = WakeWorkflowHarness(
            autoStartEnabled: false,
            selectedVMIds: ["vm-1"],
            inventoryResults: [.success([Self.makeVM(id: "vm-1", status: .stopped)])]
        )

        let result = await makeWorkflow(harness: harness).run()
        let settingsLoadCount = await harness.settingsLoadCount()
        let inventoryLoadCount = await harness.inventoryLoadCount()

        XCTAssertEqual(result, VMAutoStartAttemptResult.disabled)
        XCTAssertEqual(settingsLoadCount, 1)
        XCTAssertEqual(inventoryLoadCount, 0)
    }

    func testWakeDoesNotRetryWhenNoVMsAreSelected() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: [],
            inventoryResults: [.success([Self.makeVM(id: "vm-1", status: .stopped)])]
        )

        let result = await makeWorkflow(harness: harness).run()
        let settingsLoadCount = await harness.settingsLoadCount()
        let inventoryLoadCount = await harness.inventoryLoadCount()

        XCTAssertEqual(result, VMAutoStartAttemptResult.noWork)
        XCTAssertEqual(settingsLoadCount, 1)
        XCTAssertEqual(inventoryLoadCount, 0)
    }

    func testWakeDoesNotRetryPermanentAuthenticationFailure() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["vm-1"],
            inventoryResults: [.success([Self.makeVM(id: "vm-1", status: .stopped)])],
            authError: YandexRequestError.httpError(statusCode: 401, message: nil)
        )

        let result = await makeWorkflow(harness: harness).run()
        let authCount = await harness.authCount()
        let inventoryLoadCount = await harness.inventoryLoadCount()

        XCTAssertEqual(result, VMAutoStartAttemptResult.permanentFailure(reason: "http_401"))
        XCTAssertEqual(authCount, 1)
        XCTAssertEqual(inventoryLoadCount, 0)
    }

    func testWakeStopsAfterMaximumRetryCount() async {
        let harness = WakeWorkflowHarness(
            selectedVMIds: ["vm-1"],
            inventoryResults: [
                .success([Self.makeVM(id: "vm-1", status: .stopping)]),
                .success([Self.makeVM(id: "vm-1", status: .stopping)]),
                .success([Self.makeVM(id: "vm-1", status: .stopping)])
            ]
        )

        let result = await makeWorkflow(
            harness: harness,
            delays: [.seconds(1), .seconds(2), .seconds(3)]
        ).run()
        let inventoryLoadCount = await harness.inventoryLoadCount()
        let startRequests = await harness.startRequests()

        XCTAssertEqual(result, VMAutoStartAttemptResult.retryRequired(reason: "vm_transition"))
        XCTAssertEqual(inventoryLoadCount, 3)
        XCTAssertTrue(startRequests.isEmpty)
    }

    func testSecondWakeCancelsPreviousWakeWorkflow() async {
        let coordinator = WakeAutoStartCoordinator()
        let recorder = WakeCoordinatorRecorder()

        await coordinator.start {
            await recorder.markFirstStarted()

            while !Task.isCancelled {
                await Task.yield()
            }

            await recorder.markFirstCancelled()
        }

        await recorder.waitForFirstStart()

        await coordinator.start {
            await recorder.markSecondStarted()
        }

        await recorder.waitForFirstCancellation()
        await coordinator.waitForActiveTask()

        let snapshot = await recorder.snapshot()
        XCTAssertTrue(snapshot.didStartFirst)
        XCTAssertTrue(snapshot.didCancelFirst)
        XCTAssertTrue(snapshot.didStartSecond)
    }

    private func makeWorkflow(
        harness: WakeWorkflowHarness,
        delays: [Duration] = [.seconds(1), .seconds(2), .seconds(3)]
    ) -> VMPowerWakeAutoStartWorkflow {
        VMPowerWakeAutoStartWorkflow(
            retryPolicy: VMPowerAutomationRetryPolicy(delays: delays),
            sleeper: ImmediateTestSleeper(),
            loadSettings: {
                await harness.loadSettings()
            },
            waitUntilConnected: { timeout in
                await harness.waitUntilConnected(timeout: timeout)
            },
            authenticate: { token in
                try await harness.authenticate(token)
            },
            loadInventory: { iamToken in
                try await harness.loadInventory(iamToken)
            },
            startVMs: { vms, iamToken in
                await harness.startVMs(vms, iamToken: iamToken)
            },
            internetWaitTimeout: .seconds(1)
        )
    }

    private static func makeVM(id: String, status: VMStatus) -> VMTableData {
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

private actor WakeWorkflowHarness {
    private let autoStartEnabled: Bool
    private let startOptions: [StartOption]
    private let selectedVMIds: [String]
    private let oAuthToken: String
    private var networkResults: [Bool]
    private var inventoryResults: [Result<[VMTableData], Error>]
    private var startCompletions: [Bool]
    private let authError: Error?
    private var loadedSettingsCount = 0
    private var waitedNetworkCount = 0
    private var authenticatedCount = 0
    private var loadedInventoryCount = 0
    private var requestedStarts: [[String]] = []

    init(
        autoStartEnabled: Bool = true,
        startOptions: [StartOption] = [.afterWakeup],
        selectedVMIds: [String],
        oAuthToken: String = "fake-oauth-token",
        networkResults: [Bool] = [true, true, true, true],
        inventoryResults: [Result<[VMTableData], Error>],
        startCompletions: [Bool] = [true],
        authError: Error? = nil
    ) {
        self.autoStartEnabled = autoStartEnabled
        self.startOptions = startOptions
        self.selectedVMIds = selectedVMIds
        self.oAuthToken = oAuthToken
        self.networkResults = networkResults
        self.inventoryResults = inventoryResults
        self.startCompletions = startCompletions
        self.authError = authError
    }

    func loadSettings() -> VMAutoStartSettingsSnapshot {
        loadedSettingsCount += 1

        return VMAutoStartSettingsSnapshot(
            autoStartEnabled: autoStartEnabled,
            startOptions: startOptions,
            selectedVMIds: selectedVMIds,
            oAuthToken: oAuthToken
        )
    }

    func waitUntilConnected(timeout: Duration) -> Bool {
        waitedNetworkCount += 1
        guard !networkResults.isEmpty else { return true }
        return networkResults.removeFirst()
    }

    func authenticate(_ token: String) throws -> AuthResponse {
        authenticatedCount += 1

        if let authError {
            throw authError
        }

        return AuthResponse(code: 200, iamToken: "fake-iam-token", expiresAt: "2026-06-27T01:00:00Z")
    }

    func loadInventory(_ iamToken: String) throws -> [VMTableData] {
        loadedInventoryCount += 1
        guard !inventoryResults.isEmpty else { return [] }

        switch inventoryResults.removeFirst() {
        case .success(let inventory):
            return inventory
        case .failure(let error):
            throw error
        }
    }

    func startVMs(_ vms: [VMTableData], iamToken: String) -> Bool {
        requestedStarts.append(vms.map(\.id))
        guard !startCompletions.isEmpty else { return true }
        return startCompletions.removeFirst()
    }

    func settingsLoadCount() -> Int {
        loadedSettingsCount
    }

    func authCount() -> Int {
        authenticatedCount
    }

    func inventoryLoadCount() -> Int {
        loadedInventoryCount
    }

    func startRequests() -> [[String]] {
        requestedStarts
    }
}

private actor ImmediateTestSleeper: AutomationSleeper {
    func sleep(for duration: Duration) async throws {
        await Task.yield()
    }
}

private actor WakeCoordinatorRecorder {
    private var didStartFirstValue = false
    private var didCancelFirstValue = false
    private var didStartSecondValue = false
    private var firstStartContinuations: [CheckedContinuation<Void, Never>] = []
    private var firstCancellationContinuations: [CheckedContinuation<Void, Never>] = []

    func markFirstStarted() {
        didStartFirstValue = true
        firstStartContinuations.forEach { $0.resume() }
        firstStartContinuations.removeAll()
    }

    func markFirstCancelled() {
        didCancelFirstValue = true
        firstCancellationContinuations.forEach { $0.resume() }
        firstCancellationContinuations.removeAll()
    }

    func markSecondStarted() {
        didStartSecondValue = true
    }

    func waitForFirstStart() async {
        if didStartFirstValue { return }

        await withCheckedContinuation { continuation in
            firstStartContinuations.append(continuation)
        }
    }

    func waitForFirstCancellation() async {
        if didCancelFirstValue { return }

        await withCheckedContinuation { continuation in
            firstCancellationContinuations.append(continuation)
        }
    }

    func snapshot() -> (didStartFirst: Bool, didCancelFirst: Bool, didStartSecond: Bool) {
        (
            didStartFirstValue,
            didCancelFirstValue,
            didStartSecondValue
        )
    }
}
