//
//  yaControlApp.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

@main
struct yaControlApp: App {
    @ObservedObject var helpers = Helpers.shared
    init(){
        LoggerHelper.info("!@ yaControlApp initialized, Yeah!")
    }
    @Environment(\.openWindow) var openWindow
    @StateObject private var networkMonitor = Helpers(onConnectedToWAN: {
         // This code will run when the internet connection is detected
         LoggerHelper.info("!@ Executing custom code after internet connection detected.")
         print("Custom code executed in yaControlApp!")
     })
    
      var body: some Scene {
          MenuBarExtra {
              MainWindow()
          } label: {
//              let image: NSImage = {
//                  let ratio = $0.size.height / $0.size.width
//                  $0.size.height = 18
//                  $0.size.width = 18 / ratio
//                  return $0
//              }(NSImage(named: "AppIcon")!)
//              Image(nsImage: image)
//              let iconColor: NSColor = isConnectedToInternet ? .green : .green // Change color based on connection status
//              Image(nsImage: helpers.tintedIcon(color: iconColor))
               MenuBarIcon(isConnectedToInternet: networkMonitor.isConnectedToWAN)
          }
          .menuBarExtraStyle(.window)
      }
  
}
 
 

