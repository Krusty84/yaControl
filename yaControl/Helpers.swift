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

func convertGMTToLocalTime(utcDateString: String) -> String? {
    // Create a DateFormatter to parse the input string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // ISO 8601 format
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC") // Set the input time zone to UTC

        // Convert the string to a Date object
        guard let date = dateFormatter.date(from: utcDateString) else {
            print("Failed to parse the date string")
            return nil
        }

        // Convert the Date to local time
        dateFormatter.timeZone = TimeZone.current // Switch to the device's local time zone
        dateFormatter.dateFormat = "dd.MM.yy (HH:mm)" // Your desired format

        let localTimeString = dateFormatter.string(from: date)
        return localTimeString
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

func stopAllRunningVMs(iamToken: String, vms: [VMTableData]) {
       let runningVMs = vms.filter { $0.status == "RUNNING" }
       let group = DispatchGroup()
       
       for vm in runningVMs {
           group.enter()
           YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vm.id) { result in
               DispatchQueue.main.async {
                   switch result {
                   case .success:
                       print("VM stopped successfully: \(vm.name)")
                   case .failure(let error):
                       print("Failed to stop VM: \(error.localizedDescription)")
                   }
                   group.leave()
               }
           }
       }
   }
