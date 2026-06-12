//
//  CloudComputingViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import Foundation
import Observation

@Observable
@MainActor
final class CloudComputingModel {
    // MARK: - State
    var vmTableData: [VMTableData] = []
    var billingData: [BillingTableData] = []
    var isLoading = false
    var error: Error?
    var searchText = ""
    var currentBalance = ""
    var currency = ""
    var billingUrl: URL? = nil
    var lastUpdateTime = Date()
    var processingStates: [String: Bool] = [:]   // VM ID -> isProcessing

    private let api = YandexAPIService.shared
    private let powerService = VMPowerService.shared
    private let pollingService = VMPollingService.shared
    private let operationRegistry = VMPowerOperationRegistry.shared
    private var iamToken = ""
    private var hasLoaded = false

    // MARK: - Computed helpers
    var filteredVMs: [VMTableData] {
        guard !searchText.isEmpty else { return vmTableData }
        return vmTableData.filter { $0.name.localizedStandardContains(searchText) }
    }
    var totalVMs: Int { vmTableData.count }
    var runningVMs: Int { vmTableData.filter { $0.status.isRunning }.count }
    var showError: Bool { error != nil }
    var errorMessage: String? { error?.localizedDescription }

    // MARK: - Actions
    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await fetchVMs()
    }

    func fetchVMs() async {
        isLoading = true
        error = nil

        do {
            // Authenticate
            let auth = try await api.checkOauthKey(
                yandexPassportOauthToken: SettingsManager.shared.oAuthKey
            )
            iamToken = auth.iamToken

            // Load VMs and billing in parallel
            async let vms   = api.getVMs(iamToken: iamToken)
            async let bills = api.getCosts(iamToken: iamToken)

            let (list, billings) = try await (vms, bills)

            // Publish data
            vmTableData = list
            billingData  = billings
            if let first = billings.first {
                currentBalance = first.balance
                currency       = first.currency
                billingUrl     = first.billingUrl
            }
            lastUpdateTime = Date()
            isLoading = false

            // Update global app state
            AppState.shared.isVirtualMachineRunning = runningVMs > 0

        } catch {
            self.error = error
            isLoading = false
            LoggerHelper.error("Error fetching VMs: \(error.localizedDescription)")
        }
    }

    func setAutoStart(for id: String, isOn: Bool) {
        if let idx = vmTableData.firstIndex(where: { $0.id == id }) {
            vmTableData[idx].isAutoStarted = isOn
            SettingsManager.shared.markVMtoAutostart(for: id, isAutoStarted: isOn)
        }
    }

    func toggleVM(_ vm: VMTableData) {
        Task {
            await performManualPowerOperation(for: vm)
        }
    }

    func stopAllAndPoll() {
        let runningList = vmTableData.filter { $0.status.isRunning }

        Task {
            await stopAllAndPoll(runningList)
        }
    }

    // MARK: - Polling

    private func performManualPowerOperation(for vm: VMTableData) async {
        guard processingStates[vm.id] != true else { return }
        guard vm.status.isActionable else {
            VMPowerOperationLogger.log(
                vmId: vm.id,
                operation: nil,
                source: .manualUI,
                outcome: .skipped,
                message: "Current row status is not actionable: \(vm.status.rawValue)"
            )
            return
        }
        guard await operationRegistry.begin(vmId: vm.id, source: .manualUI) else { return }

        processingStates[vm.id] = true
        defer {
            processingStates[vm.id] = false
            Task {
                await operationRegistry.finish(vmId: vm.id)
            }
        }

        guard !iamToken.isEmpty else {
            VMPowerOperationLogger.log(
                vmId: vm.id,
                operation: nil,
                source: .manualUI,
                outcome: .failed,
                message: YandexRequestError.emptyOAuthToken.localizedDescription,
                isError: true
            )
            return
        }

        let operation: VMOperation = vm.status.isRunning ? .stop : .start

        do {
            let latestVMs = try await refreshVMInventory()
            guard let latestVM = latestVMs.first(where: { $0.id == vm.id }) else {
                VMPowerOperationLogger.log(
                    vmId: vm.id,
                    operation: operation,
                    source: .manualUI,
                    outcome: .failed,
                    message: "VM disappeared from inventory",
                    isError: true
                )
                return
            }

            if operation.isAlreadyCompleted(status: latestVM.status) {
                VMPowerOperationLogger.log(
                    vmId: latestVM.id,
                    operation: operation,
                    source: .manualUI,
                    outcome: .completed,
                    message: "VM already reached target status \(operation.targetStatus.rawValue)"
                )
                return
            }

            guard operation.canSendRequest(status: latestVM.status) else {
                VMPowerOperationLogger.log(
                    vmId: latestVM.id,
                    operation: operation,
                    source: .manualUI,
                    outcome: .skipped,
                    message: "Latest status is not actionable for operation: \(latestVM.status.rawValue)"
                )
                return
            }

            try await sendPowerRequest(operation, vmId: latestVM.id, source: .manualUI)
            let result = await pollingService.waitForVMTransition(
                iamToken: iamToken,
                vmId: latestVM.id,
                initialStatus: latestVM.status
            )
            await handlePollingResult(
                result,
                initialStatus: latestVM.status,
                operation: operation,
                source: .manualUI,
                refreshOnUncertainResult: true
            )
        } catch {
            VMPowerOperationLogger.log(
                vmId: vm.id,
                operation: operation,
                source: .manualUI,
                outcome: .failed,
                message: error.localizedDescription,
                isError: true
            )
        }
    }

    private func stopAllAndPoll(_ runningList: [VMTableData]) async {
        guard !iamToken.isEmpty else {
            LoggerHelper.error("Stop All failed: \(YandexRequestError.emptyOAuthToken.localizedDescription)")
            return
        }

        var lockedVMs: [VMTableData] = []
        for vm in runningList where vm.status.isRunning {
            guard await operationRegistry.begin(vmId: vm.id, source: .stopAll) else { continue }
            processingStates[vm.id] = true
            lockedVMs.append(vm)
        }

        guard !lockedVMs.isEmpty else { return }

        let lockedVMIds = Set(lockedVMs.map(\.id))
        defer {
            for vmId in lockedVMIds {
                processingStates[vmId] = false
            }
            Task {
                for vmId in lockedVMIds {
                    await operationRegistry.finish(vmId: vmId)
                }
            }
        }

        let results = await powerService.stopVMs(iamToken: iamToken, vmIds: Array(lockedVMIds))
        let successfulResults = results.filter(\.success)
        let failedResults = results.filter { !$0.success }

        for result in successfulResults {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: .stopAll,
                outcome: .accepted
            )
        }

        for result in failedResults {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: .stopAll,
                outcome: .failed,
                message: result.errorMessage ?? "Unknown error",
                isError: true
            )
            await finishProcessing(vmId: result.vmId)
        }

        let successfulVMIds = Set(successfulResults.map(\.vmId))
        let initialStatuses = Dictionary(
            uniqueKeysWithValues: lockedVMs
                .filter { successfulVMIds.contains($0.id) }
                .map { ($0.id, $0.status) }
        )
        let pollResults = await pollingService.waitForVMTransitions(
            iamToken: iamToken,
            initialStatuses: initialStatuses
        )

        for (vmId, result) in pollResults {
            await handlePollingResult(
                result,
                initialStatus: initialStatuses[vmId] ?? .running,
                operation: .stop,
                source: .stopAll,
                refreshOnUncertainResult: false
            )
            await finishProcessing(vmId: vmId)
        }

        let polledVMIds = Set(pollResults.keys)
        for vmId in lockedVMIds.subtracting(Set(failedResults.map(\.vmId))).subtracting(polledVMIds) {
            await finishProcessing(vmId: vmId)
        }

        await refreshVMInventoryAfterOperation(source: .stopAll)
    }

    private func sendPowerRequest(
        _ operation: VMOperation,
        vmId: String,
        source: VMPowerOperationSource
    ) async throws {
        switch operation {
        case .start:
            try await powerService.startVM(iamToken: iamToken, vmId: vmId)
        case .stop:
            try await powerService.stopVM(iamToken: iamToken, vmId: vmId)
        }

        VMPowerOperationLogger.log(
            vmId: vmId,
            operation: operation,
            source: source,
            outcome: .accepted
        )
    }

    private func handlePollingResult(
        _ result: VMPollingResult,
        initialStatus: VMStatus,
        operation: VMOperation,
        source: VMPowerOperationSource,
        refreshOnUncertainResult: Bool
    ) async {
        let timeStamp = Date().formatted(.dateTime.hour().minute().second())

        switch result {
        case .changed(let newVM):
            VMPowerOperationLogger.log(
                vmId: newVM.id,
                operation: operation,
                source: source,
                outcome: newVM.status.isFailure ? .failed : .completed,
                message: "status=\(newVM.status.rawValue)",
                isError: newVM.status.isFailure
            )

            if let idx = vmTableData.firstIndex(where: { $0.id == newVM.id }) {
                vmTableData[idx] = newVM
            }
            AppState.shared.isVirtualMachineRunning = runningVMs > 0

            if !initialStatus.isRunning && newVM.status.isRunning {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: LocalizedStringHelper.formatted(
                        L10n.Notifications.vmStarted,
                        language: SettingsManager.shared.appLanguage,
                        newVM.name,
                        timeStamp
                    )
                )
            }
            if initialStatus.isRunning && newVM.status.isStopped {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: LocalizedStringHelper.formatted(
                        L10n.Notifications.vmStopped,
                        language: SettingsManager.shared.appLanguage,
                        newVM.name,
                        timeStamp
                    )
                )
            }
            if newVM.status.isFailure {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: LocalizedStringHelper.formatted(
                        L10n.Notifications.vmError,
                        language: SettingsManager.shared.appLanguage,
                        newVM.name,
                        newVM.statusText,
                        timeStamp
                    )
                )
            }
        case .timeout(let vmId):
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: operation,
                source: source,
                outcome: .timeout,
                message: "Operation result is uncertain after polling timeout",
                isError: true
            )

            if let vm = vmTableData.first(where: { $0.id == vmId }) {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: LocalizedStringHelper.formatted(
                        L10n.Notifications.vmTimeout,
                        language: SettingsManager.shared.appLanguage,
                        vm.name,
                        timeStamp
                    )
                )
            }

            if refreshOnUncertainResult {
                await refreshVMInventoryAfterOperation(source: source)
            }
        case .failed(let vmId, let message):
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: operation,
                source: source,
                outcome: .failed,
                message: message,
                isError: true
            )

            if refreshOnUncertainResult {
                await refreshVMInventoryAfterOperation(source: source)
            }
        }
    }

    private func refreshVMInventory() async throws -> [VMTableData] {
        let vms = try await api.getVMs(iamToken: iamToken)
        vmTableData = vms
        lastUpdateTime = Date()
        AppState.shared.isVirtualMachineRunning = runningVMs > 0
        return vms
    }

    private func refreshVMInventoryAfterOperation(source: VMPowerOperationSource) async {
        do {
            _ = try await refreshVMInventory()
        } catch {
            LoggerHelper.error(
                "VM inventory refresh failed after power operation source=\(source.rawValue) error=\(error.localizedDescription)"
            )
        }
    }

    private func finishProcessing(vmId: String) async {
        processingStates[vmId] = false
        await operationRegistry.finish(vmId: vmId)
    }
}
