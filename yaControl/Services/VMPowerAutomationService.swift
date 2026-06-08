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

    init(
        authAPI: YandexAuthAPI = YandexAuthAPI(),
        inventoryService: YandexInventoryService = .shared,
        powerService: VMPowerService = .shared,
        pollingService: VMPollingService = .shared
    ) {
        self.authAPI = authAPI
        self.inventoryService = inventoryService
        self.powerService = powerService
        self.pollingService = pollingService
    }

    func handleAppLaunch() async {
        await handleAutoStart(option: .afterAppLaunched)
    }

    func handleAppExit() async -> Bool {
        await handleShutdown(options: [.afterAppExit, .afterMacOSShutdown])
    }

    func handleMacSleep() async -> Bool {
        await handleShutdown(options: [.afterMacOSSleep])
    }

    func handleMacWake() async {
        await handleAutoStart(option: .afterWakeup)
    }

    private func handleAutoStart(option: StartOption) async {
        let autoStartEnabled = SettingsManager.shared.autoStartEnabled
        let startOptions = SettingsManager.shared.startOptions
        let token = SettingsManager.shared.oAuthKey
        let vmIds = SettingsManager.shared.getAllAutostartVMs()

        await InternetConnectionMonitor.waitUntilConnected()

        guard autoStartEnabled, startOptions.contains(option), !vmIds.isEmpty else {
            LoggerHelper.info("No VMs selected for auto-start on app launch")
            AppState.shared.checkNumRunningVMs()
            return
        }

        do {
            let authResponse = try await authAPI.checkOAuthToken(token)
            let results = await powerService.startVMs(iamToken: authResponse.iamToken, vmIds: vmIds)

            for result in results {
                if result.success {
                    LoggerHelper.info("VM started successfully: \(result.vmId)")
                    await notifyWhenVMTransitionCompletes(
                        iamToken: authResponse.iamToken,
                        vmId: result.vmId,
                        initialStatus: .stopped
                    )
                } else {
                    LoggerHelper.error("Failed to start VM \(result.vmId): \(result.errorMessage ?? "Unknown error")")
                }
            }
        } catch {
            LoggerHelper.error("Auto-start failed: \(error.localizedDescription)")
        }

        AppState.shared.checkNumRunningVMs()
    }

    private func handleShutdown(options: [ShutdownOption]) async -> Bool {
        guard SettingsManager.shared.autoStartEnabled else {
            return true
        }

        guard SettingsManager.shared.shutdownOptions.contains(where: { options.contains($0) }) else {
            return true
        }

        do {
            let authResponse = try await authAPI.checkOAuthToken(SettingsManager.shared.oAuthKey)
            LoggerHelper.info("IAM token acquired successfully")

            let allVMs = try await inventoryService.loadVMTableData(iamToken: authResponse.iamToken)
            let runningVMIds = allVMs.filter { $0.status.isRunning }.map(\.id)
            LoggerHelper.info("Running VM IDs: \(runningVMIds)")

            guard !runningVMIds.isEmpty else {
                LoggerHelper.info("No running VMs found")
                return true
            }

            let results = await powerService.stopVMs(
                iamToken: authResponse.iamToken,
                vmIds: runningVMIds
            )

            for result in results {
                if result.success {
                    LoggerHelper.info("Successfully stopped VM: \(result.vmId)")
                } else {
                    LoggerHelper.error("Failed to stop VM \(result.vmId): \(result.errorMessage ?? "Unknown error")")
                }
            }

            return results.allSatisfy(\.success)
        } catch {
            LoggerHelper.error("Operation failed: \(error.localizedDescription)")
            return false
        }
    }

    private func notifyWhenVMTransitionCompletes(
        iamToken: String,
        vmId: String,
        initialStatus: VMStatus
    ) async {
        let result = await pollingService.waitForVMTransition(
            iamToken: iamToken,
            vmId: vmId,
            initialStatus: initialStatus,
            timeout: .seconds(60),
            interval: .seconds(3)
        )
        let timeStamp = Date().formatted(.dateTime.hour().minute().second())

        switch result {
        case .changed(let vm):
            if vm.status.isRunning {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: \(vm.name) has started. [\(timeStamp)]"
                )
            } else if vm.status.isStopped {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: \(vm.name) has stopped. [\(timeStamp)]"
                )
            } else if vm.status.isFailure {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: \(vm.name) error: \(vm.statusText). [\(timeStamp)]"
                )
            }
        case .timeout(let vmId):
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: "VM: Timeout: couldn’t verify status for ID \(vmId). [\(timeStamp)]"
            )
        case .failed(let vmId, let message):
            LoggerHelper.error("Polling VM \(vmId) failed: \(message)")
        }
    }
}
