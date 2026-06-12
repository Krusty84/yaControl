//
//  Helpers.swift - Compatibility wrappers for focused helpers/services
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import SwiftUI

class Helpers: ObservableObject {
    static let shared = Helpers()

    func restResponseToString(for intValue: Binding<Int?>) -> Binding<String> {
        BindingAdapters.restResponseToString(for: intValue)
    }

    func convertGMTToLocalTime(utcDateString: String) -> String {
        DateFormattingHelper.convertGMTToLocalTime(utcDateString: utcDateString)
    }

    @available(*, deprecated, message: "Use VMPowerService instead.")
    func startStopVM(iamToken: String, for vm: VMTableData) {
        Task {
            do {
                if vm.status.isRunning {
                    try await VMPowerService.shared.stopVM(iamToken: iamToken, vmId: vm.id)
                    LoggerHelper.info("VM stopped successfully")
                } else if vm.status.isStopped {
                    try await VMPowerService.shared.startVM(iamToken: iamToken, vmId: vm.id)
                    LoggerHelper.info("VM started successfully")
                }
            } catch {
                LoggerHelper.error(
                    "Failed to \(vm.status.isRunning ? "stop" : "start") VM: \(error.localizedDescription)"
                )
            }
        }
    }

    @available(*, deprecated, message: "Use VMPowerService instead.")
    func stopAllRunningVMs(iamToken: String, vms: [VMTableData]? = nil, vmIds: [String]? = nil) {
        Task {
            let results: [VMOperationResult]
            if let vms {
                results = await VMPowerService.shared.stopRunningVMs(iamToken: iamToken, vms: vms)
            } else if let vmIds {
                results = await VMPowerService.shared.stopVMs(iamToken: iamToken, vmIds: vmIds)
            } else {
                results = []
            }

            for result in results where !result.success {
                LoggerHelper.error("Error stopping VM \(result.vmId): \(result.errorMessage ?? "Unknown error")")
            }
        }
    }

    @available(*, deprecated, message: "Use VMPowerAutomationService or VMPowerService instead.")
    func startAllMarkedVMs(iamToken: String, vmIds: [String]? = nil) async {
        let vmIdsToStart = vmIds ?? SettingsManager.shared.getAllAutostartVMs()

        guard !vmIdsToStart.isEmpty else {
            LoggerHelper.info("No VMs marked for auto-start")
            return
        }

        let results = await VMPowerService.shared.startVMs(iamToken: iamToken, vmIds: vmIdsToStart)

        for result in results {
            if result.success {
                LoggerHelper.info("VM started successfully: \(result.vmId)")
                await notifyWhenVMTransitionCompletes(
                    iamToken: iamToken,
                    vmId: result.vmId,
                    initialStatus: .stopped
                )
            } else {
                LoggerHelper.error("Failed to start VM \(result.vmId): \(result.errorMessage ?? "Unknown error")")
            }
        }
    }

    func openTerminal() {
        TerminalLauncher.openTerminal()
    }

    func openRDPClient(to ip: String, username: String = "Administrator") {
        RDPFileLauncher.openRDPClient(to: ip, username: username)
    }

    func convertBytesToGB(bytes: String) -> String {
        ByteFormattingHelper.convertBytesToGB(bytes: bytes)
    }

    static func checkInternetConnection(completion: @escaping () -> Void) {
        InternetConnectionMonitor.runWhenConnected(completion)
    }

    static func billingBalanceFormatter(
        amount: String,
        currency: String,
        warningThreshold: Double = 50.0
    ) -> AttributedString {
        BillingFormattingHelper.balanceAttributedString(
            amount: amount,
            currency: currency,
            warningThreshold: warningThreshold
        )
    }

    private func notifyWhenVMTransitionCompletes(
        iamToken: String,
        vmId: String,
        initialStatus: VMStatus
    ) async {
        let result = await VMPollingService.shared.waitForVMTransition(
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
                    body: LocalizedStringHelper.formatted(
                        L10n.Notifications.vmStarted,
                        language: SettingsManager.shared.appLanguage,
                        vm.name,
                        timeStamp
                    )
                )
            } else if vm.status.isStopped {
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
        case .timeout(let vmId):
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmTimeoutID,
                    language: SettingsManager.shared.appLanguage,
                    vmId,
                    timeStamp
                )
            )
        case .failed(let vmId, let message):
            LoggerHelper.error("Polling VM \(vmId) failed: \(message)")
        }
    }
}
