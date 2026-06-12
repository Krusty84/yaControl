//
//  VMPowerService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum VMOperation: String {
    case start
    case stop

    var requiredStatus: VMStatus {
        switch self {
        case .start:
            .stopped
        case .stop:
            .running
        }
    }

    var targetStatus: VMStatus {
        switch self {
        case .start:
            .running
        case .stop:
            .stopped
        }
    }

    func isAlreadyCompleted(status: VMStatus) -> Bool {
        status == targetStatus
    }

    func canSendRequest(status: VMStatus) -> Bool {
        status == requiredStatus
    }
}

struct VMOperationResult: Identifiable, Equatable {
    let id: String
    let vmId: String
    let operation: VMOperation
    let success: Bool
    let errorMessage: String?
}

final class VMPowerService: @unchecked Sendable {
    static let shared = VMPowerService()

    private let computeAPI: YandexComputeAPI

    init(computeAPI: YandexComputeAPI = YandexComputeAPI()) {
        self.computeAPI = computeAPI
    }

    func startVM(iamToken: String, vmId: String) async throws {
        try await computeAPI.startVM(iamToken: iamToken, vmId: vmId)
    }

    func stopVM(iamToken: String, vmId: String) async throws {
        try await computeAPI.stopVM(iamToken: iamToken, vmId: vmId)
    }

    func startVMs(iamToken: String, vmIds: [String]) async -> [VMOperationResult] {
        await performVMOperations(iamToken: iamToken, vmIds: vmIds, operation: .start)
    }

    func stopVMs(iamToken: String, vmIds: [String]) async -> [VMOperationResult] {
        await performVMOperations(iamToken: iamToken, vmIds: vmIds, operation: .stop)
    }

    func stopRunningVMs(
        iamToken: String,
        vms: [VMTableData]
    ) async -> [VMOperationResult] {
        let runningVMIds = vms.filter { $0.status.isRunning }.map(\.id)
        return await stopVMs(iamToken: iamToken, vmIds: runningVMIds)
    }

    private func performVMOperations(
        iamToken: String,
        vmIds: [String],
        operation: VMOperation
    ) async -> [VMOperationResult] {
        await withTaskGroup(of: VMOperationResult.self) { group in
            for vmId in vmIds {
                group.addTask {
                    do {
                        switch operation {
                        case .start:
                            try await self.startVM(iamToken: iamToken, vmId: vmId)
                        case .stop:
                            try await self.stopVM(iamToken: iamToken, vmId: vmId)
                        }

                        return VMOperationResult(
                            id: "\(operation.rawValue)-\(vmId)",
                            vmId: vmId,
                            operation: operation,
                            success: true,
                            errorMessage: nil
                        )
                    } catch {
                        return VMOperationResult(
                            id: "\(operation.rawValue)-\(vmId)",
                            vmId: vmId,
                            operation: operation,
                            success: false,
                            errorMessage: error.localizedDescription
                        )
                    }
                }
            }

            var results: [VMOperationResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
}
