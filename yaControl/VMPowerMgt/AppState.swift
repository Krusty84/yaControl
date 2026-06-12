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
    private var isLoading = false
    private var errorMessage: String?
    private var vmTableData: [VMTableData] = []
    private var activeVMPowerOperationCount = 0
    private var blinkTask: Task<Void, Never>?
    private var blinkPhase = false
    
    @Published var isVirtualMachineRunning: Bool = false {
        didSet {
            updateMenuBarIconColor()
        }
    }

    @Published private(set) var latestConditionColor: NSColor = .systemGray // Track the latest condition color
    @Published private(set) var menuBarIconColor: NSColor = .systemGray

    private var baseMenuBarIconColor: NSColor {
        isVirtualMachineRunning ? .systemGreen : .clear
    }

    @MainActor
    func beginVMPowerActivity() {
        activeVMPowerOperationCount += 1

        if activeVMPowerOperationCount == 1 {
            startMenuBarBlinking()
        }
    }

    @MainActor
    func endVMPowerActivity() {
        activeVMPowerOperationCount = max(0, activeVMPowerOperationCount - 1)

        if activeVMPowerOperationCount == 0 {
            stopMenuBarBlinking()
        }
    }

    private func startMenuBarBlinking() {
        blinkTask?.cancel()
        blinkPhase = true
        updateMenuBarIconColor()

        blinkTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self?.blinkPhase.toggle()
                self?.updateMenuBarIconColor()
            }
        }
    }

    private func stopMenuBarBlinking() {
        blinkTask?.cancel()
        blinkTask = nil
        blinkPhase = false
        updateMenuBarIconColor()
    }

    private func updateMenuBarIconColor() {
        latestConditionColor = baseMenuBarIconColor
        menuBarIconColor = activeVMPowerOperationCount > 0 && blinkPhase
            ? .systemOrange
            : baseMenuBarIconColor
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
                        .filter { $0.status.isRunning }
                        .map { $0.id }
                    completion?(runningVMIds)
                }
                
            } catch {
                // 4. Handle errors
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion?([])
                }
            }
        }
        
            }

    // Update the app state based on the number of running VMs
    private func updateAppState(with vms: [VMTableData]) {
        let runningVMs = vms.filter { $0.status.isRunning }.count
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

        Task { @MainActor [weak self] in
            let success = await VMPowerAutomationService.shared.handleAppExit()
            self?.isLoading = false
            completion(success)
        }
    }

    func handleSleep(completion: @escaping (Bool) -> Void) {
        guard !isLoading else {
            completion(false)
            return
        }
        isLoading = true
        errorMessage = nil

        Task { @MainActor [weak self] in
            let success = await VMPowerAutomationService.shared.handleMacSleep()
            self?.isLoading = false
            completion(success)
        }
    }
        
    func handleWake() {
        Task {
            await VMPowerAutomationService.shared.handleMacWake()
        }
    }
}
