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
    @State private var slfTableData: [ServerLessFunctionTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedSlf: ServerLessFunctionTableData.ID? = nil
    //
    @State private var sortKey: KeyPath<ServerLessFunctionTableData, String>? = nil
    @State private var sortOrder: [KeyPathComparator<ServerLessFunctionTableData>] = []
    //
    var filteredSLFs: [ServerLessFunctionTableData] {
        if searchText.isEmpty {
            return slfTableData
        } else {
            return slfTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    var sortedSLFs: [ServerLessFunctionTableData] {
        return filteredSLFs.sorted(using: sortOrder)
    }
    var totalSLFs: Int {
        return slfTableData.count
    }
    
    var activeSLFs: Int {
        return slfTableData.filter { $0.status == "ACTIVE" }.count
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
                (Text("Total SLFs: ")
                    .font(.subheadline)
                    .fontWeight(.bold) + Text("\(totalSLFs)")
                    .font(.subheadline)
                    .fontWeight(.regular))
                .padding(.horizontal)
                
                // Running VMs
                (Text("Active SLFs: ")
                    .font(.subheadline)
                    .fontWeight(.bold) + Text("\(activeSLFs)")
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
                .help("Refresh SLFs")
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
                Table(filteredSLFs, selection: $selectedSlf) {
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
                    TableColumn("Status") { slf in
                        Image(systemName: slf.status == "ACTIVE" ? "arrow.up.square.fill" : "arrow.down.square.fill")
                                .foregroundColor(slf.status == "ACTIVE" ? .green : .red)
                    }.width(min:40,max:40)
                    TableColumn("Created At", value: \.createdAt).width(min: 120,max:120)
                   // TableColumn("Invoke Url", value: \.httpInvokeUrl).width(min: 120,max:120)
                    TableColumn("Invoke Url") { item in
                                    if let url = item.httpInvokeUrl {
                                        Text(url.absoluteString) // Convert URL to String
                                    } else {
                                        Text("No URL") // Handle nil case
                                    }
                                }
                                .width(min: 120,max:120)
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
                .onChange(of: selectedSlf) { oldSelection, newSelection in
                    if let selectedSLFId = newSelection, let selectedSLF = filteredSLFs.first(where: { $0.id == selectedSLFId }) {
                        print("Selected SLF ID: \(selectedSLF.id)")
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
                                        slfTableData = allSLFs
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
