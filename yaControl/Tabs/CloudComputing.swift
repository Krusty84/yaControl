//
//  CloudComputing.swift - Manage Yandex Cloud VM Instances
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct CloudComputingTabContent: View {
    @ObservedObject var apiService = YandexAPIService.shared
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
    @State private var sortKey: KeyPath<VMTableData, String>? = nil
    @State private var sortOrder: [KeyPathComparator<VMTableData>] = []
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
                        helpers.processingVMName.removeAll()
                    } else if (proccessingVMType == 1 && runningVMs == previousRunningVMs){
                        fetchVMs()
                    } else if (proccessingVMType == 1 && runningVMs > previousRunningVMs){
                        fetchVMs()
                        helpers.processingVMName.removeAll()
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
                    TableColumn("Select") { vm in
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
                        //.toggleStyle(CheckboxToggleStyle())
                    }
                    .width(min: 50, max: 50)
        
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
                        let isProcessing = helpers.processingVMName.contains(vm.name)
                        
                        Button(action: {
                            if (vm.status == "RUNNING") {
                                previousRunningVMs = runningVMs
                                proccessingVMType = 0
                            } else {
                                previousRunningVMs = runningVMs
                                proccessingVMType = 1
                            }
                            helpers.startStopVM(iamToken: iamToken, for: vm)
                        }) {
                            if isProcessing {
                                // Show loading indicator when processing
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.gray)
                                    .rotationEffect(.degrees(isProcessing ? 360 : 0))
                                    .animation(
                                        Animation.linear(duration: 1.0)
                                            .repeatForever(autoreverses: false),
                                        value: isProcessing
                                    )
                            } else {
                                // Show normal play/stop icon when not processing
                                Image(systemName: vm.status == "RUNNING" ? "stop.fill" : "play.fill")
                                    .foregroundColor(vm.status == "RUNNING" ? .red : .green)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isProcessing) // Disable button while processing
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
                    }.width(min: 150,max:150)
                }
                .padding(.vertical, 6)
                .onChange(of: selectedVM) { oldSelection, newSelection in
                    if let selectedVMId = newSelection, let selectedVM = filteredVMs.first(where: { $0.id == selectedVMId }) {
                        print("Selected VM ID: \(selectedVM.id)")
                    }
                }
            }
            HStack {
                Text("Last updated: \(apiService.lastUpdateTime)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(helpers.processingVMName)
                        .font(.subheadline)
                        .foregroundColor(.red)
                
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
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
        
        // Step 1: Get IAM Token
        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let response):
                        // Step 2: Get VMs using the IAM Token
                        iamToken=response.iamToken
                        YandexAPIService.shared.getVMs(iamToken: response.iamToken) { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                switch result {
                                    case .success(let allVMs):
                                        print("result: ", allVMs)
                                        vmTableData = allVMs
                                        self.sortTableDataByStatus()
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                }
                            }
                        }
                    case .failure(let error):
                        isLoading = false
                        print(error.localizedDescription)
                        errorMessage = error.localizedDescription
                }
            }
        }
    }
    
}
