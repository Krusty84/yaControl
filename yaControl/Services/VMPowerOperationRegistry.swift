//
//  VMPowerOperationRegistry.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 12/06/2026.
//

import Foundation

enum VMPowerOperationSource: String {
    case manualUI = "manual_ui"
    case stopAll = "stop_all"
    case appLaunch = "app_launch"
    case appExit = "app_exit"
    case macOSSleep = "macos_sleep"
    case macOSWake = "macos_wake"
}

enum VMPowerOperationOutcome: String {
    case accepted
    case completed
    case timeout
    case skipped
    case failed
}

actor VMPowerOperationRegistry {
    static let shared = VMPowerOperationRegistry()

    private var activeVMIds: Set<String> = []

    func begin(vmId: String, source: VMPowerOperationSource) -> Bool {
        guard !activeVMIds.contains(vmId) else {
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: nil,
                source: source,
                outcome: .skipped,
                message: "Operation already active for VM"
            )
            return false
        }

        activeVMIds.insert(vmId)
        return true
    }

    func finish(vmId: String) {
        activeVMIds.remove(vmId)
    }
}

enum VMPowerOperationLogger {
    static func log(
        vmId: String,
        operation: VMOperation?,
        source: VMPowerOperationSource,
        outcome: VMPowerOperationOutcome,
        message: String? = nil,
        isError: Bool = false
    ) {
        let operationValue = operation?.rawValue ?? "unknown"
        var logMessage = "VM power operation vmId=\(vmId) operation=\(operationValue) source=\(source.rawValue) result=\(outcome.rawValue)"

        if let message, !message.isEmpty {
            logMessage += " message=\(message)"
        }

        if isError {
            LoggerHelper.error(logMessage)
        } else {
            LoggerHelper.info(logMessage)
        }
    }
}
