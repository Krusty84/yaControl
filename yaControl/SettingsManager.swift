//
//  SettingsManager.swift - Settings manager
//  WavesVista
//
//  Created by Sedoykin Alexey on 11/01/2025.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager() // Singleton instance
    
    private let defaults = UserDefaults.standard
    private let autostartVMIdsKey = "autostart_vm_ids" // Key for storing autostart VM IDs
    
    private init() {} // Private initializer to prevent instantiation
    
    // Properties with default values
    var oAuthKey: String {
        get { defaults.string(forKey: "oAuthKey") ?? "" }
        set { defaults.set(newValue, forKey: "oAuthKey") }
    }
    
    // Mark VM for autostart
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
    
    // Get autostart status for a VM (existing behavior)
    func getAutostartedVMs(for vmId: String) -> Bool {
        return defaults.bool(forKey: "vm_\(vmId)_isSelected")
    }
    
    // Helper function to get all autostart VM IDs
    private func getAutostartVMIds() -> Set<String> {
        let ids = defaults.array(forKey: autostartVMIdsKey) as? [String] ?? []
        return Set(ids)
    }
    
    // Optional: Get all VMs marked for autostart
    func getAllAutostartVMs() -> [String] {
        return Array(getAutostartVMIds())
    }
}
