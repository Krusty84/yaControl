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
//                YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { [weak self] result in
//                    DispatchQueue.main.async {
//                        guard let self = self else { return }
//                        switch result {
//                        case .success(let response):
//                            let iamToken = response.iamToken
//                            YandexAPIService.shared.getVMs(iamToken: iamToken) { [weak self] result in
//                                DispatchQueue.main.async {
//                                    guard let self = self else { return }
//                                    self.isLoading = false
//                                    switch result {
//                                    case .success(let allVMs):
//                                        self.vmTableData = allVMs
//                                        self.updateAppState(with: allVMs)
//                                        let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
//                                        completion?(runningVMIds)
//                                    case .failure(let error):
//                                        self.errorMessage = error.localizedDescription
//                                        completion?([])
//                                    }
//                                }
//                            }
//                        case .failure(let error):
//                            self.isLoading = false
//                            print(error.localizedDescription)
//                            self.errorMessage = error.localizedDescription
//                            completion?([])
//                        }
//                    }
//                }
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
        print("Start application")
    }
    
    func handleShutdown(completion: @escaping (Bool) -> Void) {
        guard !isLoading else {
            completion(false)
            return
        }
        isLoading = true
        errorMessage = nil
        
        //            YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { [weak self] result in
        //                guard let self = self else {
        //                    completion(false)
        //                    return
        //                }
        //
        //                switch result {
        //                case .success(let response):
        //                    let iamToken = response.iamToken
        //                    print("IAM token acquired successfully")
        //
        //                    // First, get the list of running VMs
        //                    YandexAPIService.shared.getVMs(iamToken: iamToken) { [weak self] result in
        //                        guard let self = self else {
        //                            completion(false)
        //                            return
        //                        }
        //
        //                        switch result {
        //                        case .success(let allVMs):
        //                            let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
        //                            print("Running VM IDs: \(runningVMIds)")
        //
        //                            guard !runningVMIds.isEmpty else {
        //                                print("No running VMs found")
        //                                self.isLoading = false
        //                                completion(true)
        //                                return
        //                            }
        //
        //                            // Now stop the running VMs
        //                            let vmStopGroup = DispatchGroup()
        //                            var stopErrors: [Error] = []
        //
        //                            for vmId in runningVMIds {
        //                                vmStopGroup.enter()
        //                                YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vmId) { result in
        //                                    switch result {
        //                                    case .success:
        //                                        print("Successfully stopped VM: \(vmId)")
        //                                    case .failure(let error):
        //                                        print("Failed to stop VM \(vmId): \(error.localizedDescription)")
        //                                        stopErrors.append(error)
        //                                    }
        //                                    vmStopGroup.leave()
        //                                }
        //                            }
        //
        //                            vmStopGroup.notify(queue: .main) {
        //                                self.isLoading = false
        //                                let success = stopErrors.isEmpty
        //                                completion(success)
        //                            }
        //
        //                        case .failure(let error):
        //                            self.isLoading = false
        //                            self.errorMessage = error.localizedDescription
        //                            print("Failed to fetch VM list: \(error.localizedDescription)")
        //                            completion(false)
        //                        }
        //                    }
        //
        //                case .failure(let error):
        //                    self.isLoading = false
        //                    self.errorMessage = error.localizedDescription
        //                    print("Critical: Failed to acquire IAM token: \(error.localizedDescription)")
        //                    completion(false)
        //                }
        //            }
        
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
                print("IAM token acquired successfully")

                // 2. Get running VMs
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: response.iamToken)
                let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
                print("Running VM IDs: \(runningVMIds)")

                guard !runningVMIds.isEmpty else {
                    print("No running VMs found")
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
                            print("Successfully stopped VM: \(vmId)")
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
                    print("Operation failed: \(error.localizedDescription)")
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
        
        //            YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { [weak self] result in
        //                guard let self = self else {
        //                    completion(false)
        //                    return
        //                }
        //
        //                switch result {
        //                case .success(let response):
        //                    let iamToken = response.iamToken
        //                    print("IAM token acquired successfully")
        //
        //                    // First, get the list of running VMs
        //                    YandexAPIService.shared.getVMs(iamToken: iamToken) { [weak self] result in
        //                        guard let self = self else {
        //                            completion(false)
        //                            return
        //                        }
        //
        //                        switch result {
        //                        case .success(let allVMs):
        //                            let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
        //                            print("Running VM IDs: \(runningVMIds)")
        //
        //                            guard !runningVMIds.isEmpty else {
        //                                print("No running VMs found")
        //                                self.isLoading = false
        //                                completion(true)
        //                                return
        //                            }
        //
        //                            // Now stop the running VMs
        //                            let vmStopGroup = DispatchGroup()
        //                            var stopErrors: [Error] = []
        //
        //                            for vmId in runningVMIds {
        //                                vmStopGroup.enter()
        //                                YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vmId) { result in
        //                                    switch result {
        //                                    case .success:
        //                                        print("Successfully stopped VM: \(vmId)")
        //                                    case .failure(let error):
        //                                        print("Failed to stop VM \(vmId): \(error.localizedDescription)")
        //                                        stopErrors.append(error)
        //                                    }
        //                                    vmStopGroup.leave()
        //                                }
        //                            }
        //
        //                            vmStopGroup.notify(queue: .main) {
        //                                self.isLoading = false
        //                                let success = stopErrors.isEmpty
        //                                completion(success)
        //                            }
        //
        //                        case .failure(let error):
        //                            self.isLoading = false
        //                            self.errorMessage = error.localizedDescription
        //                            print("Failed to fetch VM list: \(error.localizedDescription)")
        //                            completion(false)
        //                        }
        //                    }
        //
        //                case .failure(let error):
        //                    self.isLoading = false
        //                    self.errorMessage = error.localizedDescription
        //                    print("Critical: Failed to acquire IAM token: \(error.localizedDescription)")
        //                    completion(false)
        //                }
        //            }
    
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
                print("IAM token acquired successfully")
                
                // 2. Get running VMs
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: response.iamToken)
                let runningVMIds = allVMs.filter { $0.status == "RUNNING" }.map { $0.id }
                print("Running VM IDs: \(runningVMIds)")

                guard !runningVMIds.isEmpty else {
                    print("No running VMs found")
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
                                print("Successfully stopped VM: \(vmId)")
                            } catch {
                                print("Failed to stop VM \(vmId): \(error.localizedDescription)")
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
            print("Handling system wake")
            // Add your wake logic here:
            // - Resume operations
            // - Restore connections
            // - Check system state
            //checkNumRunningVMs() // You already have this method
        }
}
