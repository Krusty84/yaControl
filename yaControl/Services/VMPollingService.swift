//
//  VMPollingService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum VMPollingResult {
    case changed(VMTableData)
    case timeout(vmId: String)
    case failed(vmId: String, message: String)
}

final class VMPollingService {
    static let shared = VMPollingService()

    private let inventoryService: YandexInventoryService

    init(inventoryService: YandexInventoryService = .shared) {
        self.inventoryService = inventoryService
    }

    func waitForVMTransition(
        iamToken: String,
        vmId: String,
        initialStatus: VMStatus,
        timeout: Duration,
        interval: Duration
    ) async -> VMPollingResult {
        let start = ContinuousClock.now

        while start.duration(to: .now) < timeout {
            do {
                try await Task.sleep(for: interval)
                let vms = try await inventoryService.loadVMTableData(iamToken: iamToken)

                guard let vm = vms.first(where: { $0.id == vmId }) else {
                    continue
                }

                if didTransition(from: initialStatus, to: vm.status) {
                    return .changed(vm)
                }
            } catch {
                return .failed(vmId: vmId, message: error.localizedDescription)
            }
        }

        return .timeout(vmId: vmId)
    }

    private func didTransition(from initialStatus: VMStatus, to status: VMStatus) -> Bool {
        if !initialStatus.isRunning && status.isRunning {
            return true
        }
        if initialStatus.isRunning && status.isStopped {
            return true
        }
        if status.isFailure {
            return true
        }
        return false
    }
}
