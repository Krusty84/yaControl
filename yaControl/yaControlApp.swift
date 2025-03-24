//
//  yaControlApp.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI
import AppKit

@main
struct yaControlApp: App {
    @Environment(\.openWindow) var openWindow
    @StateObject private var appState = AppState.shared
    
    init() {
            Helpers.checkInternetConnection {
                AppState.shared.checkNumRunningVMs()
            }
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
        } label: {
            MenuBarIcon(appState: appState)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarContentView: View {
    @State private var optionKeyPressed = false

    var body: some View {
        Group {
            if optionKeyPressed {
                InfoWindow()
            } else {
                MainWindow()
            }
        }
        .onAppear {
            optionKeyPressed = NSEvent.modifierFlags.contains(.option)
        }
    }
}


 
 

