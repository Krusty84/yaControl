//
//  VMPowerAutomationService.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

struct CachedIAMToken: Sendable {
    let value: String
    let expiresAt: Date
}

enum ShutdownExecutionMode: Sendable {
    case normal
    case fastTermination
}

actor IAMTokenCache {
    private var cachedToken: CachedIAMToken?
    private let expiryLeeway: TimeInterval = 60

    func validToken(now: Date = Date()) -> CachedIAMToken? {
        guard let cachedToken else { return nil }
        guard cachedToken.expiresAt.timeIntervalSince(now) > expiryLeeway else { return nil }

        return cachedToken
    }

    func store(_ authResponse: AuthResponse) {
        guard let expiresAt = ISO8601DateFormatter().date(from: authResponse.expiresAt) else {
            return
        }

        cachedToken = CachedIAMToken(value: authResponse.iamToken, expiresAt: expiresAt)
    }
}

final class VMPowerAutomationService: @unchecked Sendable {
    static let shared = VMPowerAutomationService()

    private let settingsManager: any VMPowerAutomationSettingsProviding
    private let authAPI: any YandexAuthenticating
    private let inventoryService: any VMInventoryLoading
    private let powerService: any VMPowerControlling
    private let pollingService: any VMTransitionPolling
    private let operationRegistry: VMPowerOperationRegistry
    private let wakeAutoStartCoordinator: WakeAutoStartCoordinator
    private let iamTokenCache: IAMTokenCache
    private let refreshRunningVMState: @Sendable () async -> Void
    private let waitUntilConnected: @Sendable (Duration) async -> Bool
    private let internetWaitTimeout: Duration = .seconds(30)
    private let wakeRetryPolicy: VMPowerAutomationRetryPolicy

    init(
        settingsManager: any VMPowerAutomationSettingsProviding = SettingsManager.shared,
        authAPI: any YandexAuthenticating = YandexAuthAPI(),
        inventoryService: any VMInventoryLoading = YandexInventoryService.shared,
        powerService: any VMPowerControlling = VMPowerService.shared,
        pollingService: any VMTransitionPolling = VMPollingService.shared,
        operationRegistry: VMPowerOperationRegistry = .shared,
        wakeAutoStartCoordinator: WakeAutoStartCoordinator = .shared,
        iamTokenCache: IAMTokenCache = IAMTokenCache(),
        refreshRunningVMState: @escaping @Sendable () async -> Void = {
            await MainActor.run {
                AppState.shared.checkNumRunningVMs()
            }
        },
        waitUntilConnected: @escaping @Sendable (Duration) async -> Bool = { timeout in
            await InternetConnectionMonitor.waitUntilConnected(timeout: timeout)
        },
        wakeRetryPolicy: VMPowerAutomationRetryPolicy = .wake
    ) {
        self.settingsManager = settingsManager
        self.authAPI = authAPI
        self.inventoryService = inventoryService
        self.powerService = powerService
        self.pollingService = pollingService
        self.operationRegistry = operationRegistry
        self.wakeAutoStartCoordinator = wakeAutoStartCoordinator
        self.iamTokenCache = iamTokenCache
        self.refreshRunningVMState = refreshRunningVMState
        self.waitUntilConnected = waitUntilConnected
        self.wakeRetryPolicy = wakeRetryPolicy
    }

    func handleAppLaunch() async {
        await handleAutoStart(option: .afterAppLaunched, source: .appLaunch)
    }

    func handleAppExit() async -> Bool {
        await handleShutdown(option: .afterAppExit, source: .appExit, mode: .normal)
    }

    func handleMacSleep() async -> Bool {
        await handleShutdown(option: .beforeMacOSSleep, source: .macOSSleep, mode: .fastTermination)
    }

    func handleMacOSShutdown() async -> Bool {
        await handleShutdown(option: .beforeMacOSLogout, source: .macOSPowerOff, mode: .fastTermination)
    }

    func handleMacWake() async {
        LoggerHelper.info("Wake auto-start notification received")
        await wakeAutoStartCoordinator.start { [self] in
            let result = await makeWakeAutoStartWorkflow().run()
            LoggerHelper.info("Wake auto-start workflow finished result=\(result)")
            await refreshRunningVMState()
        }
    }

    private func handleAutoStart(option: StartOption, source: VMPowerOperationSource) async {
        let autoStartEnabled = settingsManager.autoStartEnabled
        let startOptions = settingsManager.startOptions
        let token = settingsManager.oAuthKey
        let vmIds = settingsManager.getAllAutostartVMs()

        guard autoStartEnabled else {
            LoggerHelper.info("VM auto-start skipped source=\(source.rawValue) reason=disabled")
            await refreshRunningVMState()
            return
        }

        guard startOptions.contains(option) else {
            LoggerHelper.info("VM auto-start skipped source=\(source.rawValue) reason=start_option_disabled")
            await refreshRunningVMState()
            return
        }

        guard !vmIds.isEmpty else {
            LoggerHelper.info("VM auto-start skipped source=\(source.rawValue) reason=no_configured_vms")
            await refreshRunningVMState()
            return
        }

        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            LoggerHelper.error("VM auto-start failed source=\(source.rawValue) error=\(YandexRequestError.emptyOAuthToken.localizedDescription)")
            await refreshRunningVMState()
            return
        }

        let isConnected = await waitUntilConnected(internetWaitTimeout)
        guard isConnected else {
            LoggerHelper.error("VM auto-start failed source=\(source.rawValue) error=internet_wait_timeout")
            await refreshRunningVMState()
            return
        }

        do {
            let authResponse = try await authAPI.checkOAuthToken(token)
            await iamTokenCache.store(authResponse)
            let allVMs = try await inventoryService.loadVMTableData(iamToken: authResponse.iamToken)
            settingsManager.cleanupAutostartSettings(validVMIds: Set(allVMs.map(\.id)))

            let autoStartPlan = VMPowerAutomationPlanner.autoStartPlan(
                selectedVMIds: vmIds,
                inventory: allVMs
            )

            for vmId in autoStartPlan.missingVMIds {
                VMPowerOperationLogger.log(
                    vmId: vmId,
                    operation: .start,
                    source: source,
                    outcome: .skipped,
                    message: "VM is no longer present in inventory"
                )
            }

            for vm in autoStartPlan.alreadyRunningVMs {
                VMPowerOperationLogger.log(
                    vmId: vm.id,
                    operation: .start,
                    source: source,
                    outcome: .completed,
                    message: "VM already running"
                )
            }

            for vm in autoStartPlan.deferredVMs {
                VMPowerOperationLogger.log(
                    vmId: vm.id,
                    operation: .start,
                    source: source,
                    outcome: .skipped,
                    message: "Status is deferred for auto-start: \(vm.status.rawValue)"
                )
            }

            for vm in autoStartPlan.skippedVMs {
                VMPowerOperationLogger.log(
                    vmId: vm.id,
                    operation: .start,
                    source: source,
                    outcome: .skipped,
                    message: "Status is not actionable for auto-start: \(vm.status.rawValue)"
                )
            }

            await startVMs(autoStartPlan.vmsToStart, iamToken: authResponse.iamToken, source: source)
            if !autoStartPlan.vmsToStart.isEmpty {
                notifyVMInventoryDidChange()
            }
        } catch {
            LoggerHelper.error("VM auto-start failed source=\(source.rawValue) error=\(error.localizedDescription)")
        }

        await refreshRunningVMState()
    }

    func isShutdownConfigured(option: ShutdownOption) -> Bool {
        settingsManager.autoStartEnabled
        && settingsManager.shutdownOptions.contains(option)
        && !uniqueVMIds(settingsManager.getAllAutostartVMs()).isEmpty
    }

    func handleShutdown(
        option: ShutdownOption,
        source: VMPowerOperationSource,
        mode: ShutdownExecutionMode
    ) async -> Bool {
        guard settingsManager.autoStartEnabled else {
            LoggerHelper.info("VM shutdown skipped source=\(source.rawValue) reason=power_management_disabled")
            return true
        }

        guard settingsManager.shutdownOptions.contains(option) else {
            LoggerHelper.info("VM shutdown skipped source=\(source.rawValue) reason=option_disabled")
            return true
        }

        let vmIds = uniqueVMIds(settingsManager.getAllAutostartVMs())
        guard !vmIds.isEmpty else {
            LoggerHelper.info("VM shutdown skipped source=\(source.rawValue) reason=no_selected_vms")
            return true
        }

        do {
            guard !Task.isCancelled else {
                LoggerHelper.info("VM shutdown cancelled source=\(source.rawValue)")
                return false
            }

            let iamToken = try await iamTokenForShutdown(source: source)
            LoggerHelper.info("VM shutdown started source=\(source.rawValue) selectedVMCount=\(vmIds.count) mode=\(mode)")
            let failedVMIds = await sendStopCommandsOnly(
                vmIds: vmIds,
                iamToken: iamToken,
                source: source
            )

            if !failedVMIds.isEmpty {
                LoggerHelper.error("VM shutdown failed source=\(source.rawValue) failedVMIds=\(failedVMIds)")
                return false
            }

            LoggerHelper.info("VM shutdown completed source=\(source.rawValue)")
            notifyVMInventoryDidChange()
            return failedVMIds.isEmpty
        } catch is CancellationError {
            LoggerHelper.info("VM shutdown cancelled source=\(source.rawValue)")
            return false
        } catch {
            LoggerHelper.error("VM shutdown failed source=\(source.rawValue) error=\(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    private func startVMs(
        _ vms: [VMTableData],
        iamToken: String,
        source: VMPowerOperationSource
    ) async -> Bool {
        let lockedVMs = await lockVMs(vms, source: source)
        guard !lockedVMs.isEmpty else { return false }

        let lockedVMIds = Set(lockedVMs.map(\.id))
        defer {
            Task {
                await releaseLocks(lockedVMIds)
            }
        }

        guard !Task.isCancelled else {
            await releaseLocks(lockedVMIds)
            return false
        }

        let results = await powerService.startVMs(
            iamToken: iamToken,
            vmIds: Array(lockedVMIds)
        )
        let failedResults = results.filter { !$0.success }
        let successfulVMIds = Set(results.filter(\.success).map(\.vmId))

        for result in results where result.success {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .accepted
            )
        }

        for result in failedResults {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .failed,
                message: result.errorMessage ?? "Unknown error",
                isError: true
            )
            await operationRegistry.finish(vmId: result.vmId)
        }

        guard !Task.isCancelled else {
            await releaseLocks(lockedVMIds.subtracting(Set(failedResults.map(\.vmId))))
            return false
        }

        let initialStatuses = Dictionary(
            uniqueKeysWithValues: lockedVMs
                .filter { successfulVMIds.contains($0.id) }
                .map { ($0.id, $0.status) }
        )
        let pollResults = await pollingService.waitForVMTransitions(
            iamToken: iamToken,
            initialStatuses: initialStatuses,
            timeout: nil,
            interval: nil,
            maxConsecutiveFailures: nil
        )

        var didCompletePolls = true
        for (_, result) in pollResults {
            let didComplete = await handlePollingResult(result, operation: .start, source: source)
            if !didComplete {
                didCompletePolls = false
            }
        }

        await releaseLocks(lockedVMIds.subtracting(Set(failedResults.map(\.vmId))))
        return failedResults.isEmpty && didCompletePolls
    }

    private func stopVMs(
        _ vms: [VMTableData],
        iamToken: String,
        source: VMPowerOperationSource
    ) async -> Set<String> {
        let lockedVMs = await lockVMs(vms, source: source)
        var failedVMIds = Set(vms.map(\.id)).subtracting(Set(lockedVMs.map(\.id)))

        guard !lockedVMs.isEmpty else {
            return failedVMIds
        }

        let lockedVMIds = Set(lockedVMs.map(\.id))
        defer {
            Task {
                await releaseLocks(lockedVMIds)
            }
        }

        let results = await powerService.stopVMs(
            iamToken: iamToken,
            vmIds: Array(lockedVMIds)
        )
        let failedResults = results.filter { !$0.success }
        let successfulVMIds = Set(results.filter(\.success).map(\.vmId))

        for result in results where result.success {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .accepted
            )
        }

        for result in failedResults {
            VMPowerOperationLogger.log(
                vmId: result.vmId,
                operation: result.operation,
                source: source,
                outcome: .failed,
                message: result.errorMessage ?? "Unknown error",
                isError: true
            )
            failedVMIds.insert(result.vmId)
            await operationRegistry.finish(vmId: result.vmId)
        }

        let initialStatuses = Dictionary(
            uniqueKeysWithValues: lockedVMs
                .filter { successfulVMIds.contains($0.id) }
                .map { ($0.id, $0.status) }
        )
        let pollResults = await pollingService.waitForVMTransitions(
            iamToken: iamToken,
            initialStatuses: initialStatuses,
            timeout: nil,
            interval: nil,
            maxConsecutiveFailures: nil
        )

        for (vmId, result) in pollResults {
            let completed = await handlePollingResult(result, operation: .stop, source: source)
            if !completed {
                failedVMIds.insert(vmId)
            }
        }

        await releaseLocks(lockedVMIds.subtracting(Set(failedResults.map(\.vmId))))
        return failedVMIds
    }

    private func sendStopCommandsOnly(
        vmIds: [String],
        iamToken: String,
        source: VMPowerOperationSource
    ) async -> Set<String> {
        let lockedVMIds = await lockVMIds(vmIds, source: source)
        var failedVMIds = Set(vmIds).subtracting(lockedVMIds)

        guard !lockedVMIds.isEmpty else {
            return failedVMIds
        }

        var didReleaseLocks = false
        defer {
            if !didReleaseLocks {
                Task {
                    await releaseLocks(lockedVMIds)
                }
            }
        }

        guard !Task.isCancelled else {
            LoggerHelper.info("VM shutdown cancelled before stop commands source=\(source.rawValue)")
            await releaseLocks(lockedVMIds)
            didReleaseLocks = true
            return Set(lockedVMIds)
        }

        let results = await powerService.stopVMs(
            iamToken: iamToken,
            vmIds: Array(lockedVMIds)
        )

        for result in results {
            if result.success {
                LoggerHelper.info("VM shutdown command accepted source=\(source.rawValue) vmId=\(result.vmId)")
                VMPowerOperationLogger.log(
                    vmId: result.vmId,
                    operation: result.operation,
                    source: source,
                    outcome: .accepted,
                    message: "Stop command accepted by API"
                )
            } else if isNonFatalStopRejection(result.errorMessage) {
                LoggerHelper.info(
                    "VM shutdown command completed source=\(source.rawValue) vmId=\(result.vmId) reason=already_stopped_or_not_running"
                )
                VMPowerOperationLogger.log(
                    vmId: result.vmId,
                    operation: result.operation,
                    source: source,
                    outcome: .completed,
                    message: result.errorMessage ?? "VM already stopped or not running"
                )
            } else {
                LoggerHelper.error(
                    "VM shutdown command failed source=\(source.rawValue) vmId=\(result.vmId) error=\(result.errorMessage ?? "Unknown error")"
                )
                VMPowerOperationLogger.log(
                    vmId: result.vmId,
                    operation: result.operation,
                    source: source,
                    outcome: .failed,
                    message: result.errorMessage ?? "Unknown error",
                    isError: true
                )
                failedVMIds.insert(result.vmId)
            }
        }

        await releaseLocks(lockedVMIds)
        didReleaseLocks = true
        return failedVMIds
    }

    private func lockVMIds(
        _ vmIds: [String],
        source: VMPowerOperationSource
    ) async -> Set<String> {
        var lockedVMIds = Set<String>()

        for vmId in vmIds {
            if await operationRegistry.begin(vmId: vmId, source: source) {
                lockedVMIds.insert(vmId)
            }
        }

        return lockedVMIds
    }

    private func lockVMs(
        _ vms: [VMTableData],
        source: VMPowerOperationSource
    ) async -> [VMTableData] {
        var lockedVMs: [VMTableData] = []

        for vm in vms {
            if await operationRegistry.begin(vmId: vm.id, source: source) {
                lockedVMs.append(vm)
            }
        }

        return lockedVMs
    }

    private func releaseLocks(_ vmIds: Set<String>) async {
        for vmId in vmIds {
            await operationRegistry.finish(vmId: vmId)
        }
    }

    private func iamTokenForShutdown(source: VMPowerOperationSource) async throws -> String {
        if let cachedToken = await iamTokenCache.validToken() {
            LoggerHelper.info("VM shutdown using cached IAM token source=\(source.rawValue)")
            return cachedToken.value
        }

        let token = settingsManager.oAuthKey
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw YandexRequestError.emptyOAuthToken
        }

        let authResponse = try await authAPI.checkOAuthToken(token)
        await iamTokenCache.store(authResponse)
        LoggerHelper.info("VM shutdown IAM token refreshed source=\(source.rawValue)")
        return authResponse.iamToken
    }

    private func uniqueVMIds(_ vmIds: [String]) -> [String] {
        var seenVMIds = Set<String>()
        return vmIds.filter { seenVMIds.insert($0).inserted }
    }

    private func isNonFatalStopRejection(_ message: String?) -> Bool {
        guard let message else { return false }

        let normalized = message.lowercased()
        return normalized.contains("already stopped")
        || normalized.contains("instance is stopped")
        || normalized.contains("not running")
        || normalized.contains("state must be running")
        || normalized.contains("current state")
        || normalized.contains("cannot transition")
    }

    private func handlePollingResult(
        _ result: VMPollingResult,
        operation: VMOperation,
        source: VMPowerOperationSource
    ) async -> Bool {
        let timeStamp = Date().formatted(.dateTime.hour().minute().second())

        switch result {
        case .changed(let vm):
            let completed = vm.status == operation.targetStatus
            VMPowerOperationLogger.log(
                vmId: vm.id,
                operation: operation,
                source: source,
                outcome: completed ? .completed : .failed,
                message: "status=\(vm.status.rawValue)",
                isError: !completed
            )

            postNotificationIfNeeded(vm: vm, operation: operation, timeStamp: timeStamp)
            return completed
        case .timeout(let vmId):
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: operation,
                source: source,
                outcome: .timeout,
                message: "Operation result is uncertain after polling timeout",
                isError: true
            )
            return false
        case .failed(let vmId, let message):
            VMPowerOperationLogger.log(
                vmId: vmId,
                operation: operation,
                source: source,
                outcome: .failed,
                message: message,
                isError: true
            )
            return false
        }
    }

    private func postNotificationIfNeeded(
        vm: VMTableData,
        operation: VMOperation,
        timeStamp: String
    ) {
        if operation == .start, vm.status.isRunning {
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmStarted,
                    language: settingsManager.appLanguage,
                    vm.name,
                    timeStamp
                )
            )
        } else if operation == .stop, vm.status.isStopped {
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmStopped,
                    language: settingsManager.appLanguage,
                    vm.name,
                    timeStamp
                )
            )
        } else if vm.status.isFailure {
            NotificationManager.shared.postNotification(
                title: "yaControl",
                body: LocalizedStringHelper.formatted(
                    L10n.Notifications.vmError,
                    language: settingsManager.appLanguage,
                    vm.name,
                    vm.statusText,
                    timeStamp
                )
            )
        }
    }
    
    private func notifyVMInventoryDidChange() {
        NotificationCenter.default.post(name: .vmInventoryDidChange, object: nil)
    }

    private func makeWakeAutoStartWorkflow() -> VMPowerWakeAutoStartWorkflow {
        VMPowerWakeAutoStartWorkflow(
            retryPolicy: wakeRetryPolicy,
            sleeper: TaskAutomationSleeper(),
            loadSettings: {
                VMAutoStartSettingsSnapshot(
                    autoStartEnabled: self.settingsManager.autoStartEnabled,
                    startOptions: self.settingsManager.startOptions,
                    selectedVMIds: self.settingsManager.getAllAutostartVMs(),
                    oAuthToken: self.settingsManager.oAuthKey
                )
            },
            waitUntilConnected: { timeout in
                await self.waitUntilConnected(timeout)
            },
            authenticate: { token in
                let authResponse = try await self.authAPI.checkOAuthToken(token)
                await self.iamTokenCache.store(authResponse)
                return authResponse
            },
            loadInventory: { iamToken in
                try await self.inventoryService.loadVMTableData(iamToken: iamToken)
            },
            startVMs: { vms, iamToken in
                let didComplete = await self.startVMs(vms, iamToken: iamToken, source: .macOSWake)
                if !vms.isEmpty {
                    self.notifyVMInventoryDidChange()
                }
                return didComplete
            },
            internetWaitTimeout: internetWaitTimeout
        )
    }

}
