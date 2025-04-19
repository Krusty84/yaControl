//
//  CloudStorage.swift - Yandex Cloud Storage
//  yaControl
//
//  Created by Sedoykin Alexey on 09/03/2025.
//

import SwiftUI

struct BucketTabContent: View {
    @ObservedObject var yandexApi = YandexAPIService.shared
    @ObservedObject var helpers = Helpers.shared
    @State private var iamToken: String = ""
    @State private var bucketTableData: [BucketTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedBucket: BucketTableData.ID? = nil
    //
    // Billing Data
    @State private var billingData: [BillingTableData] = []
    @State private var currentBalance: String = ""
    @State private var currency: String = ""
    @State private var billingUrl: URL? = nil
    //
    @State private var sortKey: KeyPath<BucketTableData, String>? = nil
    @State private var sortOrder: [KeyPathComparator<BucketTableData>] = []
    //
    var filteredBuckets: [BucketTableData] {
        if searchText.isEmpty {
            return bucketTableData
        } else {
            return bucketTableData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    var sortedBuckets: [BucketTableData] {
        return filteredBuckets.sorted(using: sortOrder)
    }
    var totalBuckets: Int {
        return bucketTableData.count
    }
        
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            //            SearchBar(text: $searchText)
            //                .padding(.horizontal)
            HStack {
                (Text("Total Buckets: ")
                    .font(.subheadline)
                    .fontWeight(.bold) + Text("\(totalBuckets)")
                    .font(.subheadline)
                    .fontWeight(.regular))
                .padding(.horizontal)
                
                Spacer()
                
                // Refresh Button
                Button(action: {
                    fetchBuckets()
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
            } else if filteredBuckets.isEmpty {
                Text("No Buckets found")
                    .padding()
            } else {
                Table(filteredBuckets, selection: $selectedBucket) {
                    // Define columns
                    TableColumn("Name") { item in
                        if let url = item.bucketUrl {
                            Link(destination: url) {
                                Text(item.name)
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
                                            let combinedText = "\(item.name) (\(item.id))"
                                            let pasteboard = NSPasteboard.general
                                            pasteboard.clearContents()
                                            pasteboard.setString(combinedText, forType: .string)
                                        }
                                    }
                            }
                            .buttonStyle(PlainButtonStyle()) // Remove the button styling
                        } else {
                            Text(item.name)
                        }
                    }.width(min: 150,max:200)
                    TableColumn("Max Size (Gb)", value: \.maxSize).width(min: 80,max:80)
                    TableColumn("Used Size (Gb)", value: \.usedSize).width(min: 90,max:90)
                    TableColumn("Files", value: \.totalObjectCountString).width(min: 40, ideal: 40, max: 120)
                    TableColumn("Created At", value: \.createdAt).width(min: 110, ideal: 110,max:120)
                    TableColumn("Updated At", value: \.updatedAt).width(min: 110, ideal: 110,max:120)
                    
                    TableColumn("Folder") { item in
                        if let url = item.folderUrl {
                            Link(destination: url) {
                                Text(item.folderName)
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
                            Text(item.name)
                        }
                    }.width(min: 80, ideal: 80,max:150)
                }
                .padding(.vertical, 6)
//                .onChange(of: selectedBucket) { oldSelection, newSelection in
//                    if let selectedBucketId = newSelection, let selectedBucket = filteredBuckets.first(where: { $0.id == selectedBucketId }) {
//                        print("Selected Bucket ID: \(selectedBucket.id)")
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
            fetchBuckets()
        }
    }
    
    private func fetchBuckets() {
        isLoading = true
        errorMessage = nil
        // Step 1: Get IAM Token
                
        Task {
            do {
                // 1. Authenticate and get IAM token
                let authResponse = try await YandexAPIService.shared.checkOauthKey(
                    yandexPassportOauthToken: SettingsManager.shared.oAuthKey
                )
                
                // 2. Store IAM token and fetch buckets
                await MainActor.run {
                    self.iamToken = authResponse.iamToken
                }
                
                let allBuckets = try await YandexAPIService.shared.getBuckets(
                    iamToken: authResponse.iamToken
                )
                let billings = try await YandexAPIService.shared.getCosts(iamToken: iamToken)
                // 3. Update UI with results
                await MainActor.run {
                    self.bucketTableData = allBuckets
                    self.billingData = billings
                    if let firstBilling = billings.first {
                        self.currentBalance = firstBilling.balance
                        self.currency = firstBilling.currency
                        self.billingUrl = firstBilling.billingUrl
                    }
                    self.isLoading = false
                }
                
            } catch {
                // 4. Handle errors
                await MainActor.run {
                    self.isLoading = false
                    print(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
