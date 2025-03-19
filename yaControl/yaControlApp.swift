//
//  yaControlApp.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

@main
struct yaControlApp: App {
    init(){
        
    }
      @Environment(\.openWindow) var openWindow
      var body: some Scene {
          MenuBarExtra {
              MainWindow()
          } label: {
              let image: NSImage = {
                  let ratio = $0.size.height / $0.size.width
                  $0.size.height = 18
                  $0.size.width = 18 / ratio
                  return $0
              }(NSImage(named: "AppIcon")!)
              Image(nsImage: image)
          }
          .menuBarExtraStyle(.window)
      }
  }
 
 

