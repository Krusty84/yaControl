//
//  CloudComputing.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct ServerLessFunctionTabContent: View {
    @ObservedObject var apiService = YandexAPIService.shared
    @ObservedObject var helpers = Helpers.shared
    @State private var iamToken: String = ""
    @State private var serverLessFunctionTableData: [ServerLessFunctionTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedSLF: ServerLessFunctionTableData.ID? = nil
    //
    @State private var sortKey: KeyPath<ServerLessFunctionTableData, String>? = nil
    @State private var sortOrder: [KeyPathComparator<ServerLessFunctionTableData>] = []
    //
    var filteredSLFs: [ServerLessFunctionTableData] {
        if searchText.isEmpty {
            return serverLessFunctionTableData
        } else {
            return serverLessFunctionTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    var sortedVMs: [ServerLessFunctionTableData] {
        return filteredSLFs.sorted(using: sortOrder)
    }
    var totalSLFs: Int {
        return serverLessFunctionTableData.count
    }
    
    var runningVMs: Int {
        return serverLessFunctionTableData.filter { $0.status == "RUNNING" }.count
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
                    .fontWeight(.bold) + Text("\(totalSLFs)")
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
                    fetchServerLessFunctions()
                 }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh VMs")
                //
                Button(action: {
                   // helpers.stopAllRunningVMs(iamToken: iamToken, vms: serverLessFunctionTableData)
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
            }
            .padding(.vertical, 6)
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if filteredSLFs.isEmpty {
                Text("No VMs found")
                    .padding()
            } else {
                Table(filteredSLFs, selection: $selectedSLF) {
                    // Define columns
                    TableColumn("Name") { slf in
                        if let url = slf.slfUrl {
                            Link(destination: url) {
                                Text(slf.name)
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
                                               let combinedText = "\(slf.name) (\(slf.id))"
                                               let pasteboard = NSPasteboard.general
                                               pasteboard.clearContents()
                                               pasteboard.setString(combinedText, forType: .string)
                                           }
                                       }
                            }
                            .buttonStyle(PlainButtonStyle()) // Remove the button styling
                        } else {
                            Text(slf.name)
                        }
                    }.width(min: 150,max:200)
                    TableColumn("Status", value: \.status).width(min: 120,max:120)
                    TableColumn("Created At", value: \.createdAt).width(min: 120,max:120)
//                    TableColumn("Cores", value: \.cores).width(min:40,max:40)
//                    TableColumn("RAM", value: \.memoryGB).width(min:30,max:30)
//                    TableColumn("Public Ip") { vm in
//                        Text(vm.addresses.joined(separator: ", "))
//                            .fixedSize(horizontal: false, vertical: true)
//                            .lineLimit(nil)
//                            .contextMenu {
//                                   Button("Copy") {
//                                       let pasteboard = NSPasteboard.general
//                                       pasteboard.clearContents()
//                                       pasteboard.setString(slf.addresses.joined(separator: ", "), forType: .string)
//                                   }
//                               }
//                    }.width(min: 120,max:120)
                    TableColumn("Folder") { slf in
                        if let url = slf.folderUrl {
                            Link(destination: url) {
                                Text(slf.folderName)
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
                            Text(slf.name)
                        }
                    }.width(min: 150,max:150)
                }
                .padding(.vertical, 6)
                .onChange(of: selectedSLF) { oldSelection, newSelection in
                    if let selectedSLFId = newSelection, let selectedSLF = filteredSLFs.first(where: { $0.id == selectedSLFId }) {
                        print("Selected VM ID: \(selectedSLF.id)")
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
            fetchServerLessFunctions()
        }
    }
    
    private func fetchServerLessFunctions() {
        isLoading = true
        errorMessage = nil
        // Step 1: Get IAM Token
        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let response):
                        // Step 2: Get VMs using the IAM Token
                        iamToken=response.iamToken
                        YandexAPIService.shared.getServerLessFunctions(iamToken: response.iamToken) { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                switch result {
                                    case .success(let allSLFs):
                                        print("result: ", allSLFs)
                                        selected = allSLFs
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
