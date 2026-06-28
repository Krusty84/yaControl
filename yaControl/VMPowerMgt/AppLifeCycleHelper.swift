//
//  AppLifeCycleHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 30/03/2025.
//

import AppKit
import Foundation
import Observation

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppTerminationCoordinator.shared.applicationShouldTerminate(sender)
    }
}

@Observable
@MainActor
final class AppLifecycleObserver {
    static let shared = AppLifecycleObserver()

    var isFirstLaunch = true
    var didJustWake = false
    var systemStatus: SystemStatus = .active

    @ObservationIgnored
    private var observers = [NSObjectProtocol]()

    @ObservationIgnored
    private var wakeResetTask: Task<Void, Never>?

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
            nc.addObserver(forName: NSApplication.didFinishLaunchingNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleFirstLaunch()
                }
            },

            // Will sleep
            workspaceNC.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.systemStatus = .aboutToSleep
                    UserDefaults.standard.set(Date(), forKey: self.lastSleepDateKey)
                    LoggerHelper.info("System gonna sleep")
                    let success = await VMPowerAutomationService.shared.handleMacSleep()
                    LoggerHelper.info(
                        success
                        ? "Shutdown tasks completed successfully."
                        : "Shutdown tasks finished with errors."
                    )
                }
            },

            // Did wake
            workspaceNC.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleWake()
                }
            },

            // Will power off
            workspaceNC.addObserver(forName: NSWorkspace.willPowerOffNotification, object: nil, queue: .main) { _ in
                Task { @MainActor in
                    LoggerHelper.info("System will power off")
                    AppTerminationCoordinator.shared.handleMacOSPowerOffNotification()
                }
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

        wakeResetTask?.cancel()
        wakeResetTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }

            guard let self else { return }
            self.didJustWake = false
            self.systemStatus = .active
        }
    }

}
