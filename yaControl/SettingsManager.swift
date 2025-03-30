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
    private let autostartKeyPrefix = "vm_autostart_"
    
    private init() {} // Private initializer to prevent instantiation
    
    // Properties with default values
    var oAuthKey: String {
        get { defaults.string(forKey: "oAuthKey") ?? "" }
        set { defaults.set(newValue, forKey: "oAuthKey") }
    }
    
    // Autostart Management
    
    func markVMtoAutostart(for vmId: String, isAutoStarted: Bool) {
        let key = autostartKeyPrefix + vmId
        defaults.set(isAutoStarted, forKey: key)
    }
    
    func getAutostartedVMs(for vmId: String) -> Bool {
        let key = autostartKeyPrefix + vmId
        return defaults.bool(forKey: key)
    }
    
    // Cleanup Methods
    func cleanupAutostartSettings(activeVMIds: [String]) {
        // Get all autostart keys from UserDefaults
        let allKeys = defaults.dictionaryRepresentation().keys
        let autostartKeys = allKeys.filter { $0.hasPrefix(autostartKeyPrefix) }
        
        // Find orphaned keys (where the VM no longer exists)
        let orphanedKeys = autostartKeys.filter { key in
            let vmId = key.replacingOccurrences(of: autostartKeyPrefix, with: "")
            return !activeVMIds.contains(vmId)
        }
        
        // Remove orphaned entries
        orphanedKeys.forEach { defaults.removeObject(forKey: $0) }
    }
    
    // Gets all VMs marked for autostart that still exist
    func getValidAutostartedVMs(activeVMIds: [String]) -> [String] {
        return activeVMIds.filter { getAutostartedVMs(for: $0) }
    }
    
    func getAllAutostartVMs() -> [String] {
        let allKeys = defaults.dictionaryRepresentation().keys
              return allKeys
                  .filter { $0.hasPrefix(autostartKeyPrefix) }
                  .map { $0.replacingOccurrences(of: autostartKeyPrefix, with: "") }
    }
}
