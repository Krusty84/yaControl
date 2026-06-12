//
//  VMPowerAutomationService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

final class VMPowerAutomationService {
    static let shared = VMPowerAutomationService()

    private let authAPI: YandexAuthAPI
    private let inventoryService: YandexInventoryService
    private let powerService: VMPowerService
    private let pollingService: VMPollingService
    private let operationRegistry: VMPowerOperationRegistry
    private let internetWaitTimeout: Duration = .seconds(30)

    init(
        authAPI: YandexAuthAPI = YandexAuthAPI(),
        inventoryService: YandexInventoryService = .shared,
        powerService: VMPowerService = .shared,
        pollingService: VMPollingService = .shared,
        operationRegistry: VMPowerOperationRegistry = .shared
    ) {
        self.authAPI = authAPI
        self.inventoryService = inventoryService
        self.powerService = powerService
        self.pollingService = pollingService
        self.operationRegistry = operationRegistry
    }

    func handleAppLaunch() async {
        await handleAutoStart(option: .afterAppLaunched, source: .appLaunch)
    }

    func handleAppExit() async -> Bool {
        await handleShutdown(options: [.afterAppExit, .afterMacOSShutdown], source: .appExit)
    }

    func handleMacSleep() async -> Bool {
        await handleShutdown(options: [.afterMacOSSleep], source: .macOSSleep)
    }

    func handleMacWake() async {
        await handleAutoStart(option: .afterWakeup, source: .macOSWake)
    }

    private func handleAutoStart(option: StartOption, source: VMPowerOperationSource) async {
        let autoStartEnabled = SettingsManager.shared.autoStartEnabled
        let startOptions = SettingsManager.shared.startOptions
        let token = SettingsManager.shared.oAuthKey
        let vmIds = SettingsManager.shared.getAllAutostartVMs()

        guard autoStartEnabled else {
            LoggerHelper.info("VM auto-start skipped source=\(source.rawValue) reason=disabled")
            AppState.shared.checkNumRunningVMs()
            return
        }

        guard startOptions.contains(option) else {
            LoggerHelper.info("VM auto-start skipped source=\(source.rawValue) reason=start_option_disabled")
            AppState.shared.checkNumRunningVMs()
            return
        }

        guard !vmIds.isEmpty else {
            LoggerHelper.info("VM auto-start skipped source=\(source.rawValue) reason=no_configured_vms")
            AppState.shared.checkNumRunningVMs()
            return
        }

        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            LoggerHelper.error("VM auto-start failed source=\(source.rawValue) error=\(YandexRequestError.emptyOAuthToken.localizedDescription)")
            AppState.shared.checkNumRunningVMs()
            return
        }

        let isConnected = await InternetConnectionMonitor.waitUntilConnected(timeout: internetWaitTimeout)
        guard isConnected else {
            LoggerHelper.error("VM auto-start failed source=\(source.rawValue) error=internet_wait_timeout")
            AppState.shared.checkNumRunningVMs()
            return
        }

        do {
            let authResponse = try await authAPI.checkOAuthToken(token)
            let allVMs = try await inventoryService.loadVMTableData(iamToken: authResponse.iamToken)
            SettingsManager.shared.cleanupAutostartSettings(validVMIds: Set(allVMs.map(\.id)))

            let vmsById = Dictionary(uniqueKeysWithValues: allVMs.map { ($0.id, $0) })
            var vmsToStart: [VMTableData] = []

            for vmId in vmIds {
                guard let vm = vmsById[vmId] else {
                    VMPowerOperationLogger.log(
                        vmId: vmId,
                        operation: .start,
                        source: source,
                        outcome: .skipped,
                        message: "VM is no longer present in inventory"
                    )
                    continue
                }

                if vm.status.isRunning {
                    VMPowerOperationLogger.log(
                        vmId: vm.id,
                        operation: .start,
                        source: source,
                        outcome: .completed,
                        message: "VM already running"
                    )
                } else if vm.status.isStopped {
                    vmsToStart.append(vm)
                } else {
                    VMPowerOperationLogger.log(
                        vmId: vm.id,
                        operation: .start,
                        source: source,
                        outcome: .skipped,
                        message: "Status is not actionable for auto-start: \(vm.status.rawValue)"
                    )
                }
            }

            await startVMs(vmsToStart, iamToken: authResponse.iamToken, source: source)
        } catch {
            LoggerHelper.error("VM auto-start failed source=\(source.rawValue) error=\(error.localizedDescription)")
        }

        AppState.shared.checkNumRunningVMs()
    }

    private func handleShutdown(options: [ShutdownOption], source: VMPowerOperationSource) async -> Bool {
        guard SettingsManager.shared.autoStartEnabled else {
            return true
        }

        guard SettingsManager.shared.shutdownOptions.contains(where: { options.contains($0) }) else {
            return true
        }

        let token = SettingsManager.shared.oAuthKey
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            LoggerHelper.error("VM shutdown failed source=\(source.rawValue) error=\(YandexRequestError.emptyOAuthToken.localizedDescription)")
            return false
        }

        do {
            let authResponse = try await authAPI.checkOAuthToken(token)
            LoggerHelper.info("IAM token acquired successfully source=\(source.rawValue)")

            let allVMs = try await inventoryService.loadVMTableData(iamToken: authResponse.iamToken)
            let runningVMs = allVMs.filter { $0.status.isRunning }
            LoggerHelper.info("Running VM IDs source=\(source.rawValue) ids=\(runningVMs.map(\.id))")

            guard !runningVMs.isEmpty else {
                LoggerHelper.info("No running VMs found source=\(source.rawValue)")
                return true
            }

            let failedVMIds = await stopVMs(
                runningVMs,
                iamToken: authResponse.iamToken,
                source: source
            )
            AppState.shared.checkNumRunningVMs()

            if !failedVMIds.isEmpty {
                LoggerHelper.error("VM shutdown finished with failures source=\(source.rawValue) failedVMIds=\(failedVMIds)")
            }

            return failedVMIds.isEmpty
        } catch {
            LoggerHelper.error("VM shutdown failed source=\(source.rawValue) error=\(error.localizedDescription)")
            return false
        }
    }

    private func startVMs(
        _ vms: [VMTableData],
        iamToken: String,
        source: VMPowerOperationSource
    ) async {
        let lockedVMs = await lockVMs(vms, source: source)
        guard !lockedVMs.isEmpty else { return }

        let lockedVMIds = Set(lockedVMs.map(\.id))
        defer {
            Task {
                await releaseLocks(lockedVMIds)
            }
        }

        let results = await powerService.startVMs(
            iamToken: iamToken,
            vmIds: Array(lockedVMIds)
        )
        let failedResults = results.filter { !$0.success }
        let successfulVMIds = Set(results.filter(\.success).map(\.vmId))

        for result in results where result.success {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .accepted
            )
        }

        for result in failedResults {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .failed,
                message: result.errorMessage ?? "Unknown error",
                isError: true
            )
            await operationRegistry.finish(vmId: result.vmId)
        }

        let initialStatuses = Dictionary(
            uniqueKeysWithValues: lockedVMs
                .filter { successfulVMIds.contains($0.id) }
                .map { ($0.id, $0.status) }
        )
        let pollResults = await pollingService.waitForVMTransitions(
            iamToken: iamToken,
            initialStatuses: initialStatuses
        )

        for (_, result) in pollResults {
            _ = await handlePollingResult(result, operation: .start, source: source)
        }

        await releaseLocks(lockedVMIds.subtracting(Set(failedResults.map(\.vmId))))
    }

    private func stopVMs(
        _ vms: [VMTableData],
        iamToken: String,
        source: VMPowerOperationSource
    ) async -> Set<String> {
        let lockedVMs = await lockVMs(vms, source: source)
        var failedVMIds = Set(vms.map(\.id)).subtracting(Set(lockedVMs.map(\.id)))

        guard !lockedVMs.isEmpty else {
            return failedVMIds
        }

        let lockedVMIds = Set(lockedVMs.map(\.id))
        defer {
            Task {
                await releaseLocks(lockedVMIds)
            }
        }

        let results = await powerService.stopVMs(
            iamToken: iamToken,
            vmIds: Array(lockedVMIds)
        )
        let failedResults = results.filter { !$0.success }
        let successfulVMIds = Set(results.filter(\.success).map(\.vmId))

        for result in results where result.success {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .accepted
            )
        }

        for result in failedResults {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .failed,
                message: result.errorMessage ?? "Unknown error",
                isError: true
            )
            failedVMIds.insert(result.vmId)
            await operationRegistry.finish(vmId: result.vmId)
        }

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
            let completed = await handlePollingResult(result, operation: .stop, source: source)
            if !completed {
                failedVMIds.insert(vmId)
            }
        }

        await releaseLocks(lockedVMIds.subtracting(Set(failedResults.map(\.vmId))))
        return failedVMIds
    }

    private func lockVMs(
        _ vms: [VMTableData],
        source: VMPowerOperationSource
    ) async -> [VMTableData] {
        var lockedVMs: [VMTableData] = []

        for vm in vms {
            if await operationRegistry.begin(vmId: vm.id, source: source) {
                lockedVMs.append(vm)
            }
        }

        return lockedVMs
    }

    private func releaseLocks(_ vmIds: Set<String>) async {
        for vmId in vmIds {
            await operationRegistry.finish(vmId: vmId)
        }
    }

    private func handlePollingResult(
        _ result: VMPollingResult,
        operation: VMOperation,
        source: VMPowerOperationSource
    ) async -> Bool {
        let timeStamp = Date().formatted(.dateTime.hour().minute().second())

        switch result {
        case .changed(let vm):
            let completed = vm.status == operation.targetStatus
            VMPowerOperationLogger.log(
                vmId: vm.id,
                operation: operation,
                source: source,
                outcome: completed ? .completed : .failed,
                message: "status=\(vm.status.rawValue)",
                isError: !completed
            )

            postNotificationIfNeeded(vm: vm, operation: operation, timeStamp: timeStamp)
            return completed
        case .timeout(let vmId):
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: operation,
                source: source,
                outcome: .timeout,
                message: "Operation result is uncertain after polling timeout",
                isError: true
            )
            return false
        case .failed(let vmId, let message):
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: operation,
                source: source,
                outcome: .failed,
                message: message,
                isError: true
            )
            return false
        }
    }

    private func postNotificationIfNeeded(
        vm: VMTableData,
        operation: VMOperation,
        timeStamp: String
    ) {
        if operation == .start, vm.status.isRunning {
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmStarted,
                    language: SettingsManager.shared.appLanguage,
                    vm.name,
                    timeStamp
                )
            )
        } else if operation == .stop, vm.status.isStopped {
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmStopped,
                    language: SettingsManager.shared.appLanguage,
                    vm.name,
                    timeStamp
                )
            )
        } else if vm.status.isFailure {
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmError,
                    language: SettingsManager.shared.appLanguage,
                    vm.name,
                    vm.statusText,
                    timeStamp
                )
            )
        }
    }

}
