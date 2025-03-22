//
//  AppState.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 22/03/2025.
//

import Foundation
import Combine
import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var isConnectedToInternet: Bool = false {
        didSet {
            print("isConnectedToInternet changed: \(isConnectedToInternet)") // Debug log
        }
    }

    @Published var accountBalance: Double = 0.0 {
        didSet {
            print("accountBalance changed: \(accountBalance)") // Debug log
        }
    }

    @Published var isVirtualMachineRunning: Bool = false {
        didSet {
            print("isVirtualMachineRunning changed: \(isVirtualMachineRunning)") // Debug log
        }
    }
    
        // Create a Binding for isConnectedToInternet
        var isConnectedToInternetBinding: Binding<Bool> {
            Binding(
                get: { self.isConnectedToInternet },
                set: { self.isConnectedToInternet = $0 }
            )
        }

        init() {
            // Start monitoring internet connection
            Helpers.checkInternetConnection(isConnected: isConnectedToInternetBinding)
        }
}
