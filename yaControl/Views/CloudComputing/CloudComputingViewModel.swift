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
    private let helpers = Helpers.shared
    private var iamToken = ""

    // MARK: - Computed helpers
    var filteredVMs: [VMTableData] {
        guard !searchText.isEmpty else { return vmTableData }
        return vmTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    var totalVMs: Int { vmTableData.count }
    var runningVMs: Int { vmTableData.filter { $0.status == "RUNNING" }.count }

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
        // Start or stop via helper
        helpers.startStopVM(iamToken: iamToken, for: vm)
        pollVMStatus(for: vm.id)
    }

    func stopAllAndPoll() {
        // 1) Filter to just the running VMs
        let runningList = vmTableData.filter { $0.status == "RUNNING" }

        // 2) Tell the helper to stop _only_ those
        helpers.stopAllRunningVMs(iamToken: iamToken, vms: runningList)

        // 3) Start polling on just those
        for vm in runningList {
            pollVMStatus(for: vm.id)
        }
    }

    // MARK: - Polling
    
    func pollVMStatus(for vmID: String) {
        let initialIsRunning = vmTableData.first { $0.id == vmID }?.status == "RUNNING"
        processingStates[vmID] = true

        Task {
            var retry = 0
            let maxRetries = 20
            let interval: UInt64 = 3_000_000_000

            while retry < maxRetries {
                try? await Task.sleep(nanoseconds: interval)
                do {
                    let updatedVMs = try await api.getVMs(iamToken: iamToken)
                    if let newVM = updatedVMs.first(where: { $0.id == vmID }) {
                        await MainActor.run {
                            if let idx = vmTableData.firstIndex(where: { $0.id == vmID }) {
                                vmTableData[idx] = newVM
                            }
                            AppState.shared.isVirtualMachineRunning = runningVMs > 0
                        }

                        // format current time
                        let timeStamp = Date()
                            .formatted(.dateTime.hour().minute().second())
                        let name = newVM.name

                        // Detect transitions
                        if !initialIsRunning && newVM.status == "RUNNING" {
                            NotificationManager.shared.postNotification(
                                title: "yaControl",
                                body: "VM: \(name) has started. [\(timeStamp)]"
                            )
                            break
                        }
                        if initialIsRunning && newVM.status == "STOPPED" {
                            NotificationManager.shared.postNotification(
                                title: "yaControl",
                                body: "VM: \(name) has stopped. [\(timeStamp)]"
                            )
                            break
                        }
                        if ["ERROR", "CRASHED"].contains(newVM.status) {
                            NotificationManager.shared.postNotification(
                                title: "yaControl",
                                body: "VM: \(name) error: \(newVM.status). [\(timeStamp)]"
                            )
                            break
                        }
                    }
                } catch {
                    // ignore and retry
                }
                retry += 1
            }

            // timeout case
            if retry >= maxRetries,
               let vm = vmTableData.first(where: { $0.id == vmID }) {
                let timeStamp = Date()
                    .formatted(.dateTime.hour().minute().second())
                NotificationManager.shared.postNotification(
                    title: "yaControl",
                    body: "VM: Timeout: couldn’t verify status for \(vm.name). [\(timeStamp)]"
                )
            }

            processingStates[vmID] = false
        }
    }


}
