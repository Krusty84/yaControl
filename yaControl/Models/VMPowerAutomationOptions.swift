//
//  VMPowerAutomationOptions.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import Foundation

enum StartOption: String, CaseIterable, Sendable {
    case afterAppLaunched = "after_app_launched"
    case afterWakeup = "after_wakeup"
}

enum ShutdownOption: String, CaseIterable, Sendable {
    case afterAppExit = "after_app_exit"
    case beforeMacOSSleep = "before_macos_sleep"
    case beforeMacOSLogout = "before_macos_logout"
}

extension StartOption {
    static func fromStoredValue(_ value: String) -> StartOption? {
        switch value {
        case "after_app_launched", "After app launched":
            .afterAppLaunched
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
        case "before_macos_sleep", "after_macos_sleep", "After macOS sleep", "Before macOS sleep":
            .beforeMacOSSleep
        case "before_macos_shutdown", "after_macos_shutdown", "After macOS shutdown", "Before macOS logout or shutdown":
            .beforeMacOSLogout
        default:
            nil
        }
    }

    func localizedTitle(locale: Locale) -> String {
        switch self {
        case .afterAppExit:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownAfterAppExit, locale: locale)
        case .beforeMacOSSleep:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownBeforeMacOSSleep, locale: locale)
        case .beforeMacOSLogout:
            LocalizedStringHelper.string(L10n.VMAutomation.shutdownBeforeMacOSLogout, locale: locale)
        }
    }
}
