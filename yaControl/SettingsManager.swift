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
    
    // Keys - Add "Key" suffix to avoid naming conflicts
    private let oAuthKeyKey = "oAuthKey"
    private let autoStartEnabledKey = "autoStartEnabled"
    private let startOptionsKey = "startOptions"
    private let shutdownOptionsKey = "shutdownOptions"
    private let autostartVMIdsKey = "autostart_vm_ids"
    
    // General Settings
    var oAuthKey: String {
        get { defaults.string(forKey: oAuthKeyKey) ?? "" }
        set { defaults.set(newValue, forKey: oAuthKeyKey) }
    }
    
    // VM Management Settings
    var autoStartEnabled: Bool {
        get { defaults.bool(forKey: autoStartEnabledKey) }
        set { defaults.set(newValue, forKey: autoStartEnabledKey) }
    }
    
    var startOptions: [SettingsTabContent.StartOption] {
        get {
            guard let data = defaults.data(forKey: startOptionsKey),
                  let options = try? JSONDecoder().decode([String].self, from: data) else {
                return [.afterAppLaunched, .afterMacOSStarted] // Default values
            }
            return options.compactMap { SettingsTabContent.StartOption(rawValue: $0) }
        }
        set {
            let strings = newValue.map { $0.rawValue }
            if let data = try? JSONEncoder().encode(strings) {
                defaults.set(data, forKey: startOptionsKey)
            }
        }
    }
    
    var shutdownOptions: [SettingsTabContent.ShutdownOption] {
        get {
            guard let data = defaults.data(forKey: shutdownOptionsKey),
                  let options = try? JSONDecoder().decode([String].self, from: data) else {
                return [.afterAppExit, .afterMacOSShutdown] // Default values
            }
            return options.compactMap { SettingsTabContent.ShutdownOption(rawValue: $0) }
        }
        set {
            let strings = newValue.map { $0.rawValue }
            if let data = try? JSONEncoder().encode(strings) {
                defaults.set(data, forKey: shutdownOptionsKey)
            }
        }
    }
    
    // VM-specific autostart methods (unchanged from your original)
    func markVMtoAutostart(for vmId: String, isAutoStarted: Bool) {
        // Set the individual flag (existing behavior)
        defaults.set(isAutoStarted, forKey: "vm_\(vmId)_isSelected")
        
        // Maintain a set of all VM IDs marked for autostart (new functionality)
        var autostartIds = getAutostartVMIds()
        if isAutoStarted {
            autostartIds.insert(vmId)
        } else {
            autostartIds.remove(vmId)
        }
        defaults.set(Array(autostartIds), forKey: autostartVMIdsKey)
    }
    
    func getAutostartedVMs(for vmId: String) -> Bool {
        return defaults.bool(forKey: "vm_\(vmId)_isSelected")
    }
    
    private func getAutostartVMIds() -> Set<String> {
        let ids = defaults.array(forKey: autostartVMIdsKey) as? [String] ?? []
        return Set(ids)
    }
    
    func getAllAutostartVMs() -> [String] {
        return Array(getAutostartVMIds())
    }
    
    // clean autostart marker for unavaliable VM's in cloud
    func cleanupAutostartSettings(validVMIds: Set<String>) {
        let storedAutostartIds = getAutostartVMIds()
        let idsToRemove = storedAutostartIds.subtracting(validVMIds)
        
        if !idsToRemove.isEmpty {
            // Update master list
            let updatedIds = storedAutostartIds.subtracting(idsToRemove)
            defaults.set(Array(updatedIds), forKey: autostartVMIdsKey)
            
            // Remove individual settings
            for id in idsToRemove {
                defaults.removeObject(forKey: "vm_\(id)_isSelected")
            }
        }
    }
}

