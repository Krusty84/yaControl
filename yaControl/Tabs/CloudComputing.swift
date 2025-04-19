//
//  CloudComputing.swift - Manage Yandex Cloud VM Instances
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI
import UserNotifications

struct CloudComputingTabContent: View {
    @ObservedObject var yandexApi = YandexAPIService.shared
    @ObservedObject var helpers = Helpers.shared
    @StateObject var appState = AppState.shared
    @State private var iamToken: String = ""
    @State private var vmTableData: [VMTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedVM: VMTableData.ID? = nil
    //
    // Billing Data
    @State private var billingData: [BillingTableData] = []
    @State private var currentBalance: String = ""
    @State private var currency: String = ""
    @State private var billingUrl: URL? = nil
    //
    @State private var sortKey: KeyPath<VMTableData, String>? = nil
    @State private var sortOrder: [KeyPathComparator<VMTableData>] = []
    //
    @State private var isPolling = false
    @State private var pollingTask: Task<Void, Never>?
    @State private var currentlyProcessingVMID: String? = nil
    
    @State private var activePollingTasks: [String: Task<Void, Never>] = [:] // VM ID -> Task
    @State private var processingStates: [String: String] = [:] // VM ID -> Status
    //
    var filteredVMs: [VMTableData] {
        if searchText.isEmpty {
            return vmTableData
        } else {
            return vmTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    var sortedVMs: [VMTableData] {
        return filteredVMs.sorted(using: sortOrder)
    }
    var totalVMs: Int {
        return vmTableData.count
    }
    
    var runningVMs: Int {
        return vmTableData.filter { $0.status == "RUNNING" }.count
    }
    @State private var previousRunningVMs: Int = 0
    // 0 - stopping, 1 - running
    @State private var proccessingVMType: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            //            SearchBar(text: $searchText)
            //                .padding(.horizontal)
            
            HStack {
                (Text("Total VMs: ")
                    .font(.subheadline)
                    .fontWeight(.bold) + Text("\(totalVMs)")
                    .font(.subheadline)
                    .fontWeight(.regular))
                .padding(.horizontal)
                
                // Running VMs
                (Text("Running VMs: ")
                    .font(.subheadline)
                    .fontWeight(.bold) + Text("\(runningVMs)")
                    .font(.subheadline)
                    .fontWeight(.regular))
                .padding(.horizontal)
                Spacer()
                Button(action: {
                    if(proccessingVMType == 0 && runningVMs == previousRunningVMs){
                        fetchVMs()
                    } else if(proccessingVMType == 0 && runningVMs < previousRunningVMs){
                        fetchVMs()
                        //helpers.processingVMName.removeAll()
                    } else if (proccessingVMType == 1 && runningVMs == previousRunningVMs){
                        fetchVMs()
                    } else if (proccessingVMType == 1 && runningVMs > previousRunningVMs){
                        fetchVMs()
                        //helpers.processingVMName.removeAll()
                    } else {
                        fetchVMs()
                    }
                    if (vmTableData.filter { $0.status == "RUNNING" }.count == 0){
                        appState.isVirtualMachineRunning = false
                    } else {
                        appState.isVirtualMachineRunning = true
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh VMs")
                //
                Button(action: {
                    helpers.stopAllRunningVMs(iamToken: iamToken, vms: vmTableData)
                    for vm in vmTableData {startPolling(for: vm.id)}
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                        Text("Stop All")
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(5)
                }
                .disabled(runningVMs == 0)
                .help("Stop All Running VMs")
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 10) // Add padding to the right of the button
            }
            .padding(.vertical, 6)
            .padding(.leading, 10)
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if filteredVMs.isEmpty {
                Text("No VMs found")
                    .padding()
            } else {
                Table(filteredVMs, selection: $selectedVM) {
                    // Define columns
                    TableColumn("AS") { vm in
                        Toggle("", isOn: Binding(
                            get: { vm.isAutoStarted },
                            set: { newValue in
                                // Update the checkbox state in your data model
                                if let index = vmTableData.firstIndex(where: { $0.id == vm.id }) {
                                    vmTableData[index].isAutoStarted = newValue
                                    // Save the state in UserDefaults
                                    SettingsManager.shared.markVMtoAutostart(for: vm.id, isAutoStarted: newValue)
                                }
                            }
                        ))
                        .toggleStyle(CheckboxToggleStyle())
                        .help("Auto power management")
                    }
                    .width(min: 20, max:20)
                    
                    TableColumn("Name") { vm in
                        if let url = vm.vmUrl {
                            Link(destination: url) {
                                Text(vm.name)
                                    .foregroundColor(.blue)
                                    .underline()
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .onHover { hovering in
                                        isHovering = hovering
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                    .contextMenu {
                                        Button("Copy") {
                                            let combinedText = "\(vm.name) (\(vm.id))"
                                            let pasteboard = NSPasteboard.general
                                            pasteboard.clearContents()
                                            pasteboard.setString(combinedText, forType: .string)
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle()) // Remove the button styling
                        } else {
                            Text(vm.name)
                        }
                    }.width(min: 150,max:200)
                    
                    TableColumn("Status") { vm in
                        // Determine if this VM is currently being processed
                        //let isProcessing = helpers.processingVMName.contains(vm.name)
                        Button(action: {
                            // Store the VM we're processing
                            currentlyProcessingVMID = vm.id
                            guard processingStates[vm.id] == nil else { return } // Prevent duplicate clicks
                            // Determine action type (start or stop)
                            if vm.status == "RUNNING" {
                                previousRunningVMs = runningVMs
                                proccessingVMType = 0
                            } else {
                                previousRunningVMs = runningVMs
                                proccessingVMType = 1
                            }
                            
                            // Start the initial action
                            helpers.startStopVM(iamToken: iamToken, for: vm)
                            
                            // Start polling for status updates
                            startPolling(for: vm.id)
                        }) {
                            Image(systemName: processingStates[vm.id] == vm.id ? "arrow.triangle.2.circlepath" : {
                                switch vm.status {
                                    case "RUNNING": "stop.fill"
                                    case "STOPPED": "play.fill"
                                    case "STARTING", "STOPPING", "PROVISIONING", "RESTARTING","UPDATING": "arrow.triangle.2.circlepath"
                                    case "ERROR": "exclamationmark.triangle.fill"
                                    case "CRASHED": "exclamationmark.octagon.fill"
                                    default: "questionmark"
                                }
                            }())
                            .foregroundColor({
                                switch vm.status {
                                    case "RUNNING": .red
                                    case "STOPPED": .green
                                    case "ERROR", "CRASHED": .orange
                                    default: .gray
                                }
                            }())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(processingStates[vm.id] != nil) // Disable while processing
                    }
                    .width(min:40,max:40)
                    
                    TableColumn("Created At", value: \.createdAt).width(min: 120,max:120)
                    TableColumn("Cores", value: \.cores).width(min:40,max:40)
                    TableColumn("RAM", value: \.memoryGB).width(min:30,max:30)
                    TableColumn("Public Ip") { vm in
                        Text(vm.addresses.joined(separator: ", "))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .contextMenu {
                                Button("Copy") {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(vm.addresses.joined(separator: ", "), forType: .string)
                                }
                            }
                    }.width(min: 120,max:120)
                    
                    TableColumn("Folder") { vm in
                        if let url = vm.folderUrl {
                            Link(destination: url) {
                                Text(vm.folderName)
                                    .foregroundColor(.blue)
                                    .underline()
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineLimit(nil)
                                    .onHover { hovering in
                                        isHovering = hovering
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle()) // Remove the button styling
                        } else {
                            Text(vm.name)
                        }
                    }.width(min: 120, max:120)
                }
                .padding(.vertical, 6)
//                .onChange(of: selectedVM) { oldSelection, newSelection in
//                    if let selectedVMId = newSelection, let selectedVM = filteredVMs.first(where: { $0.id == selectedVMId }) {
//                        print("Selected VM ID: \(selectedVM.id)")
//                    }
//                }
            }
            
            StatusPanel(
                lastUpdateTime: yandexApi.lastUpdateTime,
                currentBalance: currentBalance,
                currency: currency,
                billingUrl:billingUrl
            )
        }
        .onAppear {
            fetchVMs()
        }
    }
    
    private func sortTableDataByStatus() {
        let statusPriority = ["RUNNING", "STARTING", "STOPPED", "STOPPING"]
        
        vmTableData.sort { a, b in
            let aPriority = statusPriority.firstIndex(of: a.status) ?? Int.max
            let bPriority = statusPriority.firstIndex(of: b.status) ?? Int.max
            
            // If same status, sort by name (optional)
            if aPriority == bPriority {
                return a.name < b.name
            }
            return aPriority < bPriority
        }
    }
        
    private func fetchVMs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Step 1: Get IAM Token
                let authResponse = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                
                // Store the IAM token
                await MainActor.run {
                    iamToken = authResponse.iamToken
                }
                
                // Step 2: Get VMs using the IAM Token
                let allVMs = try await YandexAPIService.shared.getVMs(iamToken: authResponse.iamToken)
                let billings = try await YandexAPIService.shared.getCosts(iamToken: iamToken)
                // Update UI on main thread
                await MainActor.run {
                    vmTableData = allVMs
                    self.sortTableDataByStatus()
                    //
                    self.billingData = billings
                    if let firstBilling = billings.first {
                        self.currentBalance = firstBilling.balance
                        self.currency = firstBilling.currency
                        self.billingUrl = firstBilling.billingUrl
                    }
                    isLoading = false
                }
                
            } catch {
                // Handle errors on main thread
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    print("Error fetching VMs: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startPolling(for vmID: String) {
        // Cancel any existing task for this VM
        activePollingTasks[vmID]?.cancel()
        
        // Create new task
        let task = Task {
            // Set initial processing state
            await setProcessingState(for: vmID, status: nil)
            
            var retryCount = 0
            let maxRetries = 20
            let pollingInterval: UInt64 = 3_000_000_000
            
            while retryCount < maxRetries && !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: pollingInterval)
                    
                    let updatedVMs = try await YandexAPIService.shared.getVMs(iamToken: iamToken)
                    
                    guard let updatedVM = updatedVMs.first(where: { $0.id == vmID }) else {
                        retryCount += 1
                        continue
                    }
                    
                    // Update UI immediately
                    await updateVMInTable(updatedVM)
                    
                    // Check completion
                    if await isOperationComplete(for: vmID, currentStatus: updatedVM.status) {
                        await cleanupPolling(for: vmID)
                        notifyCompletion(for: updatedVM)
                        return
                    }
                    
                    retryCount += 1
                    
                } catch {
                    retryCount += 1
                    if Task.isCancelled { return }
                }
            }
            
            // Timeout handling
            await cleanupPolling(for: vmID)
            notifyTimeout(for: vmID)
        }
        
        // Store the task
        activePollingTasks[vmID] = task
    }
    
    // 3. Helper functions
    @MainActor
    private func setProcessingState(for vmID: String, status: String?) {
        if let status = status {
            processingStates[vmID] = status
        } else {
            processingStates.removeValue(forKey: vmID)
        }
    }
    
    @MainActor
    private func updateVMInTable(_ vm: VMTableData) {
        if let index = vmTableData.firstIndex(where: { $0.id == vm.id }) {
            vmTableData[index] = vm
        }
        
        let runningCount = vmTableData.filter { $0.status == "RUNNING" }.count
        appState.isVirtualMachineRunning = runningCount > 0
        print("Updated running state: \(appState.isVirtualMachineRunning ? "RUNNING" : "STOPPED")")
        
    }
    
    private func isOperationComplete(for vmID: String, currentStatus: String) async -> Bool {
        // Get the original VM state safely
        let originalVM = await MainActor.run {
            vmTableData.first { $0.id == vmID }
        }
        
        guard let originalVM = originalVM else {
            return true
        }
        
        let isStartAction = originalVM.status == "STOPPED"
        
        // Success cases
        if (isStartAction && currentStatus == "RUNNING") ||
            (!isStartAction && currentStatus == "STOPPED") {
            return true
        }
        
        // Error cases
        return ["ERROR", "CRASHED"].contains(currentStatus)
    }
    
    @MainActor
    private func cleanupPolling(for vmID: String) {
        activePollingTasks.removeValue(forKey: vmID)
        processingStates.removeValue(forKey: vmID)
    }
    
    //    private func notifyUser(title: String, body: String, isError: Bool = false) {
    //        let notification = NSUserNotification()
    //        notification.title = title
    //        notification.informativeText = body
    //        notification.soundName = isError ? NSUserNotificationDefaultSoundName : nil
    //
    //        NSUserNotificationCenter.default.deliver(notification)
    //    }
    
    private func notifyCompletion(for vm: VMTableData) {
        let isStartAction = vm.status == "RUNNING"
        let title = isStartAction ? "VM Started" : "VM Stopped"
        let body = "\(vm.name) is now \(vm.status)"
        sendNotification(title: title, body: body)
    }
    
    private func notifyTimeout(for vmID: String) {
        if let vm = vmTableData.first(where: { $0.id == vmID }) {
            sendNotification(title: "Operation Timed Out",
                             body: "Couldn't verify final status for \(vm.name)",
                             isError: true)
        }
    }
    
    private func sendNotification(title: String, body: String, isError: Bool = false) {
        let center = UNUserNotificationCenter.current()
        
        // Check current notification settings first
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Notifications not authorized")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            if isError {
                content.sound = .default
            }
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil // Deliver immediately
            )
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to show notification: \(error.localizedDescription)")
                } else {
                    print("Notification shown successfully")
                }
            }
        }
    }
}
