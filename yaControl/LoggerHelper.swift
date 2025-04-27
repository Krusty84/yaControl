//
//  LoggerHelper.swift - The Helper for write events to MacOS logs
//  yaControl
//
//  Created by Sedoykin Alexey on 20/03/2025.
//

import OSLog
import Foundation

/*
 Open Console app to get system events and events from this application, use: com.krusty84.yaControl as filter (subsystem)
 */

/*
 LoggerHelper.debug("Sending network request...", category: "Network")
 LoggerHelper.error("DB write failed", category: "Database")
 LoggerHelper.info("Main screen loaded", category: "UI")

 */
import OSLog
import Foundation

struct LoggerHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.app", category: "General")

    static func info(_ message: String,
                     function: String = #function,
                     file: String = #file,
                     line: Int = #line) {
        guard SettingsManager.shared.appLoggingEnabled else { return }
        logger.info("[\(extractFileName(file)):\(line)] \(function) - \(message, privacy: .public)")
    }

    static func debug(_ message: String,
                      function: String = #function,
                      file: String = #file,
                      line: Int = #line) {
        guard SettingsManager.shared.appLoggingEnabled else { return }
        logger.debug("[\(extractFileName(file)):\(line)] \(function) - \(message, privacy: .public)")
    }

    static func error(_ message: String,
                      function: String = #function,
                      file: String = #file,
                      line: Int = #line) {
        guard SettingsManager.shared.appLoggingEnabled else { return }
        logger.error("[\(extractFileName(file)):\(line)] \(function) - \(message, privacy: .public)")
    }

    private static func extractFileName(_ path: String) -> String {
        return (path as NSString).lastPathComponent
    }
}

