//
//  Helpers.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import SwiftUI
import Foundation
import Network

class Helpers:ObservableObject {
    static let shared = Helpers() // Singleton for reusability
    @Published var processingVMName: String = ""
    @Published var isConnectedToWAN: Bool = false
    private var onConnectedToWAN: (() -> Void)?
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "InternetConnectionMonitor")
    
    init(onConnectedToWAN: (() -> Void)? = nil) {
        self.onConnectedToWAN = onConnectedToWAN
        checkInternetConnection()
    }
    
    deinit {
        monitor?.cancel()
    }
    
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
    
    func startStopVM(iamToken:String,for vm: VMTableData) {
        if vm.status == "RUNNING" {
            print("Stopping VM: \(vm.name)")
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
            print("Starting VM: \(vm.name)")
            self.processingVMName="Starting VM: \(vm.name)"
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
        self.processingVMName="Sopping all VM's"
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
    
    private func checkInternetConnection() {
        monitor = NWPathMonitor()
            monitor?.pathUpdateHandler = { [weak self] path in
                DispatchQueue.main.async {
                    let isConnected = path.status == .satisfied
                    self?.isConnectedToWAN = isConnected
                    if isConnected {
                        LoggerHelper.info("!@ Internet connection detected, Yeah!")
                        self?.onConnectedToWAN?() // Call the callback
                    }
                }
            }
            monitor?.start(queue: queue)
    }
    
    static func tintedIcon(named iconName: String, color: NSColor) -> NSImage {
        guard let icon = NSImage(named: iconName) else { return NSImage() } // Use your icon name here
        
        // Resize the icon to 18x18 points
        let newSize = NSSize(width: 18, height: 18)
        let resizedIcon = NSImage(size: newSize)
        
        resizedIcon.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: newSize))
        resizedIcon.unlockFocus()
        
        // Apply the tint color
        let tintedIcon = resizedIcon.copy() as! NSImage
        tintedIcon.lockFocus()
        
        color.set()
        let imageRect = NSRect(origin: .zero, size: newSize)
        imageRect.fill(using: .sourceAtop)
        
        tintedIcon.unlockFocus()
        return tintedIcon
    }
}

struct MenuBarIcon: View {
    var isConnectedToInternet: Bool
    var body: some View {
        let iconColor: NSColor = isConnectedToInternet ? .systemGreen : .systemGray // Change color based on connection status
        return Image(nsImage: Helpers.tintedIcon(named: "AppIcon", color: iconColor))
    }
}
