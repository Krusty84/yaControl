//
//  CloudComputing.swift - Yandex Cloud Serverless Functions
//  yaControl
//
//  Created by Sedoykin Alexey on 17/02/2025.
//

import SwiftUI

struct ServerLessFunctionTabContent: View {
    @ObservedObject var yandexApi = YandexAPIService.shared
    @ObservedObject var helpers = Helpers.shared
    @State private var iamToken: String = ""
    @State private var slfTableData: [ServerLessFunctionTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedSlf: ServerLessFunctionTableData.ID? = nil
    //
    // Billing Data
    @State private var billingData: [BillingTableData] = []
    @State private var currentBalance: String = ""
    @State private var currency: String = ""
    @State private var billingUrl: URL? = nil
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
                
                // Active SLFs
                (Text("Active SLFs: ")
                    .font(.subheadline)
                    .fontWeight(.bold) + Text("\(activeSLFs)")
                    .font(.subheadline)
                    .fontWeight(.regular))
                .padding(.horizontal)
                
                Spacer()
                
                // Refresh Button
                Button(action: {
                    fetchServerLessFunctions()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh SLFs")
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
            } else if filteredSLFs.isEmpty {
                Text("No SLFs found")
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
                    TableColumn("Invoke") { (slf: ServerLessFunctionTableData) in
                        Text(slf.id)
                            .contextMenu {
                                   Button("Copy invoke url") {
                                       let pasteboard = NSPasteboard.general
                                       pasteboard.clearContents()
                                       pasteboard.setString(slf.httpInvokeUrl, forType: .string)
                                   }
                                Button(action: {
                                    //guard let ipAddress = vm.addresses.first else { return }

                                    // 1. Build the SSH command
                                    let ycCommand = "yc serverless function invoke \(slf.id)"

                                    // 2. Copy to clipboard
                                    let pb = NSPasteboard.general
                                    pb.clearContents()
                                    pb.setString(ycCommand, forType: .string)

                                    helpers.openTerminal()
                                }) {
                                    Text("Call via CLI Yandex Cloud")
                                }
                                .disabled(!SettingsManager.shared.ycCLIInstalled)
                               }
                    }.width(min: 200,max:200)
                    
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
            }
            StatusPanel(
                lastUpdateTime: yandexApi.lastUpdateTime,
                currentBalance: currentBalance,
                currency: currency,
                billingUrl:billingUrl
            )
        }
        .onAppear {
            fetchServerLessFunctions()
        }
    }
    
    private func fetchServerLessFunctions() {
        isLoading = true
        errorMessage = nil
        // Step 1: Get IAM Token
        
        Task {
            do {
                // 1. Authenticate and get IAM token
                let authResponse = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                
                // 2. Store IAM token
                await MainActor.run {
                    self.iamToken = authResponse.iamToken
                }
                
                // 3. Fetch serverless functions
                let allSLFs = try await YandexAPIService.shared.getServerLessFunctions(
                    iamToken: authResponse.iamToken
                )
                let billings = try await YandexAPIService.shared.getCosts(iamToken: iamToken)
                // 4. Update UI state
                await MainActor.run {
                    self.slfTableData = allSLFs
                    self.billingData = billings
                    if let firstBilling = billings.first {
                        self.currentBalance = firstBilling.balance
                        self.currency = firstBilling.currency
                        self.billingUrl = firstBilling.billingUrl
                    }
                    self.isLoading = false
                }
                
            } catch {
                // 5. Handle errors
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    LoggerHelper.error("Error fetching Serverless Functions: \(error.localizedDescription)")
                }
            }
        }
    }
}
