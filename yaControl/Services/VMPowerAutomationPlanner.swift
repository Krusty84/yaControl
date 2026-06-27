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
    let skippedVMs: [VMTableData]
    let missingVMIds: [String]
}

enum VMPowerAutomationPlanner {
    static func autoStartPlan(
        selectedVMIds: [String],
        inventory: [VMTableData]
    ) -> VMPowerAutoStartPlan {
        let vmsById = Dictionary(uniqueKeysWithValues: inventory.map { ($0.id, $0) })
        var seenVMIds = Set<String>()
        var vmsToStart: [VMTableData] = []
        var alreadyRunningVMs: [VMTableData] = []
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
            } else {
                skippedVMs.append(vm)
            }
        }

        return VMPowerAutoStartPlan(
            vmsToStart: vmsToStart,
            alreadyRunningVMs: alreadyRunningVMs,
            skippedVMs: skippedVMs,
            missingVMIds: missingVMIds
        )
    }

    static func shutdownVMs(in inventory: [VMTableData]) -> [VMTableData] {
        var seenVMIds = Set<String>()

        return inventory.filter { vm in
            vm.status.isRunning && seenVMIds.insert(vm.id).inserted
        }
    }
}
