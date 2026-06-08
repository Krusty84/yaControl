//
//  AppLifeCycleHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 30/03/2025.
//

import SwiftUI
import AppKit

//handle termination and ensure async code executes before the app quits, the nuance of shutdown
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        Task {
            let success = await VMPowerAutomationService.shared.handleAppExit()
            LoggerHelper.info(success ? "Shutdown tasks completed successfully." : "Shutdown tasks finished with errors.")
            NSApplication.shared.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

class AppLifecycleObserver: ObservableObject {
    static let shared = AppLifecycleObserver()
    private var observers = [NSObjectProtocol]()
    
    @Published var isFirstLaunch: Bool = true
    @Published var didJustWake: Bool = false
    @Published var systemStatus: SystemStatus = .active
    
    private let hasLaunchedBeforeKey = "HasLaunchedBefore"
    private let lastSleepDateKey = "LastSleepDate"
    
    enum SystemStatus {
        case firstLaunch
        case wakeFromSleep
        case aboutToSleep
        case active
    }
    
    private init() {
        setupObservers()
        checkFirstLaunch()
    }
    
    private func setupObservers() {
        let nc = NotificationCenter.default
        let workspaceNC = NSWorkspace.shared.notificationCenter

        observers = [
            // App launch
            nc.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: .main) { _ in
                self.handleFirstLaunch()
            },

            // Will sleep
            workspaceNC.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
                self.systemStatus = .aboutToSleep
                UserDefaults.standard.set(Date(), forKey: self.lastSleepDateKey)
                LoggerHelper.info("System gonna sleep")
                Task {
                    let success = await VMPowerAutomationService.shared.handleMacSleep()
                    LoggerHelper.info(success ? "Shutdown tasks completed successfully." : "Shutdown tasks finished with errors.")
                }
            },

            // Did wake
            workspaceNC.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
                self.handleWake()
            },

            // Screen locked (optional)
//            DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
//                print("Screen locked")
//            },

            // Screen unlocked (optional)
//            DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
//                print("Screen unlocked")
//            }
        ]
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)
        isFirstLaunch = !hasLaunchedBefore
    }
    
    private func handleFirstLaunch() {
        if isFirstLaunch {
            systemStatus = .firstLaunch
            LoggerHelper.info("First launch detected")
            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
            AppState.shared.handleFirstLaunch()
        }
    }
    
    private func handleWake() {
        systemStatus = .wakeFromSleep
        didJustWake = true
        
        if let lastSleepDate = UserDefaults.standard.object(forKey: lastSleepDateKey) as? Date {
            let sleepDuration = Date().timeIntervalSince(lastSleepDate)
            LoggerHelper.info("System slept for \(sleepDuration) seconds")
        }

        Task {
            await VMPowerAutomationService.shared.handleMacWake()
        }

        // Reset state after 2 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.didJustWake = false
            self.systemStatus = .active
        }
    }
    
    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
