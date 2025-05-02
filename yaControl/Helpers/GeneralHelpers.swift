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
import Combine

class Helpers:ObservableObject {
    static let shared = Helpers() // Singleton for reusability
    let appState = AppState.shared
    // Polling-related properties
    @Published private var pollingVMs: Set<String> = []
    private var cancellables: Set<AnyCancellable> = []
    private let pollingInterval: TimeInterval = 2.0
    
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
        LoggerHelper.error("Failed to parse the date string")
        return ""
    }
    
    // Button Start/Stop VM helper
    func startStopVM(iamToken: String, for vm: VMTableData) {
        
        Task {
            do {
                if vm.status == "RUNNING" {
                    try await YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vm.id)
                    LoggerHelper.info("VM stopped successfully")
                } else if vm.status == "STOPPED"{
                    try await YandexAPIService.shared.startVM(iamToken: iamToken, vmId: vm.id)
                    LoggerHelper.info("VM started successfully")
                }
                
                // Refresh VM list after operation completes
//                await MainActor.run {
//                    self.fetchVMs() // Assuming you have a refresh function
//                }
                
            } catch {
                await MainActor.run {
                    LoggerHelper.error("Failed to \(vm.status == "RUNNING" ? "stop" : "start") VM: \(error.localizedDescription)")
                }
            }
            
            // Clear processing state
//            await MainActor.run {
//                self.processingVMName = ""
//            }
        }
    }
    
    func stopAllRunningVMs(iamToken: String, vms: [VMTableData]? = nil, vmIds: [String]? = nil) {
 
        Task {
            do {
                if let vms = vms {
                    let runningVMs = vms.filter { $0.status == "RUNNING" }
                    // Process all VMs concurrently
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for vm in runningVMs {
                            group.addTask {
                                try await YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vm.id)
                                LoggerHelper.info("VM stopped successfully: \(vm.name)")
                            }
                        }
                        // Wait for all tasks to complete
                        try await group.waitForAll()
                    }
                } else if let vmIds = vmIds {
                    // Process all VM IDs concurrently
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for vmId in vmIds {
                            group.addTask {
                                try await YandexAPIService.shared.stopVM(iamToken: iamToken, vmId: vmId)
                                LoggerHelper.info("VM stopped successfully: \(vmId)")
                            }
                        }
                        // Wait for all tasks to complete
                        try await group.waitForAll()
                    }
                }
                
                // Refresh VM list after all operations complete
//                await MainActor.run {
//                    self.fetchVMs() // Assuming you have a refresh function
//                    self.processingVMName = nil
//                }
                
            } catch {
                await MainActor.run {
                    LoggerHelper.error("Error stopping VMs: \(error.localizedDescription)")
                    //self.processingVMName = nil
                    //self.processingVMName = ""
                }
            }
        }
    }
        
    func startAllMarkedVMs(iamToken: String, vmIds: [String]? = nil) async {
        // 1. Get VM IDs to start
        let vmIdsToStart = vmIds ?? SettingsManager.shared.getAllAutostartVMs()
        // 2. Early return if no VMs to start
        guard !vmIdsToStart.isEmpty else {
            LoggerHelper.info("No VMs marked for auto-start")
            return
        }
        
        // 3. Process all VMs concurrently with structured concurrency
        await withTaskGroup(of: Void.self) { group in
            for vmId in vmIdsToStart {
                group.addTask {
                    do {
                        try await YandexAPIService.shared.startVM(iamToken: iamToken, vmId: vmId)
                        LoggerHelper.info("VM started successfully: \(vmId)")
                        await self.pollVMStatus(iamToken: iamToken, vmId: vmId)
                    } catch {
                        LoggerHelper.error("Failed to start VM \(vmId): \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Optional: Refresh VM list after all operations complete
//        await MainActor.run {
//            self.fetchVMs() // Assuming you have a refresh function
//        }
    }
    
    
    private func pollVMStatus(iamToken: String, vmId: String) async {
        // 1. Fetch initial state
        var initialIsRunning = false
        do {
            let allVMs = try await YandexAPIService.shared.getVMs(iamToken: iamToken)
            if let vm = allVMs.first(where: { $0.id == vmId }) {
                initialIsRunning = (vm.status == "RUNNING")
            }
            // update global flag
            await MainActor.run {
                AppState.shared.isVirtualMachineRunning = allVMs.contains { $0.status == "RUNNING" }
            }
        } catch {
            // assume stopped if fetch failed
            await MainActor.run {
                AppState.shared.isVirtualMachineRunning = false
            }
        }

        let maxRetries = 20
        let interval: UInt64 = 3_000_000_000  // 3 seconds
        var retry = 0

        while retry < maxRetries {
            try? await Task.sleep(nanoseconds: interval)
            retry += 1

            do {
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: iamToken)
                // update global flag each poll
                await MainActor.run {
                    AppState.shared.isVirtualMachineRunning = allVMs.contains { $0.status == "RUNNING" }
                }

                guard let vm = allVMs.first(where: { $0.id == vmId }) else { continue }

                let status = vm.status
                let timeStamp = Date().formatted(.dateTime.hour().minute().second())
                let name = vm.name

                if !initialIsRunning && status == "RUNNING" {
                    NotificationManager.shared.postNotification(
                        title: "yaControl",
                        body: "VM: \(name) has started. [\(timeStamp)]"
                    )
                    return
                }
                if initialIsRunning && status == "STOPPED" {
                    NotificationManager.shared.postNotification(
                        title: "yaControl",
                        body: "VM: \(name) has stopped. [\(timeStamp)]"
                    )
                    return
                }
                if ["ERROR", "CRASHED"].contains(status) {
                    NotificationManager.shared.postNotification(
                        title: "yaControl",
                        body: "VM: \(name) error: \(status). [\(timeStamp)]"
                    )
                    return
                }
            } catch {
                // ignore and retry
            }
        }

        // Timeout case
        let timeStamp = Date().formatted(.dateTime.hour().minute().second())
        NotificationManager.shared.postNotification(
            title: "yaControl",
            body: "VM: Timeout: couldn’t verify status for ID \(vmId). [\(timeStamp)]"
        )
    }

    
    
    
    func openTerminal() {
        if let url = URL(string: "file:///System/Applications/Utilities/Terminal.app") {
                NSWorkspace.shared.open(url)
            }
    }
    
    func openRDPClient(to ip: String, username: String = "Administrator") {
        let lines = [
            "full address:s:\(ip):3389",
            "username:s:\(username)"
        ]
        let content = lines.joined(separator: "\r\n")
        do {
            // Create a temp file
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("connection.rdp")
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            // Open it in Remote Desktop
            NSWorkspace.shared.open(fileURL)
        } catch {
            LoggerHelper.error("Could not write RDP file: \(error)")
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
                LoggerHelper.info("Internet access is available")
                DispatchQueue.main.async {
                    completion() // Call the completion handler
                }
                monitor.cancel() // Stop monitoring once the connection is available
            } else{
                LoggerHelper.error("The Internet access does not work")
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
