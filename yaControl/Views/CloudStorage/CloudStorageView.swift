//
//  CloudStorage.swift - Yandex Cloud Storage
//  yaControl
//
//  Created by Sedoykin Alexey on 09/03/2025.
//

import SwiftUI

struct BucketTabContent: View {
    @StateObject private var vm = CloudStorageViewModel()
    @State private var selectedBucket: BucketTableData.ID? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header: count + refresh
            HStack {
                Text("Total Buckets: \(vm.totalBuckets)")
                    .font(.subheadline).bold()
                Spacer()
                Button {
                    Task { await vm.fetchBuckets() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh Buckets")
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .searchable(text: $vm.searchText, prompt: "Search buckets")

            // Content
            if vm.isLoading {
                ProgressView("Loading…").padding()
            } else if let err = vm.errorMessage {
                ErrorView(error: err)
            } else if vm.filteredBuckets.isEmpty {
                Text("No buckets found").padding()
            } else {
                Table(vm.filteredBuckets, selection: $selectedBucket) {
                    TableColumn("Name") { BucketNameColumn(bucket: $0) }
                    TableColumn("Max Size (Gb)", value: \.maxSize)
                        .width(min: 80, max: 80)
                    TableColumn("Used Size (Gb)", value: \.usedSize)
                        .width(min: 90, max: 90)
                    TableColumn("Files", value: \.totalObjectCountString)
                        .width(min: 40, ideal: 40, max: 120)
                    TableColumn("Created At", value: \.createdAt)
                        .width(min: 110, max: 120)
                    TableColumn("Updated At", value: \.updatedAt)
                        .width(min: 110, max: 120)
                    TableColumn("Folder") { BucketFolderColumn(bucket: $0) }
                        .width(min: 80, max: 150)
                }
                .padding(.vertical, 6)
                .refreshable {
                    await vm.fetchBuckets()
                }
            }

            // Status / billing panel
            StatusPanel(
                lastUpdateTime: vm.lastUpdateTime,
                currentBalance: vm.currentBalance,
                currency: vm.currency,
                billingUrl: vm.billingUrl
            )
        }
        .onAppear {
            Task { await vm.fetchBuckets() }
        }
    }
}
