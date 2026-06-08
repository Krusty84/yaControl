//
//  RDPFileLauncher.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import AppKit
import Foundation

enum RDPFileLauncher {
    static func openRDPClient(to ip: String, username: String = "Administrator") {
        let lines = [
            "full address:s:\(ip):3389",
            "username:s:\(username)"
        ]
        let content = lines.joined(separator: "\r\n")

        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("connection.rdp")
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(fileURL)
        } catch {
            LoggerHelper.error("Could not write RDP file: \(error)")
        }
    }
}
