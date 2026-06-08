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
