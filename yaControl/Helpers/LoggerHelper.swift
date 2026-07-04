//
//  LoggerHelper.swift - The Helper for write events to MacOS logs
//  yaControl
//
//  Created by Sedoykin Alexey on 20/03/2025.
//

import Foundation
import OSLog

struct LoggerHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.app", category: "General")

    static func info(_ message: String,
                     function: String = #function,
                     file: String = #file,
                     line: Int = #line) {
        guard SettingsManager.shared.appLoggingEnabled else { return }
        let redactedMessage = LogRedactionHelper.redact(message)
        logger.info("[\(extractFileName(file)):\(line)] \(function) - \(redactedMessage, privacy: .public)")
    }

    static func debug(_ message: String,
                      function: String = #function,
                      file: String = #file,
                      line: Int = #line) {
        guard SettingsManager.shared.appLoggingEnabled else { return }
        let redactedMessage = LogRedactionHelper.redact(message)
        logger.debug("[\(extractFileName(file)):\(line)] \(function) - \(redactedMessage, privacy: .public)")
    }

    static func error(_ message: String,
                      function: String = #function,
                      file: String = #file,
                      line: Int = #line) {
        guard SettingsManager.shared.appLoggingEnabled else { return }
        let redactedMessage = LogRedactionHelper.redact(message)
        logger.error("[\(extractFileName(file)):\(line)] \(function) - \(redactedMessage, privacy: .public)")
    }

    private static func extractFileName(_ path: String) -> String {
        return (path as NSString).lastPathComponent
    }
}
