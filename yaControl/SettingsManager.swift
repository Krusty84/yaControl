//
//  SettingsManager.swift - Settings manager
//  WavesVista
//
//  Created by Sedoykin Alexey on 11/01/2025.
//

import Foundation

protocol VMPowerAutomationSettingsProviding: Sendable {
    var autoStartEnabled: Bool { get }
    var startOptions: [StartOption] { get }
    var shutdownOptions: [ShutdownOption] { get }
    var oAuthKey: String { get }
    var appLanguage: AppLanguage { get }

    func getAllAutostartVMs() -> [String]
    func cleanupAutostartSettings(validVMIds: Set<String>)
}

final class SettingsManager: @unchecked Sendable {
    static let shared = SettingsManager()
    private let defaults: UserDefaults
    // Keys
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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

//    var widgetRefreshIntervalMinutes: Int {
//        get {
//            guard defaults.object(forKey: widgetRefreshIntervalMinutesKey) != nil else {
//                return widgetDefaultRefreshIntervalMinutes
//            }
//
//            return max(defaults.integer(forKey: widgetRefreshIntervalMinutesKey), 5)
//        }
//        set { defaults.set(max(newValue, 5), forKey: widgetRefreshIntervalMinutesKey) }
//    }
    
    var widgetRefreshIntervalMinutes: Int {
        get {
            WidgetSharedSettings.refreshIntervalMinutes
        }

        set {
            WidgetSharedSettings.refreshIntervalMinutes = newValue
        }
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
                return [.afterAppLaunched]
            }

            do {
                let strings = try JSONDecoder().decode([String].self, from: data)
                let options = canonicalStartOptions(strings.compactMap(StartOption.fromStoredValue))
                persistMigratedOptionsIfNeeded(
                    originalStrings: strings,
                    migratedStrings: options.map(\.rawValue),
                    key: startOptionsKey
                )
                return options
            } catch {
                LoggerHelper.error("Failed to decode start options: \(error.localizedDescription)")
                return [.afterAppLaunched]
            }
        }
        set {
            let strings = canonicalStartOptions(newValue).map(\.rawValue)
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
                return []
            }

            do {
                let strings = try JSONDecoder().decode([String].self, from: data)
                let options = canonicalShutdownOptions(strings.compactMap(ShutdownOption.fromStoredValue))
                persistMigratedOptionsIfNeeded(
                    originalStrings: strings,
                    migratedStrings: options.map(\.rawValue),
                    key: shutdownOptionsKey
                )
                return options
            } catch {
                LoggerHelper.error("Failed to decode shutdown options: \(error.localizedDescription)")
                return []
            }
        }
        set {
            let strings = canonicalShutdownOptions(newValue).map(\.rawValue)
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

    private func canonicalStartOptions(_ options: [StartOption]) -> [StartOption] {
        let selected = Set(options)
        return StartOption.allCases.filter { selected.contains($0) }
    }

    private func canonicalShutdownOptions(_ options: [ShutdownOption]) -> [ShutdownOption] {
        let selected = Set(options)
        return ShutdownOption.allCases.filter { selected.contains($0) }
    }

    private func persistMigratedOptionsIfNeeded(
        originalStrings: [String],
        migratedStrings: [String],
        key: String
    ) {
        guard originalStrings != migratedStrings else { return }

        do {
            let data = try JSONEncoder().encode(migratedStrings)
            defaults.set(data, forKey: key)
        } catch {
            LoggerHelper.error("Failed to persist migrated VM automation options: \(error.localizedDescription)")
        }
    }
}

extension SettingsManager: VMPowerAutomationSettingsProviding {}
