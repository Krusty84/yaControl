//
//  VMPowerAutomationServiceLifecycleTests.swift
//  yaControlTests
//
//  Created by Sedoykin Alexey on 28/06/2026.
//

import XCTest
@testable import yaControl

final class VMPowerAutomationServiceLifecycleTests: XCTestCase {
    func testAppLaunchStartsSelectedStoppedVMWhenOptionEnabled() async {
        let harness = makeHarness(
            startOptions: [.afterAppLaunched],
            selectedVMIds: ["vm-1"],
            inventory: [Self.makeVM(id: "vm-1", status: .stopped)]
        )

        await harness.service.handleAppLaunch()
        let startRequests = await harness.power.startRequestSets()

        XCTAssertEqual(startRequests, [Set(["vm-1"])])
    }

    func testAppLaunchDoesNotStartWhenOptionDisabled() async {
        let harness = makeHarness(
            startOptions: [],
            selectedVMIds: ["vm-1"],
            inventory: [Self.makeVM(id: "vm-1", status: .stopped)]
        )

        await harness.service.handleAppLaunch()
        let startRequests = await harness.power.startRequestSets()

        XCTAssertTrue(startRequests.isEmpty)
    }

    func testWakeStartsSelectedStoppedVMWhenOptionEnabled() async {
        let coordinator = WakeAutoStartCoordinator()
        let harness = makeHarness(
            startOptions: [.afterWakeup],
            selectedVMIds: ["vm-1"],
            inventory: [Self.makeVM(id: "vm-1", status: .stopped)],
            wakeAutoStartCoordinator: coordinator,
            wakeRetryPolicy: VMPowerAutomationRetryPolicy(delays: [])
        )

        await harness.service.handleMacWake()
        await coordinator.waitForActiveTask()
        let startRequests = await harness.power.startRequestSets()

        XCTAssertEqual(startRequests, [Set(["vm-1"])])
    }

    func testUserQuitStopsSelectedVMsWhenOptionEnabled() async {
        let harness = makeHarness(
            shutdownOptions: [.afterAppExit],
            selectedVMIds: ["vm-1", "vm-2"]
        )

        let success = await harness.service.handleAppExit()
        let stopRequests = await harness.power.stopRequestSets()
        let inventoryLoadCount = await harness.inventory.loadCount()

        XCTAssertTrue(success)
        XCTAssertEqual(stopRequests, [Set(["vm-1", "vm-2"])])
        XCTAssertEqual(inventoryLoadCount, 0)
    }

    func testUserQuitDoesNotStopWhenOptionDisabled() async {
        let harness = makeHarness(
            shutdownOptions: [],
            selectedVMIds: ["vm-1"]
        )

        let success = await harness.service.handleAppExit()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertTrue(stopRequests.isEmpty)
    }

    func testMacSleepStopsSelectedVMsWhenOptionEnabled() async {
        let harness = makeHarness(
            shutdownOptions: [.beforeMacOSSleep],
            selectedVMIds: ["vm-1"]
        )

        let success = await harness.service.handleMacSleep()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertEqual(stopRequests, [Set(["vm-1"])])
    }

    func testMacSleepDoesNotStopWhenOptionDisabled() async {
        let harness = makeHarness(
            shutdownOptions: [],
            selectedVMIds: ["vm-1"]
        )

        let success = await harness.service.handleMacSleep()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertTrue(stopRequests.isEmpty)
    }

    func testMacOSShutdownStopsSelectedVMsWhenOptionEnabled() async {
        let harness = makeHarness(
            shutdownOptions: [.beforeMacOSShutdown],
            selectedVMIds: ["vm-1"]
        )

        let success = await harness.service.handleMacOSShutdown()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertEqual(stopRequests, [Set(["vm-1"])])
    }

    func testMacOSShutdownDoesNotStopWhenOptionDisabled() async {
        let harness = makeHarness(
            shutdownOptions: [],
            selectedVMIds: ["vm-1"]
        )

        let success = await harness.service.handleMacOSShutdown()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertTrue(stopRequests.isEmpty)
    }

    func testSelectionSafetyForFastShutdown() async {
        let harness = makeHarness(
            shutdownOptions: [.beforeMacOSShutdown],
            selectedVMIds: ["vm-1", "vm-1", "vm-2"]
        )

        let success = await harness.service.handleMacOSShutdown()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertEqual(stopRequests, [Set(["vm-1", "vm-2"])])
    }

    func testEmptySelectionPerformsNoStopRequests() async {
        let harness = makeHarness(
            shutdownOptions: [.beforeMacOSShutdown],
            selectedVMIds: []
        )

        let success = await harness.service.handleMacOSShutdown()
        let stopRequests = await harness.power.stopRequestSets()

        XCTAssertTrue(success)
        XCTAssertTrue(stopRequests.isEmpty)
    }

    private func makeHarness(
        autoStartEnabled: Bool = true,
        startOptions: [StartOption] = [.afterAppLaunched],
        shutdownOptions: [ShutdownOption] = [],
        selectedVMIds: [String],
        inventory: [VMTableData] = [],
        wakeAutoStartCoordinator: WakeAutoStartCoordinator = WakeAutoStartCoordinator(),
        wakeRetryPolicy: VMPowerAutomationRetryPolicy = VMPowerAutomationRetryPolicy(delays: [])
    ) -> ServiceHarness {
        let settings = MockAutomationSettings(
            autoStartEnabled: autoStartEnabled,
            startOptions: startOptions,
            shutdownOptions: shutdownOptions,
            selectedVMIds: selectedVMIds
        )
        let auth = MockAuthAPI()
        let inventoryLoader = MockInventoryLoader(inventory: inventory)
        let power = MockPowerController()
        let polling = MockPollingService()
        let service = VMPowerAutomationService(
            settingsManager: settings,
            authAPI: auth,
            inventoryService: inventoryLoader,
            powerService: power,
            pollingService: polling,
            operationRegistry: VMPowerOperationRegistry(),
            wakeAutoStartCoordinator: wakeAutoStartCoordinator,
            refreshRunningVMState: {},
            waitUntilConnected: { _ in true },
            wakeRetryPolicy: wakeRetryPolicy
        )

        return ServiceHarness(
            service: service,
            inventory: inventoryLoader,
            power: power
        )
    }

    fileprivate static func makeVM(id: String, status: VMStatus) -> VMTableData {
        VMTableData(
            id: id,
            name: "VM \(id)",
            status: status,
            createdAt: "2026-06-28T00:00:00Z",
            cores: "2",
            memoryGB: "4",
            preemptible: false,
            addresses: [],
            folderId: "folder-1",
            folderName: "Default",
            folderUrl: nil,
            vmUrl: nil,
            isAutoStarted: true
        )
    }
}

private struct ServiceHarness {
    let service: VMPowerAutomationService
    let inventory: MockInventoryLoader
    let power: MockPowerController
}

private final class MockAutomationSettings: VMPowerAutomationSettingsProviding, @unchecked Sendable {
    let autoStartEnabled: Bool
    let startOptions: [StartOption]
    let shutdownOptions: [ShutdownOption]
    let oAuthKey = "oauth-token"
    let appLanguage: AppLanguage = .english
    private let selectedVMIds: [String]

    init(
        autoStartEnabled: Bool,
        startOptions: [StartOption],
        shutdownOptions: [ShutdownOption],
        selectedVMIds: [String]
    ) {
        self.autoStartEnabled = autoStartEnabled
        self.startOptions = startOptions
        self.shutdownOptions = shutdownOptions
        self.selectedVMIds = selectedVMIds
    }

    func getAllAutostartVMs() -> [String] {
        selectedVMIds
    }

    func cleanupAutostartSettings(validVMIds: Set<String>) {}
}

private actor MockAuthAPI: YandexAuthenticating {
    func checkOAuthToken(_ token: String) async throws -> AuthResponse {
        AuthResponse(code: 200, iamToken: "iam-token", expiresAt: "2099-01-01T00:00:00Z")
    }
}

private actor MockInventoryLoader: VMInventoryLoading {
    private let inventory: [VMTableData]
    private var loadedCount = 0

    init(inventory: [VMTableData]) {
        self.inventory = inventory
    }

    func loadVMTableData(iamToken: String) async throws -> [VMTableData] {
        loadedCount += 1
        return inventory
    }

    func loadCount() -> Int {
        loadedCount
    }
}

private actor MockPowerController: VMPowerControlling {
    private var startRequests: [[String]] = []
    private var stopRequests: [[String]] = []

    func startVMs(iamToken: String, vmIds: [String]) async -> [VMOperationResult] {
        startRequests.append(vmIds)
        return vmIds.map {
            VMOperationResult(id: "start-\($0)", vmId: $0, operation: .start, success: true, errorMessage: nil)
        }
    }

    func stopVMs(iamToken: String, vmIds: [String]) async -> [VMOperationResult] {
        stopRequests.append(vmIds)
        return vmIds.map {
            VMOperationResult(id: "stop-\($0)", vmId: $0, operation: .stop, success: true, errorMessage: nil)
        }
    }

    func startRequestSets() -> [Set<String>] {
        startRequests.map(Set.init)
    }

    func stopRequestSets() -> [Set<String>] {
        stopRequests.map(Set.init)
    }
}

private actor MockPollingService: VMTransitionPolling {
    func waitForVMTransitions(
        iamToken: String,
        initialStatuses: [String: VMStatus],
        timeout: Duration?,
        interval: Duration?,
        maxConsecutiveFailures: Int?
    ) async -> [String: VMPollingResult] {
        initialStatuses.reduce(into: [String: VMPollingResult]()) { result, item in
            let vm = VMPowerAutomationServiceLifecycleTests.makeVM(id: item.key, status: .running)
            result[item.key] = .changed(vm)
        }
    }
}
