//
//  TerminalLauncher.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 08/06/2026.
//

import AppKit
import Foundation

enum TerminalLauncher {
    static func openTerminal() {
        if let url = URL(string: "file:///System/Applications/Utilities/Terminal.app") {
            NSWorkspace.shared.open(url)
        }
    }
}
