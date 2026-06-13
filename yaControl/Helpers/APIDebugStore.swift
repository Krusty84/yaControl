//
//  APIDebugStore.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class APIDebugStore {
    static let shared = APIDebugStore()

    var isEnabled: Bool {
        didSet {
            SettingsManager.shared.apiDebugEnabled = isEnabled
        }
    }

    var messages: String = ""

    private init() {
        self.isEnabled = SettingsManager.shared.apiDebugEnabled
    }

    func append(_ message: String) {
        guard isEnabled else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())

        if messages.isEmpty {
            messages = "[\(timestamp)]\n\(message)"
        } else {
            messages += "\n\n[\(timestamp)]\n\(message)"
        }
    }

    func clear() {
        messages = ""
    }

    func saveToExternalFile() {
        let panel = NSSavePanel()
        panel.title = "Save API Debug Log"
        panel.nameFieldStringValue = "yaControl-api-debug.log"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try messages.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            LoggerHelper.error("Failed to save API debug log: \(error.localizedDescription)")
        }
    }
}
