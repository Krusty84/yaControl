//
//  SettingsManager.swift - Settings manager
//  WavesVista
//
//  Created by Sedoykin Alexey on 11/01/2025.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard
    // Keys
    private let oAuthKey_ = "com.krusty84.yaControl.settings.oAuthKey"
    private let billingThresholdKey = "com.krusty84.yaControl.settings.billingThreshold"
    private let billingDefaultThreshold = 50.0
    private let autoStartEnabledKey = "com.krusty84.yaControl.settings.autoStartEnabled"
    private let appLoggingEnabledKey = "com.krusty84.yaControl.settings.appLoggingEnabled"
    private let startOptionsKey = "com.krusty84.yaControl.settings.startOptions"
    private let shutdownOptionsKey = "com.krusty84.yaControl.settings.shutdownOptions"
    private let autostartVMIdsKey = "com.krusty84.yaControl.settings.autostart_vm_ids"
    private let generalUsername4VMs_ = "com.krusty84.yaControl.settings.generalUsername4VMs"

    // General
    var appLoggingEnabled: Bool {
        get { defaults.bool(forKey: appLoggingEnabledKey) }
        set { defaults.set(newValue, forKey: appLoggingEnabledKey) }
    }
    
    var oAuthKey: String {
        get { defaults.string(forKey: oAuthKey_) ?? "" }
        set { defaults.set(newValue, forKey: oAuthKey_) }
    }

    var generalUsername4VMs: String {
        get { defaults.string(forKey: generalUsername4VMs_) ?? "" }
        set { defaults.set(newValue, forKey: generalUsername4VMs_) }
    }

    // Billing (fallback to default if no value stored)
    var billingThreshold: Double {
        get {
            if defaults.object(forKey: billingThresholdKey) == nil {
                return billingDefaultThreshold
            }
            return defaults.double(forKey: billingThresholdKey)
        }
        set {
            defaults.set(newValue, forKey: billingThresholdKey)
        }
    }

    // VM Management
    var autoStartEnabled: Bool {
        get { defaults.bool(forKey: autoStartEnabledKey) }
        set { defaults.set(newValue, forKey: autoStartEnabledKey) }
    }

    var startOptions: [SettingsTabContent.StartOption] {
        get {
            guard
                let data = defaults.data(forKey: startOptionsKey),
                let strings = try? JSONDecoder().decode([String].self, from: data)
            else {
                return [.afterAppLaunched, .afterMacOSStarted]
            }
            return strings.compactMap { .init(rawValue: $0) }
        }
        set {
            let strings = newValue.map(\.rawValue)
            if let data = try? JSONEncoder().encode(strings) {
                defaults.set(data, forKey: startOptionsKey)
            }
        }
    }

    var shutdownOptions: [SettingsTabContent.ShutdownOption] {
        get {
            guard
                let data = defaults.data(forKey: shutdownOptionsKey),
                let strings = try? JSONDecoder().decode([String].self, from: data)
            else {
                return [.afterAppExit, .afterMacOSShutdown]
            }
            return strings.compactMap { .init(rawValue: $0) }
        }
        set {
            let strings = newValue.map(\.rawValue)
            if let data = try? JSONEncoder().encode(strings) {
                defaults.set(data, forKey: shutdownOptionsKey)
            }
        }
    }

    // Per-VM autostart
    func markVMtoAutostart(for vmId: String, isAutoStarted: Bool) {
        defaults.set(isAutoStarted, forKey: "vm_\(vmId)_isSelected")
        var ids = getAutostartVMIds()
        if isAutoStarted { ids.insert(vmId) } else { ids.remove(vmId) }
        defaults.set(Array(ids), forKey: autostartVMIdsKey)
    }

    func getAutostartedVMs(for vmId: String) -> Bool {
        return defaults.bool(forKey: "vm_\(vmId)_isSelected")
    }

    private func getAutostartVMIds() -> Set<String> {
        let arr = defaults.array(forKey: autostartVMIdsKey) as? [String] ?? []
        return Set(arr)
    }

    func getAllAutostartVMs() -> [String] {
        return Array(getAutostartVMIds())
    }

    func cleanupAutostartSettings(validVMIds: Set<String>) {
        let stored = getAutostartVMIds()
        let toRemove = stored.subtracting(validVMIds)
        guard !toRemove.isEmpty else { return }

        let updated = stored.subtracting(toRemove)
        defaults.set(Array(updated), forKey: autostartVMIdsKey)

        toRemove.forEach { defaults.removeObject(forKey: "vm_\($0)_isSelected") }
    }
}


