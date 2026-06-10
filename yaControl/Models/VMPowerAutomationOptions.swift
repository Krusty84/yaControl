//
//  VMPowerAutomationOptions.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum StartOption: String, CaseIterable {
    case afterAppLaunched = "After app launched"
    case afterMacOSStarted = "After macOS started"
    case afterWakeup = "After wakeup"
}

enum ShutdownOption: String, CaseIterable {
    case afterAppExit = "After app exit"
    case afterMacOSShutdown = "After macOS shutdown"
    case afterMacOSSleep = "After macOS sleep"
}

extension StartOption {
    var localizedTitle: String {
        switch self {
        case .afterAppLaunched:
            LocalizedStringHelper.string(L10n.VMStart.afterAppLaunched, language: SettingsManager.shared.appLanguage)
        case .afterMacOSStarted:
            LocalizedStringHelper.string(L10n.VMStart.afterMacOSStarted, language: SettingsManager.shared.appLanguage)
        case .afterWakeup:
            LocalizedStringHelper.string(L10n.VMStart.afterWakeup, language: SettingsManager.shared.appLanguage)
        }
    }
}

extension ShutdownOption {
    var localizedTitle: String {
        switch self {
        case .afterAppExit:
            LocalizedStringHelper.string(L10n.VMShutdown.afterAppExit, language: SettingsManager.shared.appLanguage)
        case .afterMacOSShutdown:
            LocalizedStringHelper.string(L10n.VMShutdown.afterMacOSShutdown, language: SettingsManager.shared.appLanguage)
        case .afterMacOSSleep:
            LocalizedStringHelper.string(L10n.VMShutdown.afterMacOSSleep, language: SettingsManager.shared.appLanguage)
        }
    }
}
