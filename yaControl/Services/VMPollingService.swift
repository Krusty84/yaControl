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

protocol VMTransitionPolling: Sendable {
    func waitForVMTransitions(
        iamToken: String,
        initialStatuses: [String: VMStatus],
        timeout: Duration?,
        interval: Duration?,
        maxConsecutiveFailures: Int?
    ) async -> [String: VMPollingResult]
}

final class VMPollingService: @unchecked Sendable {
    static let shared = VMPollingService()

    private let inventoryService: YandexInventoryService
    private let defaultTimeout: Duration = .seconds(60)
    private let defaultInterval: Duration = .seconds(3)
    private let defaultMaxConsecutiveFailures = 4

    init(inventoryService: YandexInventoryService = .shared) {
        self.inventoryService = inventoryService
    }

    func waitForVMTransition(
        iamToken: String,
        vmId: String,
        initialStatus: VMStatus,
        timeout: Duration? = nil,
        interval: Duration? = nil,
        maxConsecutiveFailures: Int? = nil
    ) async -> VMPollingResult {
        let timeout = timeout ?? defaultTimeout
        let interval = interval ?? defaultInterval
        let maxConsecutiveFailures = maxConsecutiveFailures ?? defaultMaxConsecutiveFailures
        let start = ContinuousClock.now
        var consecutiveFailures = 0
        var lastErrorMessage: String?

        while start.duration(to: .now) < timeout {
            do {
                try await Task.sleep(for: interval)
                let vms = try await inventoryService.loadVMTableData(iamToken: iamToken)

                guard let vm = vms.first(where: { $0.id == vmId }) else {
                    consecutiveFailures += 1
                    lastErrorMessage = "VM not found in inventory"
                    LoggerHelper.error(
                        "VM polling transient failure vmId=\(vmId) attempt=\(consecutiveFailures) message=\(lastErrorMessage ?? "")"
                    )

                    if consecutiveFailures >= maxConsecutiveFailures {
                        return .failed(vmId: vmId, message: lastErrorMessage ?? "VM not found in inventory")
                    }

                    continue
                }

                consecutiveFailures = 0

                if didTransition(from: initialStatus, to: vm.status) {
                    return .changed(vm)
                }
            } catch is CancellationError {
                LoggerHelper.error("VM polling cancelled vmId=\(vmId)")
                return .failed(vmId: vmId, message: "Polling was cancelled.")
            } catch {
                if isNonRecoverable(error) {
                    return .failed(vmId: vmId, message: error.localizedDescription)
                }

                consecutiveFailures += 1
                lastErrorMessage = error.localizedDescription
                LoggerHelper.error(
                    "VM polling transient failure vmId=\(vmId) attempt=\(consecutiveFailures) message=\(error.localizedDescription)"
                )

                if consecutiveFailures >= maxConsecutiveFailures {
                    return .failed(vmId: vmId, message: lastErrorMessage ?? error.localizedDescription)
                }
            }
        }

        if let lastErrorMessage {
            LoggerHelper.error("VM polling timed out vmId=\(vmId) lastError=\(lastErrorMessage)")
        }

        return .timeout(vmId: vmId)
    }

    func waitForVMTransitions(
        iamToken: String,
        initialStatuses: [String: VMStatus],
        timeout: Duration? = nil,
        interval: Duration? = nil,
        maxConsecutiveFailures: Int? = nil
    ) async -> [String: VMPollingResult] {
        await withTaskGroup(of: (String, VMPollingResult).self) { group in
            for (vmId, initialStatus) in initialStatuses {
                group.addTask {
                    let result = await self.waitForVMTransition(
                        iamToken: iamToken,
                        vmId: vmId,
                        initialStatus: initialStatus,
                        timeout: timeout,
                        interval: interval,
                        maxConsecutiveFailures: maxConsecutiveFailures
                    )

                    return (vmId, result)
                }
            }

            var results: [String: VMPollingResult] = [:]
            for await (vmId, result) in group {
                results[vmId] = result
            }
            return results
        }
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

    private func isNonRecoverable(_ error: Error) -> Bool {
        guard let requestError = error as? YandexRequestError else {
            return false
        }

        switch requestError {
        case .invalidURL, .emptyOAuthToken:
            return true
        case .httpError(let statusCode, _):
            return statusCode == 401 || statusCode == 403 || statusCode == 404
        case .invalidResponse, .apiError, .decodingError:
            return false
        }
    }
}

extension VMPollingService: VMTransitionPolling {}
