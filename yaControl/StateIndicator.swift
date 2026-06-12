//
//  StateIndicator.swift - Helper for change Icon tining in Menu Bar (System Tray on Windows manner)
//  yaControl
//
//  Created by Sedoykin Alexey on 22/03/2025.
//

import SwiftUI
import AppKit

// MARK: - Icon Tinting

@MainActor
private final class MenuBarIconImageCache {
    static let shared = MenuBarIconImageCache()

    private let iconSize = NSSize(width: 18, height: 18)
    private var images: [String: NSImage] = [:]

    private init() {}

    func tintedIcon(named iconName: String, color: NSColor) -> NSImage {
        let key = cacheKey(iconName: iconName, color: color)

        if let image = images[key] {
            return image
        }

        let image = renderTintedIcon(named: iconName, color: color)
        images[key] = image
        return image
    }

    private func renderTintedIcon(named iconName: String, color: NSColor) -> NSImage {
        guard let icon = NSImage(named: iconName) else {
            return NSImage(size: iconSize)
        }

        let image = NSImage(size: iconSize)
        image.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: iconSize))
        color.set()
        NSRect(origin: .zero, size: iconSize).fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }

    private func cacheKey(iconName: String, color: NSColor) -> String {
        guard let rgbColor = color.usingColorSpace(.deviceRGB) else {
            return "\(iconName)-\(color.hash)"
        }

        return [
            iconName,
            rgbColor.redComponent.formatted(),
            rgbColor.greenComponent.formatted(),
            rgbColor.blueComponent.formatted(),
            rgbColor.alphaComponent.formatted()
        ].joined(separator: "-")
    }
}

// MARK: - MenuBar Implementation
struct MenuBarIcon: View {
    let appState: AppState
    private let iconCache = MenuBarIconImageCache.shared

    var body: some View {
        Image(nsImage: iconCache.tintedIcon(named: "AppIcon", color: appState.menuBarIconColor))
    }
}
