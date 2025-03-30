//
//  AppLifeCycleHelper.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 30/03/2025.
//

import SwiftUI
import AppKit

class AppLifecycleObserver: ObservableObject {
    static let shared = AppLifecycleObserver()
    private var observers = [NSObjectProtocol]()
    
    // State tracking
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
        case shuttingDown
    }
    
    private init() {
        setupObservers()
        checkFirstLaunch()
    }
    
    private func setupObservers() {
        // App launch (first login)
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleFirstLaunch()
        })
        
        // Will terminate (shutdown/quit)
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.systemStatus = .shuttingDown
            print("Application will terminate")
            AppState.shared.handleShutdown()
        })
        
        // Will sleep
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.systemStatus = .aboutToSleep
            UserDefaults.standard.set(Date(), forKey: self.lastSleepDateKey)
            print("System will sleep")
            AppState.shared.handleSleep()
        })
        
        // Did wake
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleWake()
        })
        
        // Screen locked/unlocked (optional)
        observers.append(DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { _ in
            print("Screen locked")
        })
        
        observers.append(DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { _ in
            print("Screen unlocked")
        })
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: hasLaunchedBeforeKey)
        isFirstLaunch = !hasLaunchedBefore
    }
    
    private func handleFirstLaunch() {
        if isFirstLaunch {
            print("First app launch after login/reboot")
            systemStatus = .firstLaunch
            UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
            // Perform first-time setup here
        }
    }
    
    private func handleWake() {
        print("System woke from sleep")
        systemStatus = .wakeFromSleep
        didJustWake = true
        
        // Check how long we were asleep
        if let lastSleepDate = UserDefaults.standard.object(forKey: lastSleepDateKey) as? Date {
            let sleepDuration = Date().timeIntervalSince(lastSleepDate)
            print("System was asleep for \(sleepDuration) seconds")
        }
        
        // Reset wake flag after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.didJustWake = false
            self.systemStatus = .active
        }
        
        AppState.shared.handleWake()
    }
    
    deinit {
        observers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // Helper function to check if system recently woke up
    func recentlyWokeUp() -> Bool {
        guard let lastSleepDate = UserDefaults.standard.object(forKey: lastSleepDateKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(lastSleepDate) < 5 // Within last 5 seconds
    }
}
