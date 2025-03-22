//
//  StateIndicator.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 22/03/2025.
//

import SwiftUI
import AppKit

// MARK: - Icon Color Rules

struct IconColorRule {
    let condition: (AppState) -> Bool // A closure that takes AppState and returns a Bool
    let color: NSColor // The color to use if the condition is true
}

let iconColorRules: [IconColorRule] = [
    IconColorRule(
        condition: { $0.isConnectedToInternet }, // Connected to the internet (highest priority)
        color: .systemBlue
    ),
    IconColorRule(
        condition: { $0.accountBalance < 0 }, // Account is in credit (negative balance)
        color: .systemRed
    ),
    IconColorRule(
        condition: { $0.accountBalance < 100 }, // Account balance is low
        color: .systemYellow
    ),
    IconColorRule(
        condition: { $0.isVirtualMachineRunning }, // At least one virtual machine is running
        color: .systemGreen
    ),
    IconColorRule(
        condition: { _ in true }, // Default rule (always matches)
        color: .systemGray
    )
]

// MARK: - Icon Color Determination

func determineIconColor(for appState: AppState) -> NSColor {
    for rule in iconColorRules {
        if rule.condition(appState) {
            print("Rule matched: \(rule.color)") // Debug log
            return rule.color
        }
    }
    return .systemGray // Fallback color (should never be reached)
}

// MARK: - Icon Tinting

func tintedIcon(named iconName: String, color: NSColor) -> NSImage {
    guard let icon = NSImage(named: iconName) else { return NSImage() } // Use your icon name here
    
    // Resize the icon to 18x18 points
    let newSize = NSSize(width: 18, height: 18)
    let resizedIcon = NSImage(size: newSize)
    
    resizedIcon.lockFocus()
    icon.draw(in: NSRect(origin: .zero, size: newSize))
    resizedIcon.unlockFocus()
    
    // Apply the tint color
    let tintedIcon = resizedIcon.copy() as! NSImage
    tintedIcon.lockFocus()
    
    color.set()
    let imageRect = NSRect(origin: .zero, size: newSize)
    imageRect.fill(using: .sourceAtop)
    
    tintedIcon.unlockFocus()
    return tintedIcon
}

struct MenuBarIcon: View {
    @ObservedObject var appState: AppState // Observe the AppState

    var body: some View {
        let iconColor = determineIconColor(for: appState) // Determine the icon color
        return Image(nsImage: tintedIcon(named: "AppIcon", color: iconColor)) // Tint the icon
    }
}
