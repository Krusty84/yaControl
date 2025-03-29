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
    func checkNumRunningVMs() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        // Step 1: Get IAM Token
        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let response):
                        // Step 2: Get VMs using the IAM Token
                        let iamToken = response.iamToken
                        YandexAPIService.shared.getVMs(iamToken: iamToken) { result in
                            DispatchQueue.main.async {
                                self.isLoading = false
                                switch result {
                                    case .success(let allVMs):
                                        print("result: ", allVMs)
                                        self.vmTableData = allVMs
                                        self.updateAppState(with: allVMs)
                                    case .failure(let error):
                                        self.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    case .failure(let error):
                        self.isLoading = false
                        print(error.localizedDescription)
                        self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Update the app state based on the number of running VMs
    private func updateAppState(with vms: [VMTableData]) {
        let runningVMs = vms.filter { $0.status == "RUNNING" }.count
        self.isVirtualMachineRunning = runningVMs >= 1
    }
}
