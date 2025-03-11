//
//  CloudStorage.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 09/03/2025.
//

import SwiftUI

struct BucketTabContent: View {
    @ObservedObject var apiService = YandexAPIService.shared
    @ObservedObject var helpers = Helpers.shared
    @State private var iamToken: String = ""
    @State private var bucketTableData: [BucketTableData] = []
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var searchText: String = ""
    @State private var isHovering = false
    @State private var selectedBucket: BucketTableData.ID? = nil
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
    
//    var activeBuckets: Int {
//        return bucketTableData.filter { $0.status == "ACTIVE" }.count
//    }
    
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
                    TableColumn("Files", value: \.totalObjectCountString).width(min: 90, max: 90)
                    TableColumn("Created At", value: \.createdAt).width(min: 120,max:120)
                    TableColumn("Updated At", value: \.updatedAt).width(min: 120,max:120)

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
                    }.width(min: 150,max:150)
                }
                .padding(.vertical, 6)
                .onChange(of: selectedBucket) { oldSelection, newSelection in
                    if let selectedBucketId = newSelection, let selectedBucket = filteredBuckets.first(where: { $0.id == selectedBucketId }) {
                        print("Selected Bucket ID: \(selectedBucket.id)")
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
            fetchBuckets()
        }
    }
    
    private func fetchBuckets() {
        isLoading = true
        errorMessage = nil
        // Step 1: Get IAM Token
        YandexAPIService.shared.checkOauthKey(yandexPassportOauthToken: SettingsManager.shared.oAuthKey) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let response):
                        // Step 2: Get VMs using the IAM Token
                        iamToken=response.iamToken
                        YandexAPIService.shared.getBuckets(iamToken: response.iamToken) { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                switch result {
                                    case .success(let allBuckets):
                                        print("result: ", allBuckets)
                                        bucketTableData = allBuckets
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
