//
//  SettingsManager.swift - Settings manager
//  WavesVista
//
//  Created by Sedoykin Alexey on 11/01/2025.
//

import Foundation

final class SettingsManager: @unchecked Sendable {
    static let shared = SettingsManager()
    private let defaults = UserDefaults.standard
    // Keys
    private let legacyOAuthKey = "com.krusty84.yaControl.settings.oAuthKey"
    private let billingThresholdKey = "com.krusty84.yaControl.settings.billingThreshold"
    private let billingDefaultThreshold = 50.0
    private let autoStartEnabledKey = "com.krusty84.yaControl.settings.autoStartEnabled"
    private let appLoggingEnabledKey = "com.krusty84.yaControl.settings.appLoggingEnabled"
    private let apiDebugEnabledKey = "com.krusty84.yaControl.settings.apiDebugEnabled"
    private let appLanguageKey = "com.krusty84.yaControl.settings.appLanguage"
    private let ycCLIInstalledKey = "com.krusty84.yaControl.settings.ycCLIInstalled"
    private let defaultFolderIdForCreationKey = "com.krusty84.yaControl.settings.defaultFolderIdForCreation"
    private let startOptionsKey = "com.krusty84.yaControl.settings.startOptions"
    private let shutdownOptionsKey = "com.krusty84.yaControl.settings.shutdownOptions"
    private let autostartVMIdsKey = "com.krusty84.yaControl.settings.autostart_vm_ids"
    private let generalUsername4VMs_ = "com.krusty84.yaControl.settings.generalUsername4VMs"
    private let widgetAutoRefreshEnabledKey = "com.krusty84.yaControl.settings.widgetAutoRefreshEnabled"
    private let widgetRefreshIntervalMinutesKey = "com.krusty84.yaControl.settings.widgetRefreshIntervalMinutes"
    private let widgetDefaultRefreshIntervalMinutes = 30

    init() {
        migrateLegacyOAuthToken()
    }

    // General
    var appLoggingEnabled: Bool {
        get { defaults.bool(forKey: appLoggingEnabledKey) }
        set { defaults.set(newValue, forKey: appLoggingEnabledKey) }
    }
    
    var apiDebugEnabled: Bool {
        get { defaults.bool(forKey: apiDebugEnabledKey) }
        set { defaults.set(newValue, forKey: apiDebugEnabledKey) }
    }

    var appLanguage: AppLanguage {
        get {
            guard let rawValue = defaults.string(forKey: appLanguageKey) else {
                return .system
            }

            return AppLanguage(rawValue: rawValue) ?? .system
        }
        set { defaults.set(newValue.rawValue, forKey: appLanguageKey) }
    }
    
    var ycCLIInstalled: Bool {
        get { defaults.bool(forKey: ycCLIInstalledKey) }
        set { defaults.set(newValue, forKey: ycCLIInstalledKey) }
    }
    
    var defaultFolderIdForCreation: String {
        get { defaults.string(forKey: defaultFolderIdForCreationKey) ?? "" }
        set { defaults.set(newValue, forKey: defaultFolderIdForCreationKey) }
    }

    var widgetAutoRefreshEnabled: Bool {
        get {
            guard defaults.object(forKey: widgetAutoRefreshEnabledKey) != nil else {
                return true
            }

            return defaults.bool(forKey: widgetAutoRefreshEnabledKey)
        }
        set { defaults.set(newValue, forKey: widgetAutoRefreshEnabledKey) }
    }

    var widgetRefreshIntervalMinutes: Int {
        get {
            guard defaults.object(forKey: widgetRefreshIntervalMinutesKey) != nil else {
                return widgetDefaultRefreshIntervalMinutes
            }

            return max(defaults.integer(forKey: widgetRefreshIntervalMinutesKey), 5)
        }
        set { defaults.set(max(newValue, 5), forKey: widgetRefreshIntervalMinutesKey) }
    }
    
    var oAuthKey: String {
        get {
            do {
                return try KeychainTokenStore.shared.readOAuthToken() ?? ""
            } catch {
                LoggerHelper.error("Failed to read OAuth token from Keychain: \(error.localizedDescription)")
                return ""
            }
        }
        set {
            do {
                if newValue.isEmpty {
                    try KeychainTokenStore.shared.deleteOAuthToken()
                } else {
                    try KeychainTokenStore.shared.saveOAuthToken(newValue)
                }
            } catch {
                LoggerHelper.error("Failed to update OAuth token in Keychain: \(error.localizedDescription)")
            }
        }
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

    var startOptions: [StartOption] {
        get {
            guard let data = defaults.data(forKey: startOptionsKey) else {
                return [.afterAppLaunched, .afterMacOSStarted]
            }

            do {
                let strings = try JSONDecoder().decode([String].self, from: data)
                return strings.compactMap(StartOption.fromStoredValue)
            } catch {
                LoggerHelper.error("Failed to decode start options: \(error.localizedDescription)")
                return [.afterAppLaunched, .afterMacOSStarted]
            }
        }
        set {
            let strings = newValue.map(\.rawValue)
            do {
                let data = try JSONEncoder().encode(strings)
                defaults.set(data, forKey: startOptionsKey)
            } catch {
                LoggerHelper.error("Failed to encode start options: \(error.localizedDescription)")
            }
        }
    }

    var shutdownOptions: [ShutdownOption] {
        get {
            guard let data = defaults.data(forKey: shutdownOptionsKey) else {
                return [.afterAppExit, .afterMacOSShutdown]
            }

            do {
                let strings = try JSONDecoder().decode([String].self, from: data)
                return strings.compactMap(ShutdownOption.fromStoredValue)
            } catch {
                LoggerHelper.error("Failed to decode shutdown options: \(error.localizedDescription)")
                return [.afterAppExit, .afterMacOSShutdown]
            }
        }
        set {
            let strings = newValue.map(\.rawValue)
            do {
                let data = try JSONEncoder().encode(strings)
                defaults.set(data, forKey: shutdownOptionsKey)
            } catch {
                LoggerHelper.error("Failed to encode shutdown options: \(error.localizedDescription)")
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

    private func migrateLegacyOAuthToken() {
        if let token = defaults.string(forKey: legacyOAuthKey), !token.isEmpty {
            do {
                try KeychainTokenStore.shared.saveOAuthToken(token)
                defaults.removeObject(forKey: legacyOAuthKey)
            } catch {
                LoggerHelper.error("Failed to migrate OAuth token to Keychain: \(error.localizedDescription)")
            }
        } else {
            defaults.removeObject(forKey: legacyOAuthKey)
        }
    }
}
