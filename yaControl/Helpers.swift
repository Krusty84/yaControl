//
//  Helpers.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import SwiftUI

func numberStringBinding(for intValue: Binding<Int?>) -> Binding<String> {
    Binding(
        get: {
            // Convert Int? to String (use "" if nil)
            intValue.wrappedValue.map(String.init) ?? ""
        },
        set: { newValue in
            // Convert String back to Int?
            intValue.wrappedValue = Int(newValue)
        }
    )
}

func startStopVM(iamToken:String,for vm: VMTableData) {
    if vm.status == "RUNNING" {
        print("Stopping VM: \(vm.name)")
        // Call API to stop the VM
        YandexAPIService.shared.stopVM(iamToken:iamToken, vmId: vm.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("VM stopped successfully")
                    // Update the VM status in the UI
                case .failure(let error):
                    print("Failed to stop VM: \(error.localizedDescription)")
                }
            }
        }
    } else {
        print("Starting VM: \(vm.name)")
        // Call API to start the VM
        YandexAPIService.shared.startVM(iamToken:iamToken,vmId: vm.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("VM started successfully")
                    // Update the VM status in the UI
                case .failure(let error):
                    print("Failed to start VM: \(error.localizedDescription)")
                }
            }
        }
    }
}
