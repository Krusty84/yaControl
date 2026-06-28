//
//  AppTerminationCoordinator.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 28/06/2026.
//

import AppKit
import Foundation

enum AppTerminationReason: Equatable, Sendable {
    case userQuit
    case macOSLogoutOrShutdown
}

enum AppTerminationShutdownResult: Equatable, Sendable {
    case completed
    case failed
    case timedOut
    case skipped
}

struct AppTerminationCoordinatorState: Equatable, Sendable {
    let pendingReason: AppTerminationReason?
    let hasShutdownTask: Bool
    let lastResult: AppTerminationShutdownResult?
}

private final class TerminationWaitContinuation: @unchecked Sendable {
    private let lock = NSLock()
    private let continuation: CheckedContinuation<AppTerminationShutdownResult, Never>
    private var didResume = false
    private var operationTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    init(_ continuation: CheckedContinuation<AppTerminationShutdownResult, Never>) {
        self.continuation = continuation
    }

    func setTasks(operationTask: Task<Void, Never>, timeoutTask: Task<Void, Never>) {
        lock.lock()
        self.operationTask = operationTask
        self.timeoutTask = timeoutTask
        let shouldCancel = didResume
        lock.unlock()

        if shouldCancel {
            operationTask.cancel()
            timeoutTask.cancel()
        }
    }

    func resume(returning result: AppTerminationShutdownResult) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }

        didResume = true
        let operationTask = operationTask
        let timeoutTask = timeoutTask
        lock.unlock()

        operationTask?.cancel()
        timeoutTask?.cancel()
        continuation.resume(returning: result)
    }
}

@MainActor
final class AppTerminationCoordinator {
    static let shared = AppTerminationCoordinator()

    private let terminationTimeout: Duration
    private let isShutdownConfigured: @Sendable (ShutdownOption) -> Bool
    private let runShutdown: @Sendable (AppTerminationReason) async -> Bool

    private var pendingReason: AppTerminationReason?
    private var shutdownTask: Task<Bool, Never>?
    private var lastResult: AppTerminationShutdownResult?

    init(
        terminationTimeout: Duration = .seconds(8),
        automationService: VMPowerAutomationService = .shared
    ) {
        self.terminationTimeout = terminationTimeout
        self.isShutdownConfigured = { option in
            automationService.isShutdownConfigured(option: option)
        }
        self.runShutdown = { reason in
            switch reason {
            case .userQuit:
                await automationService.handleAppExit()
            case .macOSLogoutOrShutdown:
                await automationService.handleMacOSShutdown()
            }
        }
    }

    init(
        terminationTimeout: Duration,
        isShutdownConfigured: @escaping @Sendable (ShutdownOption) -> Bool,
        runShutdown: @escaping @Sendable (AppTerminationReason) async -> Bool
    ) {
        self.terminationTimeout = terminationTimeout
        self.isShutdownConfigured = isShutdownConfigured
        self.runShutdown = runShutdown
    }

    var stateSnapshot: AppTerminationCoordinatorState {
        AppTerminationCoordinatorState(
            pendingReason: pendingReason,
            hasShutdownTask: shutdownTask != nil,
            lastResult: lastResult
        )
    }

    func handleMacOSPowerOffNotification() {
        _ = beginTermination(reason: .macOSLogoutOrShutdown)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
            return .terminateNow
        }

        let reason = pendingReason ?? .userQuit
        guard beginTermination(reason: reason) else {
            return .terminateNow
        }

        let task = shutdownTask

        Task { @MainActor [weak sender] in
            if let task {
                _ = await waitForShutdown(task, reason: reason)
            }

            // AppKit requires an explicit reply after returning terminateLater.
            sender?.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }

    @discardableResult
    func beginTermination(reason: AppTerminationReason) -> Bool {
        pendingReason = reason

        guard isShutdownConfigured(shutdownOption(for: reason)) else {
            lastResult = .skipped
            LoggerHelper.info("VM shutdown skipped source=\(source(for: reason).rawValue) reason=option_disabled")
            return false
        }

        _ = startOrReuseShutdownTask(reason: reason)
        return true
    }

    func waitForPendingTermination() async -> AppTerminationShutdownResult {
        guard let shutdownTask else {
            lastResult = .skipped
            return .skipped
        }

        let reason = pendingReason ?? .userQuit
        return await waitForShutdown(shutdownTask, reason: reason)
    }

    private func startOrReuseShutdownTask(reason: AppTerminationReason) -> Task<Bool, Never> {
        if let shutdownTask {
            LoggerHelper.info("VM shutdown task reused source=\(source(for: reason).rawValue)")
            return shutdownTask
        }

        let task = Task { [runShutdown] in
            await runShutdown(reason)
        }
        shutdownTask = task
        LoggerHelper.info("VM shutdown task started source=\(source(for: reason).rawValue)")
        return task
    }

    private func waitForShutdown(
        _ task: Task<Bool, Never>,
        reason: AppTerminationReason
    ) async -> AppTerminationShutdownResult {
        let source = source(for: reason)

        let result = await withCheckedContinuation { continuation in
            let waitContinuation = TerminationWaitContinuation(continuation)

            let operationTask = Task {
                let didComplete = await task.value
                waitContinuation.resume(returning: didComplete ? .completed : .failed)
            }

            let timeoutTask = Task { [terminationTimeout] in
                do {
                    try await Task.sleep(for: terminationTimeout)
                } catch {
                    return
                }

                waitContinuation.resume(returning: .timedOut)
            }

            waitContinuation.setTasks(operationTask: operationTask, timeoutTask: timeoutTask)
        }

        if result == .timedOut {
            task.cancel()
        }

        lastResult = result
        switch result {
        case .completed:
            LoggerHelper.info("VM shutdown completed source=\(source.rawValue)")
        case .failed:
            LoggerHelper.error("VM shutdown failed source=\(source.rawValue)")
        case .timedOut:
            LoggerHelper.error("VM shutdown timed_out source=\(source.rawValue)")
        case .skipped:
            LoggerHelper.info("VM shutdown skipped source=\(source.rawValue)")
        }

        return result
    }

    private func shutdownOption(for reason: AppTerminationReason) -> ShutdownOption {
        switch reason {
        case .userQuit:
            .afterAppExit
        case .macOSLogoutOrShutdown:
            .beforeMacOSLogout
        }
    }

    private func source(for reason: AppTerminationReason) -> VMPowerOperationSource {
        switch reason {
        case .userQuit:
            .appExit
        case .macOSLogoutOrShutdown:
            .macOSPowerOff
        }
    }
}
