//
//  AppState.swift - Global State Container
//  yaControl
//
//  Created by Sedoykin Alexey on 22/03/2025.
//

import AppKit
import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState() // Singleton for reusability
    private var timer: Timer?
    private var isLoading = false
    private var errorMessage: String?
    private var vmTableData: [VMTableData] = []
    
    @Published var isVirtualMachineRunning: Bool = false {
        didSet {
            updateLatestConditionColor()
        }
    }

    @Published private(set) var latestConditionColor: NSColor = .systemGray // Track the latest condition color

    // Helper function to update the latestConditionColor based on the latest changed variable
    private func updateLatestConditionColor() {
        let newColor: NSColor
        if isVirtualMachineRunning {
            newColor = .systemGreen
        } else {
            newColor = .clear
        }
        latestConditionColor = newColor
    }

    // Fetch VMs and update the app state
    func checkNumRunningVMs(completion: (([String]) -> Void)? = nil) {
                guard !isLoading else { return }
                isLoading = true
                errorMessage = nil
        Task { [weak self] in
            guard let self else { return }
            
            do {
                // 1. Get IAM token
                let response = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                
                // 2. Get VMs
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: response.iamToken)
                
                // 3. Update state on main thread
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.vmTableData = allVMs
                    self.updateAppState(with: allVMs)
                    
                    let runningVMIds = allVMs
                        .filter { $0.status == "RUNNING" }
                        .map { $0.id }
                    completion?(runningVMIds)
                }
                
            } catch {
                // 4. Handle errors
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    print(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    completion?([])
                }
            }
        }
        
            }

    // Update the app state based on the number of running VMs
    private func updateAppState(with vms: [VMTableData]) {
        let runningVMs = vms.filter { $0.status == "RUNNING" }.count
        self.isVirtualMachineRunning = runningVMs >= 1
    }
    
    //MARK: - Handlers for AppLifecycleObserver catcher
    func handleFirstLaunch(){
        LoggerHelper.info("Start application")
    }
    
    func handleShutdown(completion: @escaping (Bool) -> Void) {
        guard !isLoading else {
            completion(false)
            return
        }
        isLoading = true
        errorMessage = nil
                
        Task { [weak self] in
            guard let self else {
                completion(false)
                return
            }

            do {
                // 1. Get IAM token
                let response = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                LoggerHelper.info("IAM token acquired successfully")

                // 2. Get running VMs
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: response.iamToken)
                let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
                LoggerHelper.info("Running VM IDs: \(runningVMIds)")

                guard !runningVMIds.isEmpty else {
                    LoggerHelper.info("No running VMs found")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    completion(true)
                    return
                }

                // 3. Stop all running VMs concurrently
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for vmId in runningVMIds {
                        group.addTask {
                            try await YandexAPIService.shared.stopVM(
                                iamToken: response.iamToken,
                                vmId: vmId
                            )
                            LoggerHelper.info("Successfully stopped VM: \(vmId)")
                        }
                    }

                    // Wait for all stop operations to complete
                    try await group.waitForAll()
                }

                // 4. Final completion
                await MainActor.run {
                    self.isLoading = false
                }
                completion(true)

            } catch {
                // Error handling
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    LoggerHelper.error("Operation failed: \(error.localizedDescription)")
                }
                completion(false)
            }
        }
        
    }

    func handleSleep(completion: @escaping (Bool) -> Void) {
        guard !isLoading else {
            completion(false)
            return
        }
        isLoading = true
        errorMessage = nil
            
        Task { [weak self] in
            guard let self else {
                completion(false)
                return
            }

            do {
                // 1. Get IAM token
                let response = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                LoggerHelper.info("IAM token acquired successfully")
                
                // 2. Get running VMs
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: response.iamToken)
                let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
                LoggerHelper.info("Running VM IDs: \(runningVMIds)")
                
                guard !runningVMIds.isEmpty else {
                    LoggerHelper.info("No running VMs found")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    completion(true)
                    return
                }

                // 3. Stop all VMs concurrently with error collection
                var stopErrors: [Error] = []
                
                await withTaskGroup(of: Void.self) { group in
                    for vmId in runningVMIds {
                        group.addTask {
                            do {
                                try await YandexAPIService.shared.stopVM(
                                    iamToken: response.iamToken,
                                    vmId: vmId
                                )
                                LoggerHelper.info("Successfully stopped VM: \(vmId)")
                            } catch {
                                LoggerHelper.error("Failed to stop VM \(vmId): \(error.localizedDescription)")
                                await MainActor.run {
                                    stopErrors.append(error)
                                }
                            }
                        }
                    }
                }

                // 4. Final completion
                await MainActor.run {
                    self.isLoading = false
                    completion(stopErrors.isEmpty)
                }

            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    print("Operation failed: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
        
    func handleWake() {
        let autoStartEnabled = SettingsManager.shared.autoStartEnabled
        let startOptions = SettingsManager.shared.startOptions
        let oAuthKey = SettingsManager.shared.oAuthKey
        let vmsToStart = SettingsManager.shared.getAllAutostartVMs()
        
        Helpers.checkInternetConnection {
            if autoStartEnabled && startOptions.contains(.afterWakeup) && !vmsToStart.isEmpty {
                Task {
                    do {
                        // 1. Get IAM token
                        let authResponse = try await YandexAPIService.shared.checkOauthKey(
                            yandexPassportOauthToken: oAuthKey
                        )
                        
                        // 2. Start all marked VMs
                        await Helpers.shared.startAllMarkedVMs(
                            iamToken: authResponse.iamToken,
                            vmIds: vmsToStart
                        )
                        
                    } catch {
                        await MainActor.run {
                            LoggerHelper.error("Auto-start failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
            else {
                LoggerHelper.info("No VMs selected for auto-start on app launch")
            }
            AppState.shared.checkNumRunningVMs()
        }
        }
}
