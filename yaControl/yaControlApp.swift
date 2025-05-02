//
//  yaControlApp.swift - ENTRY POINT OF APP
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI
import AppKit
//import UserNotifications

@main
struct yaControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow
    @StateObject private var appState = AppState.shared
    
    init() {
        // Initialize the app lifecycle observer
        _ = AppLifecycleObserver.shared
        
        // Create local copies of the properties we need to modify
        let autoStartEnabled = SettingsManager.shared.autoStartEnabled
        let startOptions = SettingsManager.shared.startOptions
        let oAuthKey = SettingsManager.shared.oAuthKey
        let vmsToStart = SettingsManager.shared.getAllAutostartVMs()
        
        Helpers.checkInternetConnection {
            if autoStartEnabled && startOptions.contains(.afterAppLaunched) && !vmsToStart.isEmpty {
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
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            MenuBarIcon(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarContentView: View {
    @State private var optionKeyPressed = false

    var body: some View {
        Group {
            if optionKeyPressed {
                InfoWindow()
            } else {
                MainWindow()
            }
        }
        .onAppear {
            optionKeyPressed = NSEvent.modifierFlags.contains(.option)
        }
    }
}


 
 

