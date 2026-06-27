//
//  VMPowerAutomationPlanner.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import Foundation

struct VMPowerAutoStartPlan: Equatable {
    let vmsToStart: [VMTableData]
    let alreadyRunningVMs: [VMTableData]
    let deferredVMs: [VMTableData]
    let skippedVMs: [VMTableData]
    let missingVMIds: [String]
}

struct VMPowerShutdownPlan: Equatable {
    let vmsToStop: [VMTableData]
    let skippedVMs: [VMTableData]
    let missingVMIds: [String]
}

enum VMPowerAutomationPlanner {
    static func autoStartPlan(
        selectedVMIds: [String],
        inventory: [VMTableData]
    ) -> VMPowerAutoStartPlan {
        let vmsById = uniqueVMsById(inventory)
        var seenVMIds = Set<String>()
        var vmsToStart: [VMTableData] = []
        var alreadyRunningVMs: [VMTableData] = []
        var deferredVMs: [VMTableData] = []
        var skippedVMs: [VMTableData] = []
        var missingVMIds: [String] = []

        for vmId in selectedVMIds where seenVMIds.insert(vmId).inserted {
            guard let vm = vmsById[vmId] else {
                missingVMIds.append(vmId)
                continue
            }

            if vm.status.isRunning {
                alreadyRunningVMs.append(vm)
            } else if vm.status.isStopped {
                vmsToStart.append(vm)
            } else if vm.status.isTransitioning {
                deferredVMs.append(vm)
            } else {
                skippedVMs.append(vm)
            }
        }

        return VMPowerAutoStartPlan(
            vmsToStart: vmsToStart,
            alreadyRunningVMs: alreadyRunningVMs,
            deferredVMs: deferredVMs,
            skippedVMs: skippedVMs,
            missingVMIds: missingVMIds
        )
    }

    static func shutdownPlan(
        selectedVMIds: [String],
        inventory: [VMTableData]
    ) -> VMPowerShutdownPlan {
        let vmsById = uniqueVMsById(inventory)
        var seenVMIds = Set<String>()
        var vmsToStop: [VMTableData] = []
        var skippedVMs: [VMTableData] = []
        var missingVMIds: [String] = []

        for vmId in selectedVMIds where seenVMIds.insert(vmId).inserted {
            guard let vm = vmsById[vmId] else {
                missingVMIds.append(vmId)
                continue
            }

            if vm.status.isRunning {
                vmsToStop.append(vm)
            } else {
                skippedVMs.append(vm)
            }
        }

        return VMPowerShutdownPlan(
            vmsToStop: vmsToStop,
            skippedVMs: skippedVMs,
            missingVMIds: missingVMIds
        )
    }

    private static func uniqueVMsById(_ inventory: [VMTableData]) -> [String: VMTableData] {
        inventory.reduce(into: [String: VMTableData]()) { result, vm in
            if result[vm.id] == nil {
                result[vm.id] = vm
            }
        }
    }
}
