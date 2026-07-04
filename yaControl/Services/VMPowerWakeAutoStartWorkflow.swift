//
//  VMPowerWakeAutoStartWorkflow.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 27/06/2026.
//

import Foundation

struct VMAutoStartSettingsSnapshot: Equatable, Sendable {
    let autoStartEnabled: Bool
    let startOptions: [StartOption]
    let selectedVMIds: [String]
    let oAuthToken: String
}

enum VMAutoStartAttemptResult: Equatable, Sendable {
    case completed
    case noWork
    case disabled
    case retryRequired(reason: String)
    case permanentFailure(reason: String)
    case cancelled
}

struct VMPowerAutomationRetryPolicy: Equatable, Sendable {
    let delays: [Duration]

    static let wake = VMPowerAutomationRetryPolicy(
        delays: [.seconds(2), .seconds(5), .seconds(10), .seconds(20)]
    )
}

protocol AutomationSleeper: Sendable {
    func sleep(for duration: Duration) async throws
}

struct TaskAutomationSleeper: AutomationSleeper {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

struct VMPowerWakeAutoStartWorkflow: Sendable {
    let retryPolicy: VMPowerAutomationRetryPolicy
    let sleeper: any AutomationSleeper
    let loadSettings: @Sendable () async -> VMAutoStartSettingsSnapshot
    let waitUntilConnected: @Sendable (Duration) async -> Bool
    let authenticate: @Sendable (String) async throws -> AuthResponse
    let loadInventory: @Sendable (String) async throws -> [VMTableData]
    let startVMs: @Sendable ([VMTableData], String) async -> Bool
    let internetWaitTimeout: Duration

    func run() async -> VMAutoStartAttemptResult {
        guard !retryPolicy.delays.isEmpty else {
            return await performAttempt(attempt: 1)
        }
        guard let lastAttemptIndex = retryPolicy.delays.indices.last else {
            return await performAttempt(attempt: 1)
        }

        for attemptIndex in retryPolicy.delays.indices {
            guard !Task.isCancelled else {
                LoggerHelper.info("Wake auto-start cancelled")
                return .cancelled
            }

            do {
                try await sleeper.sleep(for: retryPolicy.delays[attemptIndex])
            } catch {
                LoggerHelper.info("Wake auto-start cancelled")
                return .cancelled
            }

            let attempt = attemptIndex + 1
            let result = await performAttempt(attempt: attempt)

            switch result {
            case .retryRequired(let reason):
                guard attemptIndex < lastAttemptIndex else {
                    LoggerHelper.error("Wake auto-start exhausted retries reason=\(reason)")
                    return result
                }

                LoggerHelper.info("Wake auto-start retrying attempt=\(attempt + 1) reason=\(reason)")
            case .completed:
                LoggerHelper.info("Wake auto-start completed")
                return result
            case .noWork, .disabled, .permanentFailure, .cancelled:
                return result
            }
        }

        return .retryRequired(reason: "max_retries_exhausted")
    }

    private func performAttempt(attempt: Int) async -> VMAutoStartAttemptResult {
        LoggerHelper.info("Wake auto-start attempt=\(attempt)")

        guard !Task.isCancelled else {
            LoggerHelper.info("Wake auto-start cancelled")
            return .cancelled
        }

        let settings = await loadSettings()
        guard settings.autoStartEnabled else {
            LoggerHelper.info("Wake auto-start disabled reason=power_management_disabled")
            return .disabled
        }

        guard settings.startOptions.contains(.afterMacOSWakeup) else {
            LoggerHelper.info("Wake auto-start disabled reason=after_macos_wakeup_disabled")
            return .disabled
        }

        guard !settings.selectedVMIds.isEmpty else {
            LoggerHelper.info("Wake auto-start no work reason=no_selected_vms")
            return .noWork
        }

        LoggerHelper.info("Wake auto-start started selectedVMCount=\(settings.selectedVMIds.count)")

        guard !settings.oAuthToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .permanentFailure(reason: "empty_oauth_token")
        }

        let isConnected = await waitUntilConnected(internetWaitTimeout)
        guard !Task.isCancelled else {
            LoggerHelper.info("Wake auto-start cancelled")
            return .cancelled
        }
        guard isConnected else {
            return .retryRequired(reason: "network_unavailable")
        }

        do {
            let authResponse = try await authenticate(settings.oAuthToken)
            guard !Task.isCancelled else {
                LoggerHelper.info("Wake auto-start cancelled")
                return .cancelled
            }

            let inventory = try await loadInventory(authResponse.iamToken)
            guard !Task.isCancelled else {
                LoggerHelper.info("Wake auto-start cancelled")
                return .cancelled
            }

            let plan = VMPowerAutomationPlanner.autoStartPlan(
                selectedVMIds: settings.selectedVMIds,
                inventory: inventory
            )

            for vm in plan.deferredVMs {
                LoggerHelper.info("Wake auto-start deferred vmId=\(vm.id) status=\(vm.status.rawValue)")
            }

            for vm in plan.skippedVMs {
                LoggerHelper.info("Wake auto-start skipped vmId=\(vm.id) status=\(vm.status.rawValue)")
            }

            for vmId in plan.missingVMIds {
                LoggerHelper.info("Wake auto-start skipped vmId=\(vmId) reason=missing")
            }

            if !plan.vmsToStart.isEmpty {
                let vmIds = plan.vmsToStart.map(\.id)
                LoggerHelper.info("Wake auto-start starting vmIds=\(vmIds)")
                let didComplete = await startVMs(plan.vmsToStart, authResponse.iamToken)
                guard !Task.isCancelled else {
                    LoggerHelper.info("Wake auto-start cancelled")
                    return .cancelled
                }

                if didComplete {
                    LoggerHelper.info("Wake auto-start start request accepted vmIds=\(vmIds)")
                    return .completed
                }

                return .retryRequired(reason: "start_incomplete")
            }

            if !plan.deferredVMs.isEmpty {
                return .retryRequired(reason: "vm_transition")
            }

            return .completed
        } catch is CancellationError {
            LoggerHelper.info("Wake auto-start cancelled")
            return .cancelled
        } catch {
            return VMPowerAutomationErrorPolicy.autoStartAttemptResult(for: error)
        }
    }
}

enum VMPowerAutomationErrorPolicy {
    static func autoStartAttemptResult(for error: Error) -> VMAutoStartAttemptResult {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed,
                 .timedOut:
                return .retryRequired(reason: urlError.code.rawValue.description)
            default:
                return .permanentFailure(reason: urlError.code.rawValue.description)
            }
        }

        guard let requestError = error as? YandexRequestError else {
            return .permanentFailure(reason: error.localizedDescription)
        }

        switch requestError {
        case .invalidURL, .emptyOAuthToken, .decodingError, .apiError:
            return .permanentFailure(reason: requestError.localizedDescription)
        case .invalidResponse:
            return .retryRequired(reason: "invalid_response")
        case .httpError(let statusCode, _):
            if statusCode == 408 || statusCode == 429 || (500...599).contains(statusCode) {
                return .retryRequired(reason: "http_\(statusCode)")
            }

            return .permanentFailure(reason: "http_\(statusCode)")
        }
    }
}
