//
//  yaControlApp.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

@main
struct yaControlApp: App {
    @StateObject private var appState = AppState.shared
    init() {
        LoggerHelper.info("!@ yaControlApp initialized, Yeah!")
    }
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
          MenuBarExtra {
              MainWindow()
          } label: {
              MenuBarIcon(appState: appState)
              
          }
          .menuBarExtraStyle(.window)
      }
}
 
 

