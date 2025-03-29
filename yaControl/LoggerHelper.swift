//
//  LoggerHelper.swift - The Helper for write events to MacOS logs
//  yaControl
//
//  Created by Sedoykin Alexey on 20/03/2025.
//

import OSLog
import Foundation

/*
 Open Console app to get system events and events from this application, use: com.krusty84.yaControl as filter
 */
struct LoggerHelper {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "General")
    
    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
    
    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
    
    static func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }
}
