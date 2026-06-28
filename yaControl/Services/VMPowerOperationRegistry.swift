//
//  VMPowerOperationRegistry.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 12/06/2026.
//

import Foundation

enum VMPowerOperationSource: String, Sendable {
    case manualUI = "manual_ui"
    case stopAll = "stop_all"
    case appLaunch = "app_launch"
    case appExit = "app_exit"
    case macOSSleep = "macos_sleep"
    case macOSWake = "macos_wake"
    case macOSPowerOff = "macos_power_off"
}

enum VMPowerOperationOutcome: String, Sendable {
    case accepted
    case completed
    case timeout
    case skipped
    case failed
}

actor VMPowerOperationRegistry {
    static let shared = VMPowerOperationRegistry()

    private var activeVMIds: Set<String> = []

    func begin(vmId: String, source: VMPowerOperationSource) async -> Bool {
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
        await MainActor.run {
            AppState.shared.beginVMPowerActivity()
        }
        return true
    }

    func finish(vmId: String) async {
        let wasActive = activeVMIds.remove(vmId) != nil
        guard wasActive else { return }

        await MainActor.run {
            AppState.shared.endVMPowerActivity()
        }
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
