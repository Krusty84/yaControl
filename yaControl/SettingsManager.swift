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
      private let autostartKeyPrefix = "vm_autostart_"
      
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
        let key = autostartKeyPrefix + vmId
        defaults.set(isAutoStarted, forKey: key)
    }
    
    func getAutostartedVMs(for vmId: String) -> Bool {
        let key = autostartKeyPrefix + vmId
        return defaults.bool(forKey: key)
    }
    
//    func cleanupAutostartSettings(activeVMIds: [String]) {
//        let allKeys = defaults.dictionaryRepresentation().keys
//        let autostartKeys = allKeys.filter { $0.hasPrefix(autostartKeyPrefix) }
//        
//        let orphanedKeys = autostartKeys.filter { key in
//            let vmId = key.replacingOccurrences(of: autostartKeyPrefix, with: "")
//            return !activeVMIds.contains(vmId)
//        }
//        
//        orphanedKeys.forEach { defaults.removeObject(forKey: $0) }
//    }
    
    func cleanupAutostartSettings(activeVMIds: [String]) {
        // Create a set for faster lookups (O(1) instead of O(n))
        let activeIdsSet = Set(activeVMIds)
        print("zzzzz", activeIdsSet)
        // Get all autostart keys
        let allKeys = defaults.dictionaryRepresentation().keys
        let autostartKeys = allKeys.filter { $0.hasPrefix(autostartKeyPrefix) }
        
        // Process each key
        autostartKeys.forEach { key in
            print("key", key)
            let vmId = key.replacingOccurrences(of: autostartKeyPrefix, with: "")
            
            // Check if the VM ID is empty or not in active IDs
            if vmId.isEmpty || !activeIdsSet.contains(vmId) {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    func getValidAutostartedVMs_SUS(activeVMIds: [String]) -> [String] {
        return activeVMIds.filter { getAutostartedVMs(for: $0) }
    }
    
    func getAllAutostartVMs_SUS() -> [String] {
        let allKeys = defaults.dictionaryRepresentation().keys
        return allKeys
            .filter { $0.hasPrefix(autostartKeyPrefix) }
            .map { $0.replacingOccurrences(of: autostartKeyPrefix, with: "") }
    }
}

