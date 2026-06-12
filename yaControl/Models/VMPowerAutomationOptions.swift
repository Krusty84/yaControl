//
//  VMPowerAutomationOptions.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum StartOption: String, CaseIterable {
    case afterAppLaunched = "after_app_launched"
    case afterMacOSStarted = "after_macos_started"
    case afterWakeup = "after_wakeup"
}

enum ShutdownOption: String, CaseIterable {
    case afterAppExit = "after_app_exit"
    case afterMacOSShutdown = "after_macos_shutdown"
    case afterMacOSSleep = "after_macos_sleep"
}

extension StartOption {
    static func fromStoredValue(_ value: String) -> StartOption? {
        switch value {
        case "after_app_launched", "After app launched":
            .afterAppLaunched
        case "after_macos_started", "After macOS started":
            .afterMacOSStarted
        case "after_wakeup", "After wakeup":
            .afterWakeup
        default:
            nil
        }
    }

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
    static func fromStoredValue(_ value: String) -> ShutdownOption? {
        switch value {
        case "after_app_exit", "After app exit":
            .afterAppExit
        case "after_macos_shutdown", "After macOS shutdown":
            .afterMacOSShutdown
        case "after_macos_sleep", "After macOS sleep":
            .afterMacOSSleep
        default:
            nil
        }
    }

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
