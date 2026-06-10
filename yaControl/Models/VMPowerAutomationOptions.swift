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
            LocalizedStringHelper.string(L10n.VMAutomation.startAfterAppLaunched, language: SettingsManager.shared.appLanguage)
        case .afterMacOSStarted:
            LocalizedStringHelper.string(L10n.VMAutomation.startAfterMacOSStarted, language: SettingsManager.shared.appLanguage)
        case .afterWakeup:
            LocalizedStringHelper.string(L10n.VMAutomation.startAfterWakeup, language: SettingsManager.shared.appLanguage)
        }
    }
}

extension ShutdownOption {
    var localizedTitle: String {
        switch self {
        case .afterAppExit:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterAppExit, language: SettingsManager.shared.appLanguage)
        case .afterMacOSShutdown:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterMacOSShutdown, language: SettingsManager.shared.appLanguage)
        case .afterMacOSSleep:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterMacOSSleep, language: SettingsManager.shared.appLanguage)
        }
    }
}
