//
//  Helpers.swift - General Helpers (Data converters, Time Format, etc.)
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import SwiftUI
import AppKit
import Foundation
import Network

class Helpers:ObservableObject {
    static let shared = Helpers() // Singleton for reusability
    let appState = AppState.shared
    @Published var processingVMName: String = ""
    
    init (){
    }
    
    deinit {
    }
    
    func restResponseToString(for intValue: Binding<Int?>) -> Binding<String> {
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
    
    func convertGMTToLocalTime(utcDateString: String) -> String {
        print("Input Date: " + utcDateString)
        
        // Define possible date formats
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ", // With milliseconds
            "yyyy-MM-dd'T'HH:mm:ssZ",     // Without milliseconds
            "yyyy-MM-dd'T'HH:mmZ",        // Without seconds
            "yyyy-MM-dd HH:mm:ss Z",      // Alternative format
            "yyyy-MM-dd HH:mm Z"          // Another alternative format
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC") // Set input time zone to UTC
        
        // Try each format until one succeeds
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: utcDateString) {
                // Convert the Date to local time
                dateFormatter.timeZone = TimeZone.current // Switch to local time zone
                dateFormatter.dateFormat = "dd.MM.yy (HH:mm)" // Your desired output format
                let localTimeString = dateFormatter.string(from: date)
                return localTimeString
            }
        }
        
        // If none of the formats worked
        print("Failed to parse the date string")
        return ""
    }
    
    // Button Start/Stop VM helper
    func startStopVM(iamToken:String,for vm: VMTableData) {
        if vm.status == "RUNNING" {
            //print("Stopping VM: \(vm.name)")
            self.processingVMName="Stopping VM: \(vm.name)"
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
            //print("Starting VM: \(vm.name)")
            self.processingVMName="Starting VM: \(vm.name)"
            // Call API to start the VM
            YandexAPIService.shared.startVM(iamToken:iamToken,vmId: vm.id) { result in
                DispatchQueue.main.async {
                    switch result {
                        case .success:
                            //print("VM started successfully")
                            self.appState.isVirtualMachineRunning = true
                        case .failure(let error):
                            print("Failed to start VM: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
//    func stopAllRunningVMs(iamToken: String, vms: [VMTableData]) {
//        let runningVMs = vms.filter { $0.status == "RUNNING" }
//        self.processingVMName="Sopping all VM's"
//        let group = DispatchGroup()
//        
//        for vm in runningVMs {
//            group.enter()
//            YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vm.id) { result in
//                DispatchQueue.main.async {
//                    switch result {
//                        case .success:
//                            print("VM stopped successfully: \(vm.name)")
//                        case .failure(let error):
//                            print("Failed to stop VM: \(error.localizedDescription)")
//                    }
//                    group.leave()
//                }
//            }
//        }
//    }
    func stopAllRunningVMs(iamToken: String, vms: [VMTableData]? = nil, vmIds: [String]? = nil) {
        if let vms = vms {
            let runningVMs = vms.filter { $0.status == "RUNNING" }
            self.processingVMName = "Stopping all VM's"
            for vm in runningVMs {
                // Just send requeust withpout waiting and main queue
                YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vm.id) { result in
                    // Логируем в фоне, если нужно
                    switch result {
                    case .success:
                        print("VM stopped successfully: \(vm.name)")
                    case .failure(let error):
                        print("Failed to stop VM: \(error.localizedDescription)")
                    }
                }
            }
        } else if let vmIds = vmIds {
            self.processingVMName = "Stopping VMs by IDs"
            
            for vmId in vmIds {
                // Just send requeust withpout waiting and main queue
                YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vmId) { result in
                    switch result {
                    case .success:
                        print("VM stopped successfully: \(vmId)")
                    case .failure(let error):
                        print("Failed to stop VM: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func startAllMarkedVMs(iamToken: String, vmIds: [String]? = nil) {
        // 1. Check if VM IDs were provided, otherwise fetch from SettingsManager
        let vmIdsToStart = vmIds ?? SettingsManager.shared.getAllAutostartVMs()
        
        // 2. Early return if no VMs to start
        guard !vmIdsToStart.isEmpty else {
            print("No VMs marked for auto-start")
            return
        }
        
        // 3. Start each VM asynchronously without blocking the main queue
        for vmId in vmIdsToStart {
            YandexAPIService.shared.startVM(iamToken: iamToken, vmId: vmId) { result in
                DispatchQueue.main.async {  // Ensure UI updates (if any) are on main thread
                    switch result {
                    case .success:
                        print("VM started successfully: \(vmId)")
                    case .failure(let error):
                        print("Failed to start VM \(vmId): \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func convertBytesToGB(bytes: String) -> String {
        // Convert the input string (bytes) to a Double
        guard let bytesValue = Double(bytes) else {
            return "0" // Return a default value if conversion fails
        }
        
        // Constants for conversion
        let bytesInGB: Double = 1024 * 1024 * 1024 // 1 GB = 1024 MB = 1024 * 1024 KB = 1024 * 1024 * 1024 bytes
        
        // Convert bytes to GB
        let sizeInGB = bytesValue / bytesInGB
        
        // Format the result to 2 decimal places
        return String(format: "%.2f", sizeInGB)
    }
    
    static func checkInternetConnection(completion: @escaping () -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetConnectionMonitor")

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                // Internet connection is available
                DispatchQueue.main.async {
                    completion() // Call the completion handler
                }
                monitor.cancel() // Stop monitoring once the connection is available
            }
        }

        // Start monitoring
        monitor.start(queue: queue)
    }
    
    static func billingBalanceFormatter(
        amount: String,
        currency: String,
        warningThreshold: Double = 50.0  // Default value of 50, but customizable
    ) -> AttributedString {
        guard !amount.isEmpty, !currency.isEmpty else {
            var result = AttributedString("N/A")
            result.foregroundColor = .primary
            return result
        }
        // Clean the input string
        let cleanedAmount = amount.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
        
        // Convert to Double and format
        if let balanceValue = Double(cleanedAmount) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.roundingMode = .halfUp
            
            if let formattedString = formatter.string(from: NSNumber(value: balanceValue)) {
                let fullString = "\(formattedString) \(currency)"
                var result = AttributedString(fullString)
                
                // Set color based on value using the warningThreshold
                if balanceValue < 0 {
                    result.foregroundColor = .red
                } else if balanceValue > 0 && balanceValue < warningThreshold {
                    result.foregroundColor = .orange
                } else {
                    result.foregroundColor = .green
                }
                
                return result
            }
        }
        
        // Fallback
        var result = AttributedString("\(amount) \(currency)")
        result.foregroundColor = .primary
        return result
    }
}

extension Binding where Value == Double {
    /// Converts a `Binding<Double>` to a `Binding<String>` with number formatting.
    func toFormattedString(
        numberStyle: NumberFormatter.Style = .decimal,
        maximumFractionDigits: Int = 2
    ) -> Binding<String> {
        Binding<String>(
            get: {
                let formatter = NumberFormatter()
                formatter.numberStyle = numberStyle
                formatter.maximumFractionDigits = maximumFractionDigits
                return formatter.string(from: NSNumber(value: self.wrappedValue)) ?? ""
            },
            set: { newValue in
                let formatter = NumberFormatter()
                formatter.numberStyle = numberStyle
                if let number = formatter.number(from: newValue) {
                    self.wrappedValue = number.doubleValue
                }
            }
        )
    }
}
