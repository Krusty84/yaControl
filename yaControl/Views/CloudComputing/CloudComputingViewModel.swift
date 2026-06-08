//
//  CloudComputingViewModel.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 01/05/2025.
//

import SwiftUI
import UserNotifications

@MainActor
class CloudComputingViewModel: ObservableObject {
    // MARK: - Published state
    @Published var vmTableData: [VMTableData] = []
    @Published var billingData: [BillingTableData] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchText = ""
    @Published var currentBalance = ""
    @Published var currency = ""
    @Published var billingUrl: URL? = nil
    @Published var lastUpdateTime = Date()
    @Published var processingStates: [String: Bool] = [:]   // VM ID -> isProcessing

    private let api = YandexAPIService.shared
    private let powerService = VMPowerService.shared
    private let pollingService = VMPollingService.shared
    private var iamToken = ""

    // MARK: - Computed helpers
    var filteredVMs: [VMTableData] {
        guard !searchText.isEmpty else { return vmTableData }
        return vmTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    var totalVMs: Int { vmTableData.count }
    var runningVMs: Int { vmTableData.filter { $0.status.isRunning }.count }

    // MARK: - Actions
    func fetchVMs() async {
        isLoading = true
        errorMessage = nil

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
            errorMessage = error.localizedDescription
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
        guard processingStates[vm.id] != true else { return }
        processingStates[vm.id] = true

        Task {
            do {
                if vm.status.isRunning {
                    try await powerService.stopVM(iamToken: iamToken, vmId: vm.id)
                    LoggerHelper.info("VM stopped successfully")
                } else if vm.status.isStopped {
                    try await powerService.startVM(iamToken: iamToken, vmId: vm.id)
                    LoggerHelper.info("VM started successfully")
                }

                await pollVMStatus(for: vm.id, initialStatus: vm.status)
            } catch {
                LoggerHelper.error(
                    "Failed to \(vm.status.isRunning ? "stop" : "start") VM: \(error.localizedDescription)"
                )
                processingStates[vm.id] = false
            }
        }
    }

    func stopAllAndPoll() {
        // 1) Filter to just the running VMs
        let runningList = vmTableData.filter { $0.status.isRunning }

        Task {
            let results = await powerService.stopRunningVMs(iamToken: iamToken, vms: runningList)
            for result in results where !result.success {
                LoggerHelper.error("Error stopping VM \(result.vmId): \(result.errorMessage ?? "Unknown error")")
            }
            for vm in runningList {
                processingStates[vm.id] = true
                await pollVMStatus(for: vm.id, initialStatus: vm.status)
            }
        }
    }

    // MARK: - Polling
    
    private func pollVMStatus(for vmID: String, initialStatus: VMStatus) async {
        let result = await pollingService.waitForVMTransition(
            iamToken: iamToken,
            vmId: vmID,
            initialStatus: initialStatus,
            timeout: .seconds(60),
            interval: .seconds(3)
        )
        let timeStamp = Date().formatted(.dateTime.hour().minute().second())

        switch result {
        case .changed(let newVM):
            if let idx = vmTableData.firstIndex(where: { $0.id == vmID }) {
                vmTableData[idx] = newVM
            }
            AppState.shared.isVirtualMachineRunning = runningVMs > 0

            if !initialStatus.isRunning && newVM.status.isRunning {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: \(newVM.name) has started. [\(timeStamp)]"
                )
            }
            if initialStatus.isRunning && newVM.status.isStopped {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: \(newVM.name) has stopped. [\(timeStamp)]"
                )
            }
            if newVM.status.isFailure {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: \(newVM.name) error: \(newVM.statusText). [\(timeStamp)]"
                )
            }
        case .timeout:
            if let vm = vmTableData.first(where: { $0.id == vmID }) {
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: Timeout: couldn’t verify status for \(vm.name). [\(timeStamp)]"
                )
            }
        case .failed(let vmId, let message):
            LoggerHelper.error("Polling VM \(vmId) failed: \(message)")
        }

        processingStates[vmID] = false
    }
}
