//
//  NotificationManager.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 02/05/2025.
//

import UserNotifications
import SwiftUI

/*
 NotificationManager.shared.requestAuthorization()
 */
class NotificationManager: ObservableObject {
    
    static let shared = NotificationManager()
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                LoggerHelper.error("Notification authorization error: \(error.localizedDescription)")
            } else {
                LoggerHelper.info("Notification permission granted? \(granted)")
            }
        }
    }
    
    /*
     let message = lines.joined(separator: "\n")
     NotificationManager.shared.postNotification(
         title: "yaControl",
         body: message
     )
     */
    
    func postNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // No trigger means deliver immediately
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                LoggerHelper.error("Error posting notification: \(error.localizedDescription)")
            }
        }
    }
}
