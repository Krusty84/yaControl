//
//  yaControlApp.swift - ENTRY POINT OF APP
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI
import AppKit

@main
struct YaControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow
    @State private var appState = AppState.shared
    @AppStorage("com.krusty84.yaControl.settings.appLanguage")
    private var appLanguageRawValue: String = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    init() {
        // Initialize the app lifecycle observer
        _ = AppLifecycleObserver.shared

        Task {
            await VMPowerAutomationService.shared.handleAppLaunch()
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environment(\.locale, appLanguage.locale)
                .id(appLanguage.rawValue)
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
