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
    func localizedTitle(locale: Locale) -> String {
        switch self {
        case .afterAppLaunched:
            LocalizedStringHelper.string(L10n.VMAutomation.startAfterAppLaunched, locale: locale)
        case .afterMacOSStarted:
            LocalizedStringHelper.string(L10n.VMAutomation.startAfterMacOSStarted, locale: locale)
        case .afterWakeup:
            LocalizedStringHelper.string(L10n.VMAutomation.startAfterWakeup, locale: locale)
        }
    }
}

extension ShutdownOption {
    func localizedTitle(locale: Locale) -> String {
        switch self {
        case .afterAppExit:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterAppExit, locale: locale)
        case .afterMacOSShutdown:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterMacOSShutdown, locale: locale)
        case .afterMacOSSleep:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterMacOSSleep, locale: locale)
        }
    }
}
